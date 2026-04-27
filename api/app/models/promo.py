import enum
from datetime import datetime

from sqlalchemy import BigInteger, Boolean, DateTime, Enum, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models._base import TimestampMixin, UUIDPK


class PromoType(str, enum.Enum):
    percent = "percent"
    amount = "amount"
    free_delivery = "free_delivery"


class Promo(UUIDPK, TimestampMixin, Base):
    __tablename__ = "promos"

    code: Mapped[str] = mapped_column(String(40), unique=True, index=True)
    type: Mapped[PromoType] = mapped_column(Enum(PromoType, name="promo_type"))
    value: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    min_order_minor: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    valid_from: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    valid_to: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    max_uses: Mapped[int | None] = mapped_column(Integer)
    uses_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
