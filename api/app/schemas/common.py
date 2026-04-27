from typing import Generic, TypeVar

from pydantic import BaseModel, ConfigDict, Field

T = TypeVar("T")


class ORMBase(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class I18n(BaseModel):
    ru: str = ""
    kk: str = ""
    en: str = ""


class Page(BaseModel, Generic[T]):
    items: list[T]
    total: int
    limit: int = Field(default=20, ge=1, le=100)
    offset: int = Field(default=0, ge=0)
