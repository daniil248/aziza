from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.catalog import Category, Product
from app.schemas.catalog import CategoryRead, ProductCard, ProductDetail
from app.schemas.common import Page

router = APIRouter()
products_router = APIRouter()


@router.get("", response_model=list[CategoryRead])
async def list_categories(db: AsyncSession = Depends(get_db)) -> list[Category]:
    res = await db.execute(
        select(Category).where(Category.is_active.is_(True)).order_by(Category.sort)
    )
    return list(res.scalars().all())


@products_router.get("", response_model=Page[ProductCard])
async def list_products(
    category: str | None = Query(default=None, description="category slug"),
    q: str | None = Query(default=None, max_length=100),
    limit: int = Query(default=30, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> Page[ProductCard]:
    stmt = select(Product).where(Product.is_active.is_(True)).order_by(Product.sort)

    if category:
        stmt = stmt.join(Category, Product.category_id == Category.id).where(
            Category.slug == category
        )

    res = await db.execute(stmt)
    rows = list(res.scalars().all())

    # Python-side i18n search — keeps SQL portable across SQLite (dev) and Postgres (prod).
    if q:
        needle = q.lower()
        rows = [
            p for p in rows
            if any(
                isinstance(v, str) and needle in v.lower()
                for v in (p.name_i18n or {}).values()
            )
        ]

    total = len(rows)
    items = [ProductCard.model_validate(p) for p in rows[offset : offset + limit]]
    return Page(items=items, total=total, limit=limit, offset=offset)


@products_router.get("/{slug}", response_model=ProductDetail)
async def get_product(slug: str, db: AsyncSession = Depends(get_db)) -> Product:
    res = await db.execute(
        select(Product).where(Product.slug == slug, Product.is_active.is_(True))
    )
    product = res.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product
