"""Client order endpoints — placing orders, listing, detail, cancel.

Prices are always computed server-side from the catalog. The client only sends
product + variant + qty; it never dictates money.
"""

import secrets

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import require_roles
from app.core.config import get_settings
from app.core.database import get_db
from app.models.catalog import Product
from app.models.order import Order, OrderItem, OrderStatus
from app.models.user import Address, User, UserRole
from app.schemas.orders import OrderCreate, OrderRead

router = APIRouter()
settings = get_settings()

# Crockford-ish base32 alphabet — no ambiguous 0/O/1/I/L. 6 chars ≈ 1.07e9 codes.
_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"


def _gen_code(n: int = 6) -> str:
    return "".join(secrets.choice(_CODE_ALPHABET) for _ in range(n))


async def _unique_code(db: AsyncSession) -> str:
    """Generate a short order code, retrying on the (rare) collision."""
    for _ in range(10):
        code = _gen_code()
        existing = await db.execute(select(Order.id).where(Order.code == code))
        if existing.scalar_one_or_none() is None:
            return code
    # Extremely unlikely — widen the space rather than fail.
    return _gen_code(10)


async def _load_order(db: AsyncSession, order_id: str) -> Order | None:
    res = await db.execute(
        select(Order).where(Order.id == order_id).options(selectinload(Order.items))
    )
    return res.scalar_one_or_none()


@router.post("", response_model=OrderRead, status_code=201)
async def create_order(
    payload: OrderCreate,
    current_user: User = Depends(require_roles(UserRole.client)),
    db: AsyncSession = Depends(get_db),
) -> Order:
    # Address must belong to the ordering client.
    res = await db.execute(
        select(Address).where(
            Address.id == str(payload.address_id), Address.user_id == current_user.id
        )
    )
    address = res.scalar_one_or_none()
    if not address:
        raise HTTPException(status_code=422, detail="unknown address")

    order_items: list[OrderItem] = []
    subtotal = 0
    for line in payload.items:
        prod_res = await db.execute(
            select(Product).where(
                Product.id == str(line.product_id), Product.is_active.is_(True)
            )
        )
        product = prod_res.scalar_one_or_none()
        if not product:
            raise HTTPException(
                status_code=422, detail=f"unknown product: {line.product_id}"
            )

        # Resolve the price from the product's variants (source of truth).
        variant = next(
            (v for v in (product.variants or []) if v.get("label") == line.variant_label),
            None,
        )
        if variant is None or "price_minor" not in variant:
            raise HTTPException(
                status_code=422,
                detail=f"unknown variant '{line.variant_label}' for product {product.slug}",
            )

        unit_price = int(variant["price_minor"])
        line_total = unit_price * line.qty
        subtotal += line_total
        order_items.append(
            OrderItem(
                product_id=product.id,
                variant_label=line.variant_label,
                qty=line.qty,
                unit_price_minor=unit_price,
                total_minor=line_total,
            )
        )

    delivery_fee = settings.delivery_fee_minor
    discount = 0  # Promo engine TODO — promo_code is recorded but not yet applied.
    total = subtotal + delivery_fee - discount

    order = Order(
        code=await _unique_code(db),
        client_id=current_user.id,
        address_id=address.id,
        status=OrderStatus.pending,
        payment_method=payload.payment_method,
        subtotal_minor=subtotal,
        delivery_fee_minor=delivery_fee,
        discount_minor=discount,
        total_minor=total,
        promo_code=payload.promo_code,
        comment=payload.comment,
        scheduled_for=payload.scheduled_for,
        items=order_items,
    )
    db.add(order)
    await db.flush()
    # Re-load with items eagerly populated for the response.
    return await _load_order(db, order.id)


@router.get("", response_model=list[OrderRead])
async def my_orders(
    current_user: User = Depends(require_roles(UserRole.client)),
    db: AsyncSession = Depends(get_db),
) -> list[Order]:
    res = await db.execute(
        select(Order)
        .where(Order.client_id == current_user.id)
        .options(selectinload(Order.items))
        .order_by(Order.created_at.desc())
    )
    return list(res.scalars().all())


@router.get("/{order_id}", response_model=OrderRead)
async def my_order_detail(
    order_id: str,
    current_user: User = Depends(require_roles(UserRole.client)),
    db: AsyncSession = Depends(get_db),
) -> Order:
    order = await _load_order(db, order_id)
    if not order or order.client_id != current_user.id:
        raise HTTPException(status_code=404, detail="order not found")
    return order


@router.post("/{order_id}/cancel", response_model=OrderRead)
async def cancel_order(
    order_id: str,
    current_user: User = Depends(require_roles(UserRole.client)),
    db: AsyncSession = Depends(get_db),
) -> Order:
    order = await _load_order(db, order_id)
    if not order or order.client_id != current_user.id:
        raise HTTPException(status_code=404, detail="order not found")
    if order.status not in (OrderStatus.pending, OrderStatus.confirmed):
        raise HTTPException(
            status_code=409, detail=f"cannot cancel order in status '{order.status.value}'"
        )
    order.status = OrderStatus.cancelled
    await db.flush()
    await db.refresh(order)
    return order
