import asyncio

from app.bot.main import run_bot
from app.logging_config import setup_logging


def main() -> None:
    setup_logging()
    asyncio.run(run_bot())


if __name__ == "__main__":
    main()
