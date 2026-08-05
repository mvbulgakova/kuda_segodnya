from app.parsers.base import Parser, RawEvent
from app.parsers.kudago import KudaGoParser
from app.parsers.timepad import TimepadParser

ALL_PARSERS: list[Parser] = [
    KudaGoParser(),
    TimepadParser(),
]

__all__ = ["ALL_PARSERS", "Parser", "RawEvent"]
