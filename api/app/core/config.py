from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Local dev uses SQLite — zero setup. For prod, switch via env var to Postgres
    # (see docs/PRODUCTION.md).
    database_url: str = Field(default="sqlite+aiosqlite:///./aziza.db")
    secret_key: str = Field(default="dev-secret-change-in-prod")
    environment: str = Field(default="development")
    cors_origins: list[str] = Field(
        default=[
            "http://localhost:3000",
            "http://localhost:8080",
            "http://localhost:5173",
            "http://localhost:64000",  # default flutter web port
        ]
    )
    access_token_ttl_min: int = 15
    refresh_token_ttl_days: int = 30
    api_v1_prefix: str = "/api/v1"


@lru_cache
def get_settings() -> Settings:
    return Settings()
