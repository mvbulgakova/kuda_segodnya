from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    telegram_bot_token: str = ""

    database_url: str = "postgresql+asyncpg://kuda:kuda@localhost:5432/kuda_segodnya"

    tz: str = "Europe/Moscow"
    log_level: str = "INFO"

    timepad_cities: str = "Москва"
    timepad_token: str = ""  # https://dev.timepad.ru/api/oauth/ — без токена парсер пропускается
    kudago_location: str = "msk"

    gemini_api_key: str = ""

    parse_interval_minutes: int = Field(default=60, ge=5)
    events_per_page: int = 10


settings = Settings()
