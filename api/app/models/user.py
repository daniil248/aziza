import enum
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Enum, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models._base import TimestampMixin, UUIDPK

if TYPE_CHECKING:
    from app.models.order import Order
    from app.models.subscription import Subscription


class UserRole(str, enum.Enum):
    client = "client"
    courier = "courier"
    admin = "admin"


class AddressLabel(str, enum.Enum):
    home = "home"
    work = "work"
    custom = "custom"


class User(UUIDPK, TimestampMixin, Base):
    __tablename__ = "users"

    phone: Mapped[str | None] = mapped_column(String(32), unique=True, index=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str | None] = mapped_column(String(120))
    avatar_url: Mapped[str | None] = mapped_column(String(500))
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role"), default=UserRole.client, nullable=False
    )
    locale: Mapped[str] = mapped_column(String(8), default="ru", nullable=False)
    password_hash: Mapped[str | None] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    addresses: Mapped[list["Address"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    orders: Mapped[list["Order"]] = relationship(
        back_populates="client", foreign_keys="Order.client_id"
    )
    subscription: Mapped["Subscription | None"] = relationship(
        back_populates="user", uselist=False
    )


class Address(UUIDPK, TimestampMixin, Base):
    __tablename__ = "addresses"

    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    label: Mapped[AddressLabel] = mapped_column(
        Enum(AddressLabel, name="address_label"), default=AddressLabel.home
    )
    street: Mapped[str] = mapped_column(String(200))
    building: Mapped[str | None] = mapped_column(String(40))
    apt: Mapped[str | None] = mapped_column(String(40))
    entrance: Mapped[str | None] = mapped_column(String(20))
    floor: Mapped[str | None] = mapped_column(String(20))
    comment: Mapped[str | None] = mapped_column(String(500))
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    user: Mapped[User] = relationship(back_populates="addresses")
