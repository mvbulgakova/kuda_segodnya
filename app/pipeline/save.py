from dataclasses import dataclass

import structlog
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Event, EventSource, EventStatus, Source, Venue
from app.parsers.base import Parser, RawEvent
from app.pipeline.normalize import dedup_hash

log = structlog.get_logger(__name__)


@dataclass(slots=True)
class SaveStats:
    parsed: int = 0
    created: int = 0
    linked: int = 0  # existing event, new source link
    skipped: int = 0


async def ensure_source(session: AsyncSession, parser: Parser) -> Source:
    stmt = select(Source).where(Source.slug == parser.slug)
    src = (await session.execute(stmt)).scalar_one_or_none()
    if src is None:
        src = Source(
            slug=parser.slug,
            kind=parser.kind,
            title=parser.title,
            url=parser.source_url,
        )
        session.add(src)
        await session.flush()
    return src


async def _find_or_create_venue(
    session: AsyncSession, name: str | None, address: str | None
) -> Venue | None:
    if not name:
        return None
    stmt = select(Venue).where(Venue.name == name).limit(1)
    venue = (await session.execute(stmt)).scalar_one_or_none()
    if venue is None:
        venue = Venue(name=name[:256], address=(address or None))
        session.add(venue)
        await session.flush()
    return venue


async def save_events(
    session: AsyncSession, parser: Parser, raws: list[RawEvent]
) -> SaveStats:
    stats = SaveStats(parsed=len(raws))
    source = await ensure_source(session, parser)

    for raw in raws:
        h = dedup_hash(raw.title, raw.starts_at, raw.venue_name)

        existing = (
            await session.execute(select(Event).where(Event.dedup_hash == h))
        ).scalar_one_or_none()

        if existing is None:
            venue = await _find_or_create_venue(session, raw.venue_name, raw.venue_address)
            event = Event(
                dedup_hash=h,
                title=raw.title,
                description=raw.description,
                starts_at=raw.starts_at,
                ends_at=raw.ends_at,
                venue_id=venue.id if venue else None,
                price_kind=raw.price_kind,
                age_limit=raw.age_limit,
                cover_url=raw.cover_url,
                canonical_url=raw.external_url,
                status=EventStatus.published,
            )
            session.add(event)
            await session.flush()
            event_id = event.id
            stats.created += 1
        else:
            event_id = existing.id

        # Upsert event_source link (ignore conflict on uq_source_external)
        stmt = (
            pg_insert(EventSource)
            .values(
                event_id=event_id,
                source_id=source.id,
                external_id=raw.external_id,
                external_url=raw.external_url,
            )
            .on_conflict_do_nothing(constraint="uq_source_external")
        )
        result = await session.execute(stmt)
        if existing is not None and result.rowcount:
            stats.linked += 1
        elif existing is not None:
            stats.skipped += 1

    log.info(
        "pipeline.saved",
        source=parser.slug,
        parsed=stats.parsed,
        created=stats.created,
        linked=stats.linked,
        skipped=stats.skipped,
    )
    return stats
