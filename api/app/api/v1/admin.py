"""Admin endpoints — CRUD for products + image upload.

NOTE: no auth gate yet. In production we add a JWT requirement / IP allowlist.
For local dev this is fine — backend is bound to localhost.
"""

import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.catalog import Product
from app.schemas.catalog import ProductDetail, ProductWrite, UploadResult

router = APIRouter()

# Where uploads are persisted on disk. Mounted as /static/* in main.py.
UPLOAD_ROOT = Path(__file__).resolve().parents[3] / "static" / "products"
UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)

ALLOWED_MIME = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "image/gif": "gif",
    "image/avif": "avif",
}
MAX_BYTES = 8 * 1024 * 1024  # 8 MB


@router.get("/products", response_model=list[ProductDetail])
async def admin_list_products(db: AsyncSession = Depends(get_db)) -> list[Product]:
    res = await db.execute(select(Product).order_by(Product.sort))
    return list(res.scalars().all())


@router.post("/products", response_model=ProductDetail, status_code=201)
async def admin_create_product(
    payload: ProductWrite, db: AsyncSession = Depends(get_db)
) -> Product:
    if not payload.slug or not payload.category_id or not payload.name_i18n:
        raise HTTPException(
            status_code=422, detail="slug, category_id, name_i18n are required to create"
        )
    existing = await db.execute(select(Product).where(Product.slug == payload.slug))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="slug already exists")

    product = Product(
        slug=payload.slug,
        category_id=str(payload.category_id),
        name_i18n=payload.name_i18n or {},
        description_i18n=payload.description_i18n or {},
        ingredients_i18n=payload.ingredients_i18n or {},
        cooking_i18n=payload.cooking_i18n or {},
        kbju=payload.kbju or {},
        variants=payload.variants or [],
        main_image_url=payload.main_image_url,
        gallery_urls=payload.gallery_urls or [],
        sort=payload.sort or 0,
        is_active=payload.is_active if payload.is_active is not None else True,
    )
    db.add(product)
    await db.flush()
    await db.refresh(product)
    return product


@router.patch("/products/{product_id}", response_model=ProductDetail)
async def admin_update_product(
    product_id: str, payload: ProductWrite, db: AsyncSession = Depends(get_db)
) -> Product:
    res = await db.execute(select(Product).where(Product.id == product_id))
    product = res.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="not found")

    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        if field == "category_id" and value is not None:
            value = str(value)
        setattr(product, field, value)

    await db.flush()
    await db.refresh(product)
    return product


@router.delete("/products/{product_id}", status_code=204)
async def admin_delete_product(product_id: str, db: AsyncSession = Depends(get_db)) -> None:
    res = await db.execute(select(Product).where(Product.id == product_id))
    product = res.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="not found")
    await db.delete(product)


@router.post("/upload", response_model=UploadResult)
async def admin_upload_image(file: UploadFile = File(...)) -> UploadResult:
    """Accept any common image format; persist under /static/products/<uuid>.<ext>."""
    mime = file.content_type or ""
    if mime not in ALLOWED_MIME:
        raise HTTPException(
            status_code=415,
            detail=f"unsupported type: {mime}. allowed: {', '.join(ALLOWED_MIME)}",
        )

    # Read enforcing size cap.
    body = await file.read(MAX_BYTES + 1)
    if len(body) > MAX_BYTES:
        raise HTTPException(status_code=413, detail="file too large (max 8 MB)")

    ext = ALLOWED_MIME[mime]
    fname = f"{uuid.uuid4().hex}.{ext}"
    target = UPLOAD_ROOT / fname
    target.write_bytes(body)

    # URL is host-relative; the host (localhost or prod CDN) is contributed by the client.
    url = f"/static/products/{fname}"
    return UploadResult(url=url, filename=fname, size=len(body))
