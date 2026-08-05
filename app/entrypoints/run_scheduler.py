import asyncio

import structlog

from app.logging_config import setup_logging
from app.scheduler import build_scheduler, run_all_parsers

log = structlog.get_logger(__name__)


async def main_async() -> None:
    scheduler = build_scheduler()
    scheduler.start()
    log.info("scheduler.started")
    # прогреваем сразу, чтобы не ждать первый тик
    await run_all_parsers()
    # держим event loop живым
    await asyncio.Event().wait()


def main() -> None:
    setup_logging()
    try:
        asyncio.run(main_async())
    except (KeyboardInterrupt, SystemExit):
        pass


if __name__ == "__main__":
    main()
