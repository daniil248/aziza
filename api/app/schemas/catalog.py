import uuid

from pydantic import BaseModel, Field

from app.schemas.common import ORMBase


class CategoryRead(ORMBase):
    id: uuid.UUID
    slug: str
    sort: int
    name_i18n: dict[str, str]
    image_url: str | None = None


class ProductVariant(BaseModel):
    label: str
    label_i18n: dict[str, str] = Field(default_factory=dict)
    weight_g: int
    price_minor: int


class KBJU(BaseModel):
    kcal: float = 0
    protein: float = 0
    fat: float = 0
    carb: float = 0


class ProductCard(ORMBase):
    id: uuid.UUID
    slug: str
    category_id: uuid.UUID
    name_i18n: dict[str, str]
    main_image_url: str | None = None
    variants: list[ProductVariant]


class ProductDetail(ProductCard):
    description_i18n: dict[str, str]
    ingredients_i18n: dict[str, str]
    cooking_i18n: dict[str, str]
    kbju: dict
    gallery_urls: list[str] = Field(default_factory=list)


class ProductWrite(BaseModel):
    """Used for both create and update. Optional fields → unchanged on update."""

    slug: str | None = None
    category_id: uuid.UUID | None = None
    name_i18n: dict[str, str] | None = None
    description_i18n: dict[str, str] | None = None
    ingredients_i18n: dict[str, str] | None = None
    cooking_i18n: dict[str, str] | None = None
    kbju: dict | None = None
    variants: list[dict] | None = None
    main_image_url: str | None = None
    gallery_urls: list[str] | None = None
    sort: int | None = None
    is_active: bool | None = None


class UploadResult(BaseModel):
    url: str
    filename: str
    size: int
