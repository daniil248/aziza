import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.models.order import OrderStatus, PaymentMethod, PaymentStatus
from app.schemas.auth import AddressRead
from app.schemas.common import ORMBase


class OrderItemIn(BaseModel):
    product_id: uuid.UUID
    variant_label: str = Field(min_length=1, max_length=40)
    qty: int = Field(ge=1, le=999)


class OrderCreate(BaseModel):
    address_id: uuid.UUID
    items: list[OrderItemIn] = Field(min_length=1)
    payment_method: PaymentMethod = PaymentMethod.cash
    comment: str | None = Field(default=None, max_length=500)
    promo_code: str | None = Field(default=None, max_length=40)
    scheduled_for: datetime | None = None


class OrderItemRead(ORMBase):
    id: uuid.UUID
    product_id: uuid.UUID
    variant_label: str
    qty: int
    unit_price_minor: int
    total_minor: int


class OrderRead(ORMBase):
    """Client-facing order view. Money is always in minor units (integers)."""

    id: uuid.UUID
    code: str
    status: OrderStatus
    payment_method: PaymentMethod
    payment_status: PaymentStatus
    subtotal_minor: int
    delivery_fee_minor: int
    discount_minor: int
    total_minor: int
    promo_code: str | None = None
    comment: str | None = None
    scheduled_for: datetime | None = None
    created_at: datetime
    items: list[OrderItemRead] = Field(default_factory=list)


# --- Party summaries embedded in courier/admin order views ---


class PartyRead(ORMBase):
    """Lightweight client/courier summary embedded in operational order views."""

    id: uuid.UUID
    name: str | None = None
    phone: str | None = None


class OrderOpsRead(OrderRead):
    """Order view for courier/admin — adds client, courier and address details."""

    client: PartyRead | None = None
    courier: PartyRead | None = None
    address: AddressRead | None = None


class CourierOrders(BaseModel):
    available: list[OrderOpsRead]
    mine: list[OrderOpsRead]
    done: list[OrderOpsRead]


class StatusUpdate(BaseModel):
    status: OrderStatus


class AssignCourier(BaseModel):
    courier_id: uuid.UUID | None = None


# --- Admin courier management ---


class CourierRead(ORMBase):
    id: uuid.UUID
    phone: str | None = None
    name: str | None = None
    is_active: bool
    active_orders: int = 0


class CourierCreate(BaseModel):
    phone: str = Field(min_length=4, max_length=32)
    name: str | None = Field(default=None, max_length=120)
    password: str = Field(min_length=6, max_length=128)


class CourierUpdate(BaseModel):
    is_active: bool | None = None
    name: str | None = Field(default=None, max_length=120)
    password: str | None = Field(default=None, min_length=6, max_length=128)
