from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from aiogram import F, Router
from aiogram.filters import Command
from aiogram.types import CallbackQuery, Message
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.bot.formatters import format_event_card
from app.bot.keyboards import event_card_kb, more_kb
from app.config import settings
from app.db import session_scope
from app.models import Attendance, Event, EventStatus, PriceKind

router = Router(name="today")

PAGE_SIZE = 5
EMPTY_MSG = (
    "На сегодня бесплатного пока пусто 😔\n"
    "Попробуй /завтра или загляни попозже — база обновляется каждый час."
)


def _today_window() -> tuple[datetime, datetime]:
    tz = ZoneInfo(settings.tz)
    now_local = datetime.now(tz)
    start = now_local
    end = (now_local + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
    return start, end


async def _fetch_events(session: AsyncSession, offset: int, limit: int) -> list[Event]:
    start, end = _today_window()
    stmt = (
        select(Event)
        .where(
            Event.status == EventStatus.published,
            Event.price_kind.in_(
                [PriceKind.free, PriceKind.free_reg, PriceKind.free_student]
            ),
            Event.starts_at >= start,
            Event.starts_at < end,
        )
        .order_by(Event.starts_at.asc())
        .offset(offset)
        .limit(limit)
    )
    result = await session.execute(stmt)
    return list(result.scalars().unique().all())


async def _going_counts(session: AsyncSession, event_ids: list[int]) -> dict[int, int]:
    if not event_ids:
        return {}
    stmt = (
        select(Attendance.event_id, func.count(Attendance.id))
        .where(Attendance.event_id.in_(event_ids), Attendance.status == "going")
        .group_by(Attendance.event_id)
    )
    return dict((await session.execute(stmt)).all())


async def _send_page(message_or_cb: Message | CallbackQuery, offset: int) -> None:
    async with session_scope() as session:
        events = await _fetch_events(session, offset, PAGE_SIZE)
        counts = await _going_counts(session, [e.id for e in events])

    target: Message = (
        message_or_cb.message if isinstance(message_or_cb, CallbackQuery) else message_or_cb
    )

    if not events and offset == 0:
        await target.answer(EMPTY_MSG)
        return
    if not events:
        await target.answer("Больше событий на сегодня нет.")
        return

    for e in events:
        await target.answer(
            format_event_card(e),
            reply_markup=event_card_kb(e, counts.get(e.id, 0)),
            parse_mode="HTML",
        )

    # Show "more" button if we hit page size (might be more available)
    if len(events) == PAGE_SIZE:
        await target.answer("...", reply_markup=more_kb(offset + PAGE_SIZE))


@router.message(Command(commands=["сегодня", "today"]))
async def cmd_today(message: Message) -> None:
    await _send_page(message, offset=0)


@router.callback_query(F.data.startswith("today_more:"))
async def cb_more(cb: CallbackQuery) -> None:
    if not cb.data:
        return
    try:
        offset = int(cb.data.split(":", 1)[1])
    except (ValueError, IndexError):
        await cb.answer()
        return
    await cb.answer()
    if cb.message:
        try:
            await cb.message.delete()
        except Exception:
            pass
    await _send_page(cb, offset=offset)
