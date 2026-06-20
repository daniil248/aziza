"""Auth + profile + delivery-address endpoints for client users."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import Address, User, UserRole
from app.schemas.auth import (
    AddressRead,
    AddressUpdate,
    AddressWrite,
    LoginIn,
    ProfileUpdate,
    RefreshIn,
    RegisterIn,
    Token,
    UserRead,
)

router = APIRouter()


def _normalize_phone(phone: str) -> str:
    """Reduce a phone to its digits only (drops +, spaces, dashes, parens)."""
    return "".join(ch for ch in phone if ch.isdigit())


def _issue_tokens(user: User) -> Token:
    return Token(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
        token_type="bearer",
        user=UserRead.model_validate(user),
    )


@router.post("/register", response_model=Token, status_code=201)
async def register(payload: RegisterIn, db: AsyncSession = Depends(get_db)) -> Token:
    phone = _normalize_phone(payload.phone)
    if not phone:
        raise HTTPException(status_code=422, detail="invalid phone")

    existing = await db.execute(select(User).where(User.phone == phone))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="phone already registered")

    user = User(
        phone=phone,
        name=payload.name,
        role=UserRole.client,
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)
    return _issue_tokens(user)


@router.post("/login", response_model=Token)
async def login(payload: LoginIn, db: AsyncSession = Depends(get_db)) -> Token:
    phone = _normalize_phone(payload.phone)
    res = await db.execute(select(User).where(User.phone == phone))
    user = res.scalar_one_or_none()
    # Generic 401 — don't leak whether the phone exists.
    if not user or not user.is_active or not user.password_hash:
        raise HTTPException(status_code=401, detail="invalid credentials")
    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="invalid credentials")
    return _issue_tokens(user)


@router.post("/refresh", response_model=Token)
async def refresh(payload: RefreshIn, db: AsyncSession = Depends(get_db)) -> Token:
    decoded = decode_token(payload.refresh_token)
    if not decoded or decoded.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="invalid refresh token")
    res = await db.execute(select(User).where(User.id == decoded.get("sub")))
    user = res.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="invalid refresh token")
    return _issue_tokens(user)


@router.get("/me", response_model=UserRead)
async def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.patch("/me", response_model=UserRead)
async def update_me(
    payload: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(current_user, field, value)
    await db.flush()
    await db.refresh(current_user)
    return current_user


# --- Delivery addresses (own resources only) ---


@router.get("/me/addresses", response_model=list[AddressRead])
async def list_addresses(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[Address]:
    res = await db.execute(
        select(Address).where(Address.user_id == current_user.id).order_by(Address.created_at)
    )
    return list(res.scalars().all())


@router.post("/me/addresses", response_model=AddressRead, status_code=201)
async def create_address(
    payload: AddressWrite,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Address:
    address = Address(user_id=current_user.id, **payload.model_dump())
    db.add(address)
    await db.flush()
    await db.refresh(address)
    return address


async def _own_address(address_id: str, user: User, db: AsyncSession) -> Address:
    res = await db.execute(
        select(Address).where(Address.id == address_id, Address.user_id == user.id)
    )
    address = res.scalar_one_or_none()
    if not address:
        raise HTTPException(status_code=404, detail="address not found")
    return address


@router.patch("/me/addresses/{address_id}", response_model=AddressRead)
async def update_address(
    address_id: str,
    payload: AddressUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Address:
    address = await _own_address(address_id, current_user, db)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(address, field, value)
    await db.flush()
    await db.refresh(address)
    return address


@router.delete("/me/addresses/{address_id}", status_code=204)
async def delete_address(
    address_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    address = await _own_address(address_id, current_user, db)
    await db.delete(address)
