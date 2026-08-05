from datetime import UTC, datetime, timedelta

import httpx
import structlog

from app.config import settings
from app.models import PriceKind, SourceKind
from app.parsers.base import RawEvent

log = structlog.get_logger(__name__)

API_URL = "https://kudago.com/public-api/v1.4/events/"
PAGE_SIZE = 100
LOOKAHEAD_DAYS = 7


class KudaGoParser:
    slug = "kudago"
    kind = SourceKind.api
    title = "KudaGo"
    source_url = "https://kudago.com/"

    async def parse(self) -> list[RawEvent]:
        actual_since = int(datetime.now(tz=UTC).timestamp())
        actual_until = int(
            (datetime.now(tz=UTC) + timedelta(days=LOOKAHEAD_DAYS)).timestamp()
        )
        params = {
            "location": settings.kudago_location,
            "is_free": "true",
            "actual_since": actual_since,
            "actual_until": actual_until,
            "fields": ",".join(
                [
                    "id",
                    "title",
                    "short_title",
                    "dates",
                    "place",
                    "price",
                    "is_free",
                    "images",
                    "site_url",
                    "description",
                    "body_text",
                    "age_restriction",
                ]
            ),
            "expand": "place,dates",
            "page_size": PAGE_SIZE,
            "order_by": "-publication_date",
        }

        events: list[RawEvent] = []
        url: str | None = API_URL
        page = 0
        async with httpx.AsyncClient(timeout=20.0) as client:
            while url and page < 5:  # cap at 500 events
                resp = await client.get(url, params=params if page == 0 else None)
                resp.raise_for_status()
                payload = resp.json()
                for item in payload.get("results", []):
                    ev = _to_raw(item, actual_since, actual_until)
                    if ev is not None:
                        events.append(ev)
                url = payload.get("next")
                page += 1

        log.info("kudago.parsed", count=len(events))
        return events


def _to_raw(item: dict, since_ts: int, until_ts: int) -> RawEvent | None:
    dates = item.get("dates") or []
    starts_at = _pick_upcoming_start(dates, since_ts, until_ts)
    if starts_at is None:
        return None

    title = (item.get("title") or item.get("short_title") or "").strip()
    if not title:
        return None

    place = item.get("place") or {}
    venue_name = (place.get("title") if isinstance(place, dict) else None) or None
    venue_address = (place.get("address") if isinstance(place, dict) else None) or None

    images = item.get("images") or []
    cover = images[0].get("image") if images and isinstance(images[0], dict) else None

    age = _parse_age(item.get("age_restriction"))

    return RawEvent(
        external_id=str(item["id"]),
        title=title[:512],
        description=(item.get("description") or item.get("body_text") or "").strip() or None,
        starts_at=starts_at,
        price_kind=PriceKind.free if item.get("is_free") else PriceKind.free_reg,
        venue_name=venue_name,
        venue_address=venue_address,
        age_limit=age,
        cover_url=cover,
        external_url=item.get("site_url"),
    )


def _pick_upcoming_start(dates: list, since_ts: int, until_ts: int) -> datetime | None:
    best: int | None = None
    for d in dates:
        if not isinstance(d, dict):
            continue
        start = d.get("start")
        if not isinstance(start, int):
            continue
        if start < since_ts or start > until_ts:
            continue
        if best is None or start < best:
            best = start
    if best is None:
        return None
    return datetime.fromtimestamp(best, tz=UTC)


def _parse_age(value) -> int | None:
    if not value:
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        digits = "".join(ch for ch in value if ch.isdigit())
        if digits:
            return int(digits[:2])
    return None
