import asyncio

from app.logging_config import setup_logging
from app.scheduler import run_all_parsers


def main() -> None:
    setup_logging()
    asyncio.run(run_all_parsers())


if __name__ == "__main__":
    main()
