from datetime import datetime, timezone

from app.pipeline.normalize import dedup_hash, normalize_title, normalize_venue


def test_normalize_title_removes_punct_and_case():
    assert normalize_title("Лекция: «Как жить?!»") == "лекция как жить"


def test_normalize_title_yo_to_e():
    assert normalize_title("Ёжик") == normalize_title("Ежик")


def test_normalize_venue_empty():
    assert normalize_venue(None) == ""
    assert normalize_venue("") == ""


def test_dedup_hash_stable_across_source_wording():
    dt = datetime(2026, 8, 5, 19, 0, tzinfo=timezone.utc)
    a = dedup_hash("Лекция «Всё о котах»", dt, "Библиотека им. Достоевского")
    b = dedup_hash("лекция  все о котах", dt, "Библиотека им Достоевского")
    assert a == b


def test_dedup_hash_differs_on_time():
    dt1 = datetime(2026, 8, 5, 19, 0, tzinfo=timezone.utc)
    dt2 = datetime(2026, 8, 5, 20, 0, tzinfo=timezone.utc)
    assert dedup_hash("X", dt1, "Y") != dedup_hash("X", dt2, "Y")


def test_dedup_hash_differs_on_venue():
    dt = datetime(2026, 8, 5, 19, 0, tzinfo=timezone.utc)
    assert dedup_hash("X", dt, "A") != dedup_hash("X", dt, "B")
