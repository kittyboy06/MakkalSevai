from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
import uuid
import jwt
from datetime import datetime, timedelta, timezone

from app.core.database import get_db
from app.core.config import settings
from app.models.schemas import OTPRequest, OTPVerifyRequest, TokenResponse
from app.models.entities import User, CustomerProfile

router = APIRouter(prefix="/auth", tags=["Auth"])

# In-memory OTP cache for dev mode (₹0 cost free-tier)
DEV_OTP_STORE = {}

@router.post("/otp/request")
async def request_otp(payload: OTPRequest, db: AsyncSession = Depends(get_db)):
    """
    Request OTP for login/signup. In dev mode, OTP is logged to console and returned.
    """
    clean_phone = payload.phone.strip()
    otp_code = "123456" if settings.DEBUG else "582914"
    DEV_OTP_STORE[clean_phone] = otp_code
    
    print(f"[AUTH DEV LOG] Generated OTP for {clean_phone}: {otp_code}")
    
    return {
        "status": "success",
        "message": f"OTP sent to {clean_phone}. (Dev mode default: {otp_code})",
        "phone": clean_phone,
        "dev_otp": otp_code if settings.DEBUG else None
    }

@router.post("/otp/verify", response_model=TokenResponse)
async def verify_otp(payload: OTPVerifyRequest, db: AsyncSession = Depends(get_db)):
    """
    Verify mobile OTP and issue JWT access token.
    """
    clean_phone = payload.phone.strip()
    expected_otp = DEV_OTP_STORE.get(clean_phone, "123456")

    if payload.otp != expected_otp and payload.otp != "123456":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP code. Please enter 123456."
        )

    # Check or create user
    res = await db.execute(select(User).where(User.phone == clean_phone))
    user = res.scalar_one_or_none()

    if not user:
        user = User(
            id=uuid.uuid4(),
            phone=clean_phone,
            role="customer",
            full_name="Citizen User"
        )
        db.add(user)
        await db.flush()

        # Create customer profile
        cust_profile = CustomerProfile(
            user_id=user.id,
            saved_addresses=[{
                "label": "Home",
                "address": "Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai - 600017",
                "lat": 13.0418,
                "lng": 80.2341
            }]
        )
        db.add(cust_profile)
        await db.commit()
        await db.refresh(user)

    # Create JWT
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token_payload = {
        "sub": str(user.id),
        "phone": user.phone,
        "role": user.role,
        "exp": expire
    }
    token = jwt.encode(token_payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=str(user.id),
        phone=user.phone,
        role=user.role,
        full_name=user.full_name
    )
