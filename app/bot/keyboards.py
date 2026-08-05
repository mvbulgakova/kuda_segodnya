from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup

from app.models import Event


def event_card_kb(event: Event, going_count: int = 0) -> InlineKeyboardMarkup:
    going_label = f"🙋 Пойду ({going_count})" if going_count else "🙋 Пойду"
    rows: list[list[InlineKeyboardButton]] = [
        [InlineKeyboardButton(text=going_label, callback_data=f"going:{event.id}")]
    ]
    if event.canonical_url:
        rows[0].append(InlineKeyboardButton(text="Подробнее ↗", url=event.canonical_url))
    rows.append([InlineKeyboardButton(text="🚩 Пожаловаться", callback_data=f"report:{event.id}")])
    return InlineKeyboardMarkup(inline_keyboard=rows)


def more_kb(offset: int) -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [InlineKeyboardButton(text="Показать ещё", callback_data=f"today_more:{offset}")]
        ]
    )
