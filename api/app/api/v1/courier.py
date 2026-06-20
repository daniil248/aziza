"""Courier endpoints — order feed, atomic claim, status advancement."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import require_roles
from app.core.database import get_db
from app.models.order import Order, OrderStatus
from app.models.user import User, UserRole
from app.schemas.orders import CourierOrders, OrderOpsRead, StatusUpdate

router = APIRouter()

# Statuses an order can be in to appear in the public "available" feed.
_CLAIMABLE = (OrderStatus.confirmed, OrderStatus.preparing)
# Statuses a courier may advance an order to.
_ADVANCEABLE = (OrderStatus.in_transit, OrderStatus.delivered)


def _ops_query():
    """Order query with client, courier, address and items eagerly loaded."""
    return select(Order).options(
        selectinload(Order.items),
        selectinload(Order.client),
        selectinload(Order.courier),
        selectinload(Order.address),
    )


@router.get("/orders", response_model=CourierOrders)
async def courier_orders(
    current_user: User = Depends(require_roles(UserRole.courier)),
    db: AsyncSession = Depends(get_db),
) -> CourierOrders:
    avail_res = await db.execute(
        _ops_query()
        .where(Order.courier_id.is_(None), Order.status.in_(_CLAIMABLE))
        .order_by(Order.created_at)
    )
    mine_res = await db.execute(
        _ops_query()
        .where(
            Order.courier_id == current_user.id,
            Order.status.in_((OrderStatus.courier_assigned, OrderStatus.in_transit)),
        )
        .order_by(Order.created_at)
    )
    done_res = await db.execute(
        _ops_query()
        .where(Order.courier_id == current_user.id, Order.status == OrderStatus.delivered)
        .order_by(Order.created_at.desc())
        .limit(20)
    )
    return CourierOrders(
        available=[OrderOpsRead.model_validate(o) for o in avail_res.scalars().all()],
        mine=[OrderOpsRead.model_validate(o) for o in mine_res.scalars().all()],
        done=[OrderOpsRead.model_validate(o) for o in done_res.scalars().all()],
    )


@router.post("/orders/{order_id}/take", response_model=OrderOpsRead)
async def take_order(
    order_id: str,
    current_user: User = Depends(require_roles(UserRole.courier)),
    db: AsyncSession = Depends(get_db),
) -> Order:
    # Atomic claim — guarded UPDATE so two couriers can't both win the row.
    res = await db.execute(
        update(Order)
        .where(
            Order.id == order_id,
            Order.courier_id.is_(None),
            Order.status.in_(_CLAIMABLE),
        )
        .values(courier_id=current_user.id, status=OrderStatus.courier_assigned)
    )
    if res.rowcount == 0:
        # Either it doesn't exist, or it's already been taken / not claimable.
        exists = await db.execute(select(Order.id).where(Order.id == order_id))
        if exists.scalar_one_or_none() is None:
            raise HTTPException(status_code=404, detail="order not found")
        raise HTTPException(status_code=409, detail="order already taken")

    await db.flush()
    loaded = await db.execute(_ops_query().where(Order.id == order_id))
    return loaded.scalar_one()


@router.post("/orders/{order_id}/status", response_model=OrderOpsRead)
async def advance_status(
    order_id: str,
    payload: StatusUpdate,
    current_user: User = Depends(require_roles(UserRole.courier)),
    db: AsyncSession = Depends(get_db),
) -> Order:
    if payload.status not in _ADVANCEABLE:
        raise HTTPException(
            status_code=422,
            detail="courier may only set status to in_transit or delivered",
        )

    res = await db.execute(_ops_query().where(Order.id == order_id))
    order = res.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="order not found")
    if order.courier_id != current_user.id:
        raise HTTPException(status_code=403, detail="not your order")

    order.status = payload.status
    await db.flush()
    await db.refresh(order)
    return order
