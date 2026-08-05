from aiogram import Router
from aiogram.filters import CommandStart
from aiogram.types import Message
from sqlalchemy import select

from app.db import session_scope
from app.models import User

router = Router(name="start")

GREETING = (
    "Привет! Я — <b>Куда сегодня</b> 👋\n\n"
    "Собираю бесплатные события Москвы для студентов: лекции, выставки, "
    "концерты, стендапы, воркшопы.\n\n"
    "Команды:\n"
    "· /сегодня — что бесплатного сегодня\n"
    "· /завтра — на завтра (скоро)\n"
    "· /выходные — на выходные (скоро)\n"
)


@router.message(CommandStart())
async def start(message: Message) -> None:
    if message.from_user is None:
        return
    async with session_scope() as session:
        existing = (
            await session.execute(select(User).where(User.tg_id == message.from_user.id))
        ).scalar_one_or_none()
        if existing is None:
            session.add(
                User(
                    tg_id=message.from_user.id,
                    username=message.from_user.username,
                    first_name=message.from_user.first_name,
                )
            )
    await message.answer(GREETING)
