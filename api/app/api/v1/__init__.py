from fastapi import APIRouter

from app.api.v1 import admin, admin_ops, auth, catalog, courier, health, orders

router = APIRouter()
router.include_router(health.router)
router.include_router(catalog.router, prefix="/categories", tags=["catalog"])
router.include_router(catalog.products_router, prefix="/products", tags=["catalog"])
router.include_router(admin.router, prefix="/admin", tags=["admin"])
router.include_router(admin_ops.router, prefix="/admin", tags=["admin"])
router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(orders.router, prefix="/orders", tags=["orders"])
router.include_router(courier.router, prefix="/courier", tags=["courier"])
