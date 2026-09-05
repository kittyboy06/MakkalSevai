from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, func
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import uuid

from app.core.database import get_db
from app.models.entities import User, CustomerProfile, Order
from app.api.v1.auth import get_current_customer

router = APIRouter(prefix="/customers", tags=["Customer Citizen Account"])

class AddressItem(BaseModel):
    label: str = "Home"
    address: str
    lat: float
    lng: float
    is_default: Optional[bool] = False

class AddressCreateRequest(BaseModel):
    label: str = Field(default="Saved Address", example="Home")
    address: str = Field(..., example="Flat 4B, Shanti Nilayam, T. Nagar, Chennai")
    lat: float = Field(..., example=13.0418)
    lng: float = Field(..., example=80.2341)
    is_default: bool = False

class CustomerStats(BaseModel):
    total_bookings: int
    completed_bookings: int
    active_bookings: int
    total_spent: float

class CustomerProfileResponse(BaseModel):
    id: str
    phone: str
    full_name: str
    email: Optional[str] = None
    role: str
    saved_addresses: List[Dict[str, Any]] = []
    stats: CustomerStats


@router.get("/me/profile", response_model=CustomerProfileResponse)
async def get_my_customer_profile(
    current_customer: User = Depends(get_current_customer),
    db: AsyncSession = Depends(get_db)
):
    """
    Fetch profile, saved addresses, and live platform statistics for the authenticated customer.
    """
    # 1. Fetch or initialize customer_profile
    res = await db.execute(
        select(CustomerProfile).where(CustomerProfile.user_id == current_customer.id)
    )
    profile = res.scalar_one_or_none()

    saved_addresses = []
    if profile and profile.saved_addresses:
        saved_addresses = profile.saved_addresses
    elif not profile:
        # Create profile record if missing
        profile = CustomerProfile(user_id=current_customer.id, saved_addresses=[])
        db.add(profile)
        await db.commit()

    # 2. Compute live aggregate statistics from orders table
    stats_res = await db.execute(text("""
        SELECT 
            COUNT(id) as total_count,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count,
            COUNT(CASE WHEN status IN ('matching', 'offered', 'accepted', 'worker_enroute', 'in_progress') THEN 1 END) as active_count,
            COALESCE(SUM(CASE WHEN status = 'completed' THEN final_amount ELSE 0 END), 0) as total_spent
        FROM orders
        WHERE customer_id = :cid;
    """), {"cid": current_customer.id})
    stats_row = stats_res.fetchone()

    stats = CustomerStats(
        total_bookings=int(stats_row.total_count or 0),
        completed_bookings=int(stats_row.completed_count or 0),
        active_bookings=int(stats_row.active_count or 0),
        total_spent=float(stats_row.total_spent or 0.0)
    )

    return CustomerProfileResponse(
        id=str(current_customer.id),
        phone=current_customer.phone,
        full_name=current_customer.full_name or "Citizen User",
        email=current_customer.email,
        role=current_customer.role,
        saved_addresses=saved_addresses,
        stats=stats
    )


@router.post("/me/addresses", response_model=CustomerProfileResponse)
async def add_saved_address(
    payload: AddressCreateRequest,
    current_customer: User = Depends(get_current_customer),
    db: AsyncSession = Depends(get_db)
):
    """
    Save the customer's current GPS location or address to their database profile.
    """
    res = await db.execute(
        select(CustomerProfile).where(CustomerProfile.user_id == current_customer.id)
    )
    profile = res.scalar_one_or_none()

    new_address = {
        "label": payload.label,
        "address": payload.address,
        "lat": payload.lat,
        "lng": payload.lng,
        "is_default": payload.is_default
    }

    if not profile:
        profile = CustomerProfile(
            user_id=current_customer.id,
            saved_addresses=[new_address]
        )
        db.add(profile)
    else:
        existing = list(profile.saved_addresses or [])
        # Prevent exact duplicate lat/lng within 2 decimal places
        existing = [a for a in existing if not (abs(a.get("lat", 0) - payload.lat) < 0.0005 and abs(a.get("lng", 0) - payload.lng) < 0.0005)]
        existing.append(new_address)
        profile.saved_addresses = existing

    # Update PostGIS default_location if default
    if payload.is_default:
        await db.execute(text("""
            UPDATE customer_profiles
            SET default_location = ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)
            WHERE user_id = :uid;
        """), {"uid": current_customer.id, "lat": payload.lat, "lng": payload.lng})

    await db.commit()
    await db.refresh(profile)

    return await get_my_customer_profile(current_customer=current_customer, db=db)
