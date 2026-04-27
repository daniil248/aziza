import enum
from datetime import datetime

from sqlalchemy import JSON, DateTime, Enum, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models._base import TimestampMixin, UUIDPK


class PushSegment(str, enum.Enum):
    all = "all"
    subscribers = "subscribers"
    inactive = "inactive"


class PushCampaign(UUIDPK, TimestampMixin, Base):
    __tablename__ = "push_campaigns"

    segment: Mapped[PushSegment] = mapped_column(Enum(PushSegment, name="push_segment"))
    title_i18n: Mapped[dict[str, str]] = mapped_column(JSON, default=dict, nullable=False)
    body_i18n: Mapped[dict[str, str]] = mapped_column(JSON, default=dict, nullable=False)
    scheduled_for: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    image_url: Mapped[str | None] = mapped_column(String(500))
