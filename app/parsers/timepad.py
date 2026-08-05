from datetime import UTC, datetime, timedelta

import httpx
import structlog
from dateutil import parser as dateparser

from app.config import settings
from app.models import PriceKind, SourceKind
from app.parsers.base import RawEvent

log = structlog.get_logger(__name__)

API_URL = "https://api.timepad.ru/v1/events"
PAGE_SIZE = 100
LOOKAHEAD_DAYS = 7


class TimepadParser:
    slug = "timepad"
    kind = SourceKind.api
    title = "Timepad"
    source_url = "https://timepad.ru/"

    async def parse(self) -> list[RawEvent]:
        if not settings.timepad_token:
            log.warning("timepad.skipped", reason="no token")
            return []

        starts_at_min = datetime.now(tz=UTC)
        starts_at_max = starts_at_min + timedelta(days=LOOKAHEAD_DAYS)

        base_params = {
            "cities": settings.timepad_cities,
            "starts_at_min": starts_at_min.strftime("%Y-%m-%dT%H:%M:%S"),
            "starts_at_max": starts_at_max.strftime("%Y-%m-%dT%H:%M:%S"),
            "fields": ",".join(
                [
                    "id",
                    "name",
                    "starts_at",
                    "ends_at",
                    "url",
                    "poster_image",
                    "location",
                    "description_short",
                    "description_html",
                    "registration_data",
                    "categories",
                    "age_limit",
                ]
            ),
            "limit": PAGE_SIZE,
        }

        headers = {"Authorization": f"Bearer {settings.timepad_token}"}
        events: list[RawEvent] = []
        async with httpx.AsyncClient(timeout=20.0, headers=headers) as client:
            for page in range(5):  # cap at 500 events
                params = {**base_params, "skip": page * PAGE_SIZE}
                resp = await client.get(API_URL, params=params)
                if resp.status_code == 401 or resp.status_code == 403:
                    log.warning("timepad.auth_failed", status=resp.status_code)
                    return events
                resp.raise_for_status()
                payload = resp.json()
                values = payload.get("values", [])
                if not values:
                    break
                for item in values:
                    ev = _to_raw(item)
                    if ev is not None:
                        events.append(ev)
                if len(values) < PAGE_SIZE:
                    break

        log.info("timepad.parsed", count=len(events))
        return events


def _to_raw(item: dict) -> RawEvent | None:
    price_kind = _price_kind(item.get("registration_data"))
    if price_kind == PriceKind.paid:
        return None

    starts_at_raw = item.get("starts_at")
    if not starts_at_raw:
        return None
    try:
        starts_at = dateparser.parse(starts_at_raw)
    except (ValueError, TypeError):
        return None
    if starts_at.tzinfo is None:
        starts_at = starts_at.replace(tzinfo=UTC)

    ends_at = None
    if item.get("ends_at"):
        try:
            ends_at = dateparser.parse(item["ends_at"])
            if ends_at.tzinfo is None:
                ends_at = ends_at.replace(tzinfo=UTC)
        except (ValueError, TypeError):
            ends_at = None

    location = item.get("location") or {}
    venue_name = None
    venue_address = None
    if isinstance(location, dict):
        city = location.get("city")
        address = location.get("address")
        venue_name = address if address else city
        venue_address = ", ".join([p for p in [city, address] if p]) or None

    title = (item.get("name") or "").strip()
    if not title:
        return None

    poster = item.get("poster_image") or {}
    cover = poster.get("default_url") if isinstance(poster, dict) else None

    age = item.get("age_limit")
    if isinstance(age, str):
        digits = "".join(ch for ch in age if ch.isdigit())
        age = int(digits[:2]) if digits else None

    return RawEvent(
        external_id=str(item["id"]),
        title=title[:512],
        description=(item.get("description_short") or "").strip() or None,
        starts_at=starts_at,
        ends_at=ends_at,
        price_kind=price_kind,
        venue_name=venue_name,
        venue_address=venue_address,
        age_limit=age if isinstance(age, int) else None,
        cover_url=cover,
        external_url=item.get("url"),
    )


def _price_kind(reg_data) -> PriceKind:
    """Timepad возвращает registration_data.price_min / price_max."""
    if not isinstance(reg_data, dict):
        return PriceKind.free_reg  # regisration.ru события по регистрации по умолчанию

    price_min = reg_data.get("price_min")
    price_max = reg_data.get("price_max")
    is_registration_open = reg_data.get("is_registration_open", True)

    if price_min == 0 and (price_max == 0 or price_max is None):
        return PriceKind.free_reg if is_registration_open else PriceKind.free
    if price_min is None and price_max is None:
        return PriceKind.free_reg
    return PriceKind.paid
