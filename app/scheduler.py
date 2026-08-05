import asyncio

import structlog
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger

from app.config import settings
from app.db import session_scope
from app.parsers import ALL_PARSERS
from app.parsers.base import Parser
from app.pipeline.save import save_events

log = structlog.get_logger(__name__)


async def run_parser(parser: Parser) -> None:
    try:
        raws = await parser.parse()
    except Exception as exc:
        log.error("parser.failed", parser=parser.slug, error=str(exc))
        return

    try:
        async with session_scope() as session:
            await save_events(session, parser, raws)
    except Exception as exc:
        log.error("parser.save_failed", parser=parser.slug, error=str(exc))


async def run_all_parsers() -> None:
    log.info("scheduler.tick", parsers=[p.slug for p in ALL_PARSERS])
    await asyncio.gather(*(run_parser(p) for p in ALL_PARSERS))


def build_scheduler() -> AsyncIOScheduler:
    scheduler = AsyncIOScheduler(timezone=settings.tz)
    scheduler.add_job(
        run_all_parsers,
        trigger=IntervalTrigger(minutes=settings.parse_interval_minutes),
        id="parse_all",
        max_instances=1,
        coalesce=True,
        next_run_time=None,
    )
    return scheduler
