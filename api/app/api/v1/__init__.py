from fastapi import APIRouter

from app.api.v1 import admin, catalog, health

router = APIRouter()
router.include_router(health.router)
router.include_router(catalog.router, prefix="/categories", tags=["catalog"])
router.include_router(catalog.products_router, prefix="/products", tags=["catalog"])
router.include_router(admin.router, prefix="/admin", tags=["admin"])
