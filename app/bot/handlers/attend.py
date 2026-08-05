from aiogram import F, Router
from aiogram.types import CallbackQuery
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert

from app.bot.formatters import format_event_card
from app.bot.keyboards import event_card_kb
from app.db import session_scope
from app.models import Attendance, Event, Report, User

router = Router(name="attend")


@router.callback_query(F.data.startswith("going:"))
async def cb_going(cb: CallbackQuery) -> None:
    if not cb.data or cb.from_user is None:
        await cb.answer()
        return
    try:
        event_id = int(cb.data.split(":", 1)[1])
    except (ValueError, IndexError):
        await cb.answer()
        return

    async with session_scope() as session:
        user = (
            await session.execute(select(User).where(User.tg_id == cb.from_user.id))
        ).scalar_one_or_none()
        if user is None:
            user = User(
                tg_id=cb.from_user.id,
                username=cb.from_user.username,
                first_name=cb.from_user.first_name,
            )
            session.add(user)
            await session.flush()

        stmt = (
            pg_insert(Attendance)
            .values(user_id=user.id, event_id=event_id, status="going")
            .on_conflict_do_nothing(constraint="uq_user_event")
        )
        await session.execute(stmt)

        going_count = (
            await session.execute(
                select(func.count(Attendance.id)).where(
                    Attendance.event_id == event_id, Attendance.status == "going"
                )
            )
        ).scalar_one()

        event = (
            await session.execute(select(Event).where(Event.id == event_id))
        ).scalar_one_or_none()

    await cb.answer(f"Записал! Пойдут {going_count} чел.", show_alert=False)
    if cb.message and event:
        try:
            await cb.message.edit_text(
                format_event_card(event),
                reply_markup=event_card_kb(event, going_count),
                parse_mode="HTML",
            )
        except Exception:
            pass


@router.callback_query(F.data.startswith("report:"))
async def cb_report(cb: CallbackQuery) -> None:
    if not cb.data or cb.from_user is None:
        await cb.answer()
        return
    try:
        event_id = int(cb.data.split(":", 1)[1])
    except (ValueError, IndexError):
        await cb.answer()
        return

    async with session_scope() as session:
        user = (
            await session.execute(select(User).where(User.tg_id == cb.from_user.id))
        ).scalar_one_or_none()
        if user is None:
            user = User(tg_id=cb.from_user.id, username=cb.from_user.username)
            session.add(user)
            await session.flush()
        session.add(Report(user_id=user.id, event_id=event_id, reason="paid"))

    await cb.answer("Спасибо, проверим!", show_alert=False)
