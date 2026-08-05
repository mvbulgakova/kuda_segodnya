from datetime import datetime
from types import SimpleNamespace
from zoneinfo import ZoneInfo

from app.bot.formatters import format_event_card, format_time
from app.models import PriceKind


def test_format_time_uses_moscow_tz():
    dt = datetime(2026, 8, 5, 16, 0, tzinfo=ZoneInfo("UTC"))
    # 19:00 в Moscow (UTC+3)
    assert "19:00" in format_time(dt)


def test_format_event_card_escapes_html():
    event = SimpleNamespace(
        title="Hack & Slash <script>",
        description=None,
        starts_at=datetime(2026, 8, 5, 16, 0, tzinfo=ZoneInfo("UTC")),
        venue=None,
        price_kind=PriceKind.free,
    )
    card = format_event_card(event)
    assert "&lt;script&gt;" in card
    assert "&amp;" in card


def test_format_event_card_includes_venue_and_metro():
    venue = SimpleNamespace(name="Библиотека", metro="Тургеневская")
    event = SimpleNamespace(
        title="Лекция",
        description=None,
        starts_at=datetime(2026, 8, 5, 16, 0, tzinfo=ZoneInfo("UTC")),
        venue=venue,
        price_kind=PriceKind.free,
    )
    card = format_event_card(event)
    assert "Тургеневская" in card
    assert "Библиотека" in card
