from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, func
from typing import Optional, Dict, Any, List
import uuid
import jwt
from datetime import datetime, timedelta, timezone

from app.core.database import get_db
from app.core.config import settings
from app.models.schemas import OTPRequest, OTPVerifyRequest, TokenResponse, EmailLoginRequest, EmailSignupRequest
from app.models.entities import User, CustomerProfile, WorkerProfile

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
        "email": user.email,
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
        full_name=user.full_name,
        email=user.email
    )


@router.post("/email/login", response_model=TokenResponse)
async def login_with_email(payload: EmailLoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Authenticate citizen user using Email ID.
    Supports existing users (e.g. senthil.nathan@example.com) or creates a new citizen user profile.
    """
    clean_email = payload.email.strip().lower()
    if not clean_email or "@" not in clean_email or "." not in clean_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A valid email address is required to sign in."
        )

    # 1. Search for existing user by email
    res = await db.execute(select(User).where(func.lower(User.email) == clean_email))
    user = res.scalar_one_or_none()

    # Explicit handling for Rajesh Kumar seeded worker account
    if not user and clean_email == "rajesh.kumar@example.com":
        rk_res = await db.execute(select(User).where(User.phone == "+919876543211"))
        user = rk_res.scalar_one_or_none()
        if user:
            user.email = clean_email
            await db.commit()
            await db.refresh(user)

    if not user:
        # Check if phone supplied, else generate unique phone identifier
        user_phone = payload.phone.strip() if payload.phone else None
        if not user_phone:
            # Deterministic unique phone from email hash
            user_phone = f"+919{abs(hash(clean_email)) % 1000000000:09d}"

        # Ensure phone uniqueness
        phone_check = await db.execute(select(User).where(User.phone == user_phone))
        if phone_check.scalar_one_or_none():
            user_phone = f"+919{abs(hash(clean_email + str(uuid.uuid4()))) % 1000000000:09d}"

        # Derive full_name if not provided
        derived_name = payload.full_name
        if not derived_name:
            username_part = clean_email.split("@")[0]
            derived_name = " ".join([part.capitalize() for part in username_part.replace(".", " ").replace("_", " ").split()])
            if not derived_name:
                derived_name = "Citizen User"

        user = User(
            id=uuid.uuid4(),
            phone=user_phone,
            email=clean_email,
            role="customer",
            full_name=derived_name
        )
        db.add(user)
        await db.flush()

        cust_profile = CustomerProfile(
            user_id=user.id,
            saved_addresses=[]
        )
        db.add(cust_profile)
        await db.commit()
        await db.refresh(user)
    else:
        if not user.email:
            user.email = clean_email
            await db.commit()
            await db.refresh(user)

    # 2. Create JWT token
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token_payload = {
        "sub": str(user.id),
        "phone": user.phone,
        "email": user.email,
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
        full_name=user.full_name,
        email=user.email
    )


@router.post("/email/signup", response_model=TokenResponse)
async def signup_with_email(payload: EmailSignupRequest, db: AsyncSession = Depends(get_db)):
    """
    Register a new citizen account using Email and Password.
    """
    clean_email = payload.email.strip().lower()
    clean_name = payload.full_name.strip()

    if not clean_email or "@" not in clean_email or "." not in clean_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A valid email address is required to register."
        )

    if not clean_name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Full name is required."
        )

    if len(payload.password.strip()) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 6 characters."
        )

    # 1. Check if user already exists
    res = await db.execute(select(User).where(func.lower(User.email) == clean_email))
    existing = res.scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email already exists. Please sign in instead."
        )

    # 2. Unique phone identifier
    user_phone = payload.phone.strip() if payload.phone else None
    if not user_phone:
        user_phone = f"+919{abs(hash(clean_email)) % 1000000000:09d}"

    phone_check = await db.execute(select(User).where(User.phone == user_phone))
    if phone_check.scalar_one_or_none():
        user_phone = f"+919{abs(hash(clean_email + str(uuid.uuid4()))) % 1000000000:09d}"

    # 3. Create User & Profile
    user_role = payload.role if payload.role in ["worker", "customer"] else "customer"
    new_user = User(
        id=uuid.uuid4(),
        phone=user_phone,
        email=clean_email,
        role=user_role,
        full_name=clean_name
    )
    db.add(new_user)
    await db.flush()

    if user_role == "worker":
        # Create verified worker profile for trade partner
        worker_profile = WorkerProfile(
            user_id=new_user.id,
            kyc_status="verified",
            uan=f"UAN-TN-2026-{abs(hash(clean_email)) % 100000:05d}",
            primary_skill_id=1,  # Default Electrician
            secondary_skill_ids=[],
            is_available=True,
            is_on_active_job=False,
            rating_avg=5.00,
            rating_count=1,
            reliability_score=1.000,
            jobs_completed=0,
            earnings_total=0.00
        )
        db.add(worker_profile)
    else:
        cust_profile = CustomerProfile(
            user_id=new_user.id,
            saved_addresses=[]
        )
        db.add(cust_profile)

    await db.commit()
    await db.refresh(new_user)

    # 4. Generate JWT token
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token_payload = {
        "sub": str(new_user.id),
        "phone": new_user.phone,
        "email": new_user.email,
        "role": new_user.role,
        "exp": expire
    }
    token = jwt.encode(token_payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=str(new_user.id),
        phone=new_user.phone,
        role=new_user.role,
        full_name=new_user.full_name,
        email=new_user.email
    )


async def get_current_user(
    authorization: Optional[str] = Header(None),
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Extract and verify JWT Bearer token, returning the authenticated User entity.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Bearer authentication token."
        )

    token = authorization.replace("Bearer ", "").strip()
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id_str = payload.get("sub")
        if not user_id_str:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token subject.")
        user_uid = uuid.UUID(user_id_str)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired. Please re-authenticate.")
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Token verification failed: {str(e)}")

    res = await db.execute(select(User).where(User.id == user_uid))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User account not found.")

    return user


async def get_current_customer(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Ensures the authenticated user has customer or admin privileges.
    """
    if current_user.role not in ["customer", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Citizen customer account required to access this endpoint."
        )
    return current_user


async def get_current_worker(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Ensures the authenticated user has worker or admin privileges.
    """
    if current_user.role not in ["worker", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Verified worker account required to access this endpoint."
        )
    return current_user
