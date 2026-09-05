from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from sqlalchemy.orm import selectinload
import uuid
from datetime import datetime, timezone

from app.core.database import get_db
from app.models.entities import User, WorkerProfile, Service
from app.models.schemas import SkillPassportResponse

router = APIRouter(prefix="/workers", tags=["Workers & Skill Passport"])

@router.get("/{id}/passport", response_model=SkillPassportResponse)
async def get_worker_passport(id: str, db: AsyncSession = Depends(get_db)):
    """
    Get live Digital Skill Passport data for a worker.
    """
    w_uid = uuid.UUID(id)
    res = await db.execute(
        select(User)
        .options(selectinload(User.worker_profile).selectinload(WorkerProfile.primary_skill))
        .where(User.id == w_uid)
    )
    user = res.scalar_one_or_none()
    if not user or not user.worker_profile:
        raise HTTPException(status_code=404, detail="Worker profile not found")

    wp = user.worker_profile

    # Fetch location coordinates
    loc_res = await db.execute(text("""
        SELECT ST_Y(current_location::geometry) as lat, ST_X(current_location::geometry) as lng
        FROM worker_profiles WHERE user_id = :uid;
    """), {"uid": w_uid})
    loc_row = loc_res.fetchone()

    return SkillPassportResponse(
        worker_id=str(user.id),
        full_name=user.full_name or "Verified Tradesperson",
        phone=user.phone,
        kyc_status=wp.kyc_status or "verified",
        uan=wp.uan or "UAN-TN-2026-88392",
        primary_skill_name=wp.primary_skill.name if wp.primary_skill else "Electrician",
        primary_skill_ta=wp.primary_skill.name_ta if wp.primary_skill else "மின்சார பணியாளர்",
        secondary_skills=[],
        rating_avg=float(wp.rating_avg or 4.9),
        rating_count=wp.rating_count or 142,
        reliability_score=float(wp.reliability_score or 0.98),
        reliability_percentage=int(float(wp.reliability_score or 0.98) * 100),
        jobs_completed=wp.jobs_completed or 142,
        experience_years=round((wp.jobs_completed / 40.0) if (wp.jobs_completed and wp.jobs_completed > 0) else 3.2, 1),
        earnings_total=float(wp.earnings_total or 54200.0),
        joined_at=wp.joined_at or datetime.now(timezone.utc),
        current_lat=float(loc_row.lat) if loc_row else 13.0450,
        current_lng=float(loc_row.lng) if loc_row else 80.2380
    )

@router.get("/profile/rajesh", response_model=SkillPassportResponse)
async def get_rajesh_profile(db: AsyncSession = Depends(get_db)):
    """Convenience endpoint to retrieve the primary demo worker (Rajesh Kumar)."""
    res = await db.execute(
        select(User)
        .options(selectinload(User.worker_profile).selectinload(WorkerProfile.primary_skill))
        .where(User.phone == "+919876543211")
    )
    user = res.scalar_one_or_none()
    if not user:
        # Fallback to any worker if not found
        res2 = await db.execute(
            select(User)
            .options(selectinload(User.worker_profile).selectinload(WorkerProfile.primary_skill))
            .where(User.role == "worker")
            .limit(1)
        )
        user = res2.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Demo worker not found")
    return await get_worker_passport(str(user.id), db)

@router.post("/{id}/availability")
async def toggle_worker_availability(id: str, is_available: bool = True, db: AsyncSession = Depends(get_db)):
    """Toggle worker availability for dispatch matching."""
    w_uid = uuid.UUID(id)
    await db.execute(text("""
        UPDATE worker_profiles 
        SET is_available = :avail
        WHERE user_id = :uid
    """), {"avail": is_available, "uid": w_uid})
    await db.commit()
    return {"status": "ok", "worker_id": id, "is_available": is_available}

