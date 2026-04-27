import enum
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, DateTime, Enum, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._base import TimestampMixin, UUIDPK

if TYPE_CHECKING:
    from app.models.user import Address, User


class OrderStatus(str, enum.Enum):
    pending = "pending"
    confirmed = "confirmed"
    preparing = "preparing"
    courier_assigned = "courier_assigned"
    in_transit = "in_transit"
    delivered = "delivered"
    cancelled = "cancelled"


class PaymentMethod(str, enum.Enum):
    cash = "cash"
    card_online = "card_online"
    kaspi = "kaspi"
    halyk = "halyk"
    apple_pay = "apple_pay"
    google_pay = "google_pay"


class PaymentStatus(str, enum.Enum):
    pending = "pending"
    paid = "paid"
    refunded = "refunded"
    failed = "failed"


class Order(UUIDPK, TimestampMixin, Base):
    __tablename__ = "orders"

    code: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    client_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="RESTRICT"), index=True
    )
    address_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("addresses.id", ondelete="RESTRICT")
    )
    courier_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="SET NULL"), index=True
    )

    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus, name="order_status"), default=OrderStatus.pending, nullable=False
    )
    payment_method: Mapped[PaymentMethod] = mapped_column(
        Enum(PaymentMethod, name="payment_method"), default=PaymentMethod.cash
    )
    payment_status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, name="payment_status"), default=PaymentStatus.pending
    )

    subtotal_minor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    delivery_fee_minor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    discount_minor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    total_minor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    promo_code: Mapped[str | None] = mapped_column(String(40))
    comment: Mapped[str | None] = mapped_column(String(500))
    scheduled_for: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    client: Mapped["User"] = relationship(foreign_keys=[client_id], back_populates="orders")
    courier: Mapped["User | None"] = relationship(foreign_keys=[courier_id])
    address: Mapped["Address"] = relationship()
    items: Mapped[list["OrderItem"]] = relationship(
        back_populates="order", cascade="all, delete-orphan"
    )


class OrderItem(UUIDPK, Base):
    __tablename__ = "order_items"

    order_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("orders.id", ondelete="CASCADE"), index=True
    )
    product_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("products.id", ondelete="RESTRICT")
    )
    variant_label: Mapped[str] = mapped_column(String(40))
    qty: Mapped[int] = mapped_column(Integer, nullable=False)
    unit_price_minor: Mapped[int] = mapped_column(BigInteger, nullable=False)
    total_minor: Mapped[int] = mapped_column(BigInteger, nullable=False)

    order: Mapped[Order] = relationship(back_populates="items")
