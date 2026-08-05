import hashlib
import re
import unicodedata
from datetime import datetime

_PUNCT_RE = re.compile(r"[^\w\s]", flags=re.UNICODE)
_WS_RE = re.compile(r"\s+")


def normalize_title(title: str) -> str:
    t = unicodedata.normalize("NFKC", title).lower().strip()
    t = t.replace("ё", "е")
    t = _PUNCT_RE.sub(" ", t)
    t = _WS_RE.sub(" ", t).strip()
    return t


def normalize_venue(name: str | None) -> str:
    if not name:
        return ""
    return normalize_title(name)


def dedup_hash(title: str, starts_at: datetime, venue_name: str | None) -> str:
    parts = "|".join(
        [
            normalize_title(title),
            starts_at.astimezone().strftime("%Y-%m-%dT%H:%M"),
            normalize_venue(venue_name),
        ]
    )
    return hashlib.sha1(parts.encode("utf-8")).hexdigest()
