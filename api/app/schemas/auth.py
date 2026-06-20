import uuid

from pydantic import BaseModel, Field

from app.models.user import AddressLabel, UserRole
from app.schemas.common import ORMBase


class UserRead(ORMBase):
    id: uuid.UUID
    phone: str | None = None
    email: str | None = None
    name: str | None = None
    avatar_url: str | None = None
    role: UserRole
    locale: str
    is_active: bool


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserRead


class RegisterIn(BaseModel):
    phone: str = Field(min_length=4, max_length=32)
    password: str = Field(min_length=6, max_length=128)
    name: str | None = Field(default=None, max_length=120)


class LoginIn(BaseModel):
    phone: str = Field(min_length=4, max_length=32)
    password: str = Field(min_length=1, max_length=128)


class RefreshIn(BaseModel):
    refresh_token: str


class ProfileUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=120)
    email: str | None = Field(default=None, max_length=255)
    locale: str | None = Field(default=None, max_length=8)


class AddressRead(ORMBase):
    id: uuid.UUID
    label: AddressLabel
    street: str
    building: str | None = None
    apt: str | None = None
    entrance: str | None = None
    floor: str | None = None
    comment: str | None = None
    lat: float
    lng: float
    is_default: bool


class AddressWrite(BaseModel):
    """Create payload — all delivery fields. label/coords required to place orders."""

    label: AddressLabel = AddressLabel.home
    street: str = Field(min_length=1, max_length=200)
    building: str | None = Field(default=None, max_length=40)
    apt: str | None = Field(default=None, max_length=40)
    entrance: str | None = Field(default=None, max_length=20)
    floor: str | None = Field(default=None, max_length=20)
    comment: str | None = Field(default=None, max_length=500)
    lat: float = 0.0
    lng: float = 0.0
    is_default: bool = False


class AddressUpdate(BaseModel):
    """Partial update — only set fields are applied."""

    label: AddressLabel | None = None
    street: str | None = Field(default=None, max_length=200)
    building: str | None = Field(default=None, max_length=40)
    apt: str | None = Field(default=None, max_length=40)
    entrance: str | None = Field(default=None, max_length=20)
    floor: str | None = Field(default=None, max_length=20)
    comment: str | None = Field(default=None, max_length=500)
    lat: float | None = None
    lng: float | None = None
    is_default: bool | None = None
