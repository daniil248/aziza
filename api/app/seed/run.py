"""Seed script — run with: `python -m app.seed.run`."""

import asyncio

from sqlalchemy import select

from app.core.database import AsyncSessionLocal, Base, engine
from app.models.catalog import Category, Product
from app.models.promo import Promo, PromoType
from app.seed.data import CATEGORIES, IMAGES, PRODUCTS, PROMOS


async def seed() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        cat_by_slug: dict[str, Category] = {}
        for c in CATEGORIES:
            existing = await db.execute(select(Category).where(Category.slug == c["slug"]))
            row = existing.scalar_one_or_none()
            if row:
                row.sort = c["sort"]
                row.name_i18n = c["name_i18n"]
                cat_by_slug[c["slug"]] = row
            else:
                cat = Category(**c, is_active=True)
                db.add(cat)
                cat_by_slug[c["slug"]] = cat
        await db.flush()

        for p in PRODUCTS:
            slug = p["slug"]
            existing = await db.execute(select(Product).where(Product.slug == slug))
            row = existing.scalar_one_or_none()
            payload = {
                "slug": slug,
                "category_id": cat_by_slug[p["category"]].id,
                "sort": p.get("sort", 0),
                "name_i18n": p["name_i18n"],
                "description_i18n": p["description_i18n"],
                "ingredients_i18n": p["ingredients_i18n"],
                "cooking_i18n": p["cooking_i18n"],
                "kbju": p["kbju"],
                "variants": p["variants"],
                "is_active": True,
                "main_image_url": IMAGES.get(slug),
                "gallery_urls": [],
            }
            if row:
                for k, v in payload.items():
                    setattr(row, k, v)
            else:
                db.add(Product(**payload))

        for promo in PROMOS:
            existing = await db.execute(select(Promo).where(Promo.code == promo["code"]))
            if existing.scalar_one_or_none():
                continue
            db.add(
                Promo(
                    code=promo["code"],
                    type=PromoType(promo["type"]),
                    value=promo["value"],
                    min_order_minor=promo["min_order_minor"],
                    is_active=True,
                )
            )

        await db.commit()
        print(f"Seeded {len(CATEGORIES)} categories, {len(PRODUCTS)} products, {len(PROMOS)} promos.")


if __name__ == "__main__":
    asyncio.run(seed())
