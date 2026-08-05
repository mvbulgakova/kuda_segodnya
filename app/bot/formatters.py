from datetime import datetime
from zoneinfo import ZoneInfo

from app.config import settings
from app.models import Event, PriceKind

WEEKDAYS_RU = ["пн", "вт", "ср", "чт", "пт", "сб", "вс"]
MONTHS_RU = [
    "янв", "фев", "мар", "апр", "май", "июн",
    "июл", "авг", "сен", "окт", "ноя", "дек",
]

PRICE_LABELS = {
    PriceKind.free: "🆓 бесплатно",
    PriceKind.free_reg: "🆓 бесплатно по регистрации",
    PriceKind.free_student: "🎓 бесплатно по студенческому",
    PriceKind.paid: "💰 платно",
}


def format_time(dt: datetime) -> str:
    local = dt.astimezone(ZoneInfo(settings.tz))
    return f"{WEEKDAYS_RU[local.weekday()]} {local.day} {MONTHS_RU[local.month - 1]} · {local:%H:%M}"


def format_event_card(event: Event) -> str:
    lines: list[str] = []
    lines.append(f"<b>{_escape(event.title)}</b>")

    meta: list[str] = [format_time(event.starts_at)]
    if event.venue and event.venue.metro:
        meta.append(f"м. {_escape(event.venue.metro)}")
    if event.venue and event.venue.name:
        meta.append(_escape(event.venue.name))
    lines.append(" · ".join(meta))

    lines.append(PRICE_LABELS.get(event.price_kind, ""))

    if event.description:
        desc = event.description.strip().replace("\n", " ")
        if len(desc) > 240:
            desc = desc[:240].rstrip() + "…"
        lines.append("")
        lines.append(_escape(desc))

    return "\n".join(line for line in lines if line is not None)


def _escape(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
