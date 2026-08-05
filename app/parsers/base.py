from dataclasses import dataclass
from datetime import datetime
from typing import Protocol

from app.models import PriceKind, SourceKind


@dataclass(slots=True)
class RawEvent:
    external_id: str
    title: str
    starts_at: datetime
    price_kind: PriceKind
    ends_at: datetime | None = None
    description: str | None = None
    venue_name: str | None = None
    venue_address: str | None = None
    age_limit: int | None = None
    cover_url: str | None = None
    external_url: str | None = None


class Parser(Protocol):
    slug: str
    kind: SourceKind
    title: str
    source_url: str | None

    async def parse(self) -> list[RawEvent]: ...
