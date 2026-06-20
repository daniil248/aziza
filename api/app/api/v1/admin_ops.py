"""Admin operations — order oversight + courier management.

Kept separate from admin.py (products CRUD) on purpose.

SECURITY TODO: gate /admin/* behind nginx Basic Auth or admin JWT in prod.
These endpoints are intentionally UNGATED to match the existing /admin/products
behavior the deployed admin app relies on. Do NOT ship to a public origin without
a gate at the edge.
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.security import hash_password
from app.models.order import Order, OrderStatus
from app.models.user import User, UserRole
from app.schemas.auth import UserRead
from app.schemas.orders import (
    AssignCourier,
    CourierCreate,
    CourierRead,
    CourierUpdate,
    OrderOpsRead,
    StatusUpdate,
)
from app.schemas.common import Page

router = APIRouter()

# Order statuses that count against a courier's active workload.
_ACTIVE_COURIER_STATUSES = (OrderStatus.courier_assigned, OrderStatus.in_transit)


def _ops_query():
    return select(Order).options(
        selectinload(Order.items),
        selectinload(Order.client),
        selectinload(Order.courier),
        selectinload(Order.address),
    )


@router.get("/orders", response_model=list[OrderOpsRead])
async def admin_list_orders(
    status: OrderStatus | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
) -> list[Order]:
    stmt = _ops_query().order_by(Order.created_at.desc())
    if status is not None:
        stmt = stmt.where(Order.status == status)
    res = await db.execute(stmt)
    return list(res.scalars().all())


@router.get("/orders/{order_id}", response_model=OrderOpsRead)
async def admin_order_detail(order_id: str, db: AsyncSession = Depends(get_db)) -> Order:
    res = await db.execute(_ops_query().where(Order.id == order_id))
    order = res.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="order not found")
    return order


@router.post("/orders/{order_id}/status", response_model=OrderOpsRead)
async def admin_set_status(
    order_id: str, payload: StatusUpdate, db: AsyncSession = Depends(get_db)
) -> Order:
    res = await db.execute(_ops_query().where(Order.id == order_id))
    order = res.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="order not found")
    order.status = payload.status  # Admin may set any valid status.
    await db.flush()
    await db.refresh(order)
    return order


@router.post("/orders/{order_id}/assign", response_model=OrderOpsRead)
async def admin_assign_courier(
    order_id: str, payload: AssignCourier, db: AsyncSession = Depends(get_db)
) -> Order:
    res = await db.execute(_ops_query().where(Order.id == order_id))
    order = res.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="order not found")

    if payload.courier_id is not None:
        cour_res = await db.execute(
            select(User).where(
                User.id == str(payload.courier_id), User.role == UserRole.courier
            )
        )
        courier = cour_res.scalar_one_or_none()
        if not courier:
            raise HTTPException(status_code=422, detail="unknown courier")
        order.courier_id = courier.id
        if order.status in (OrderStatus.pending, OrderStatus.confirmed, OrderStatus.preparing):
            order.status = OrderStatus.courier_assigned
    else:
        order.courier_id = None

    await db.flush()
    await db.refresh(order)
    return order


# --- Courier management ---


@router.get("/couriers", response_model=list[CourierRead])
async def admin_list_couriers(db: AsyncSession = Depends(get_db)) -> list[CourierRead]:
    res = await db.execute(
        select(User).where(User.role == UserRole.courier).order_by(User.created_at)
    )
    couriers = list(res.scalars().all())

    # Active order counts in one grouped query.
    count_res = await db.execute(
        select(Order.courier_id, func.count(Order.id))
        .where(Order.status.in_(_ACTIVE_COURIER_STATUSES))
        .group_by(Order.courier_id)
    )
    counts = {cid: n for cid, n in count_res.all()}

    out: list[CourierRead] = []
    for c in couriers:
        item = CourierRead.model_validate(c)
        item.active_orders = counts.get(c.id, 0)
        out.append(item)
    return out


@router.post("/couriers", response_model=CourierRead, status_code=201)
async def admin_create_courier(
    payload: CourierCreate, db: AsyncSession = Depends(get_db)
) -> CourierRead:
    phone = "".join(ch for ch in payload.phone if ch.isdigit())
    if not phone:
        raise HTTPException(status_code=422, detail="invalid phone")
    existing = await db.execute(select(User).where(User.phone == phone))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="phone already registered")

    courier = User(
        phone=phone,
        name=payload.name,
        role=UserRole.courier,
        password_hash=hash_password(payload.password),
    )
    db.add(courier)
    await db.flush()
    await db.refresh(courier)
    return CourierRead.model_validate(courier)


@router.patch("/couriers/{courier_id}", response_model=CourierRead)
async def admin_update_courier(
    courier_id: str, payload: CourierUpdate, db: AsyncSession = Depends(get_db)
) -> CourierRead:
    res = await db.execute(
        select(User).where(User.id == courier_id, User.role == UserRole.courier)
    )
    courier = res.scalar_one_or_none()
    if not courier:
        raise HTTPException(status_code=404, detail="courier not found")

    data = payload.model_dump(exclude_unset=True)
    if "password" in data:
        pwd = data.pop("password")
        if pwd:
            courier.password_hash = hash_password(pwd)
    for field, value in data.items():
        setattr(courier, field, value)

    await db.flush()
    await db.refresh(courier)
    return CourierRead.model_validate(courier)


@router.get("/users", response_model=Page[UserRead])
async def admin_list_users(
    limit: int = Query(default=30, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> Page[UserRead]:
    base = select(User).where(User.role == UserRole.client)
    total = (await db.execute(select(func.count()).select_from(base.subquery()))).scalar_one()
    res = await db.execute(
        base.order_by(User.created_at.desc()).limit(limit).offset(offset)
    )
    items = [UserRead.model_validate(u) for u in res.scalars().all()]
    return Page(items=items, total=total, limit=limit, offset=offset)
