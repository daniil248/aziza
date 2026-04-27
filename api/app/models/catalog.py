from typing import Any

from sqlalchemy import JSON, Boolean, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._base import TimestampMixin, UUIDPK


class Category(UUIDPK, TimestampMixin, Base):
    __tablename__ = "categories"

    slug: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    sort: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    name_i18n: Mapped[dict[str, str]] = mapped_column(JSON, default=dict, nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(500))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    products: Mapped[list["Product"]] = relationship(back_populates="category")


class Product(UUIDPK, TimestampMixin, Base):
    __tablename__ = "products"

    slug: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    category_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("categories.id", ondelete="RESTRICT"), index=True
    )
    name_i18n: Mapped[dict[str, str]] = mapped_column(JSON, default=dict, nullable=False)
    description_i18n: Mapped[dict[str, str]] = mapped_column(JSON, default=dict, nullable=False)
    ingredients_i18n: Mapped[dict[str, str]] = mapped_column(JSON, default=dict, nullable=False)
    cooking_i18n: Mapped[dict[str, str]] = mapped_column(JSON, default=dict, nullable=False)
    kbju: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict, nullable=False)
    variants: Mapped[list[dict[str, Any]]] = mapped_column(JSON, default=list, nullable=False)
    main_image_url: Mapped[str | None] = mapped_column(String(500))
    gallery_urls: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    sort: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    category: Mapped[Category] = relationship(back_populates="products")
