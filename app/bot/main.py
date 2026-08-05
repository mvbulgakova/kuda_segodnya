import structlog
from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.enums import ParseMode
from aiogram.types import BotCommand

from app.bot.handlers import main_router
from app.config import settings

log = structlog.get_logger(__name__)


def create_bot() -> Bot:
    if not settings.telegram_bot_token:
        raise RuntimeError("TELEGRAM_BOT_TOKEN is not set")
    return Bot(
        token=settings.telegram_bot_token,
        default=DefaultBotProperties(parse_mode=ParseMode.HTML),
    )


def create_dispatcher() -> Dispatcher:
    dp = Dispatcher()
    dp.include_router(main_router)
    return dp


async def set_bot_commands(bot: Bot) -> None:
    await bot.set_my_commands(
        [
            BotCommand(command="сегодня", description="Что бесплатного сегодня"),
            BotCommand(command="start", description="Приветствие"),
        ]
    )


async def run_bot() -> None:
    bot = create_bot()
    dp = create_dispatcher()
    await set_bot_commands(bot)
    log.info("bot.starting")
    await dp.start_polling(bot)
