# Куда сегодня

Telegram-бот с бесплатными событиями Москвы для студентов.

## Что это

Агрегатор бесплатных культурных, образовательных и развлекательных событий Москвы,
собранных из открытых API (Timepad, KudaGo), порталов города (mos.ru, mosmolodezh, culture.ru)
и Telegram-каналов. Живёт как Telegram-бот, отдаёт афишу на сегодня/завтра/выходные.

## MVP-скоуп (неделя 1)

- [x] Скелет проекта, docker-compose, alembic
- [x] Парсеры: Timepad, KudaGo
- [x] Нормализация и дедуп событий по хэшу
- [x] Бот с командой `/сегодня` — отдаёт 10 карточек бесплатных событий

## Как запустить локально

1. Скопировать `.env.example` в `.env` и заполнить `TELEGRAM_BOT_TOKEN`.
   - Опционально: `TIMEPAD_TOKEN` (см. https://dev.timepad.ru/api/oauth/) — без него парсер Timepad пропускается, KudaGo работает без токена.
2. `docker compose up -d postgres`
3. `docker compose run --rm bot alembic upgrade head`
4. `docker compose run --rm scheduler python -m app.entrypoints.parse_once` — прогнать парсеры разово
5. `docker compose up -d bot scheduler`

## Структура

```
app/
  config.py           # настройки из env
  db.py               # async SQLAlchemy
  models.py           # ORM модели
  parsers/            # источники событий
  pipeline/           # нормализация, дедуп, сохранение
  bot/                # aiogram handlers
  scheduler.py        # APScheduler jobs
  entrypoints/        # run_bot, run_scheduler, parse_once
migrations/           # alembic
data/                 # справочники (метро)
```
