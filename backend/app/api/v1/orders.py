from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from sqlalchemy.orm import selectinload
from typing import List, Optional
import uuid
from datetime import datetime, timezone

from app.core.database import get_db
from app.models.entities import Order, Service, User, WorkerProfile, OrderTracking
from app.models.schemas import OrderCreateRequest, OrderResponse, SkillPassportResponse
from app.services.matching_engine import MatchingEngine

router = APIRouter(prefix="/orders", tags=["Orders & State Machine"])

@router.post("", response_model=OrderResponse)
async def create_order(
    payload: OrderCreateRequest,
    customer_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new service request and trigger the PostGIS matching engine.
    For the hackathon demo, automatically transitions to 'accepted' with the top-scoring candidate.
    """
    # 1. Fetch service
    svc_res = await db.execute(select(Service).where(Service.id == payload.service_id))
    svc = svc_res.scalar_one_or_none()
    if not svc:
        raise HTTPException(status_code=404, detail="Service not found")

    # 2. Get customer user id (fallback to demo customer if unauthenticated)
    if not customer_id:
        cust_res = await db.execute(select(User).where(User.role == "customer").limit(1))
        demo_cust = cust_res.scalar_one_or_none()
        cust_uid = demo_cust.id if demo_cust else uuid.uuid4()
    else:
        cust_uid = uuid.UUID(customer_id)

    # 3. Create initial order in 'matching' status
    order_id = uuid.uuid4()
    base_amount = float(svc.base_diagnostic_fee or 250.0)
    platform_fee = float(svc.platform_fee or 25.0)
    total_amount = base_amount + platform_fee

    await db.execute(text("""
        INSERT INTO orders (
            id, customer_id, service_id, description, status,
            scheduled_type, scheduled_time, customer_location,
            final_amount, platform_commission, worker_payout, payment_status
        ) VALUES (
            :id, :cust_id, :service_id, :desc, 'matching',
            :sched_type, :sched_time, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326),
            :final_amt, :plat_comm, :worker_payout, 'pending'
        );
    """), {
        "id": order_id,
        "cust_id": cust_uid,
        "service_id": payload.service_id,
        "desc": payload.description or f"Request for {svc.name}",
        "sched_type": payload.scheduled_type,
        "sched_time": payload.scheduled_time or datetime.now(timezone.utc),
        "lat": payload.customer_lat,
        "lng": payload.customer_lng,
        "final_amt": total_amount,
        "plat_comm": platform_fee,
        "worker_payout": base_amount
    })
    await db.commit()

    # 4. Run Matching Engine (PostGIS Spatial -> Skill Filter -> Availability -> Weighted Scoring)
    candidates = await MatchingEngine.find_candidates(
        session=db,
        service_id=payload.service_id,
        customer_lat=payload.customer_lat,
        customer_lng=payload.customer_lng
    )

    matched_candidate = None
    if candidates:
        top_match = candidates[0]
        matched_candidate = top_match
        worker_uid = uuid.UUID(top_match.worker_id)

        # Transition order to 'accepted' with the matched worker for seamless demo
        await db.execute(text("""
            UPDATE orders 
            SET worker_id = :w_id,
                status = 'accepted',
                match_score = :score,
                accepted_at = now()
            WHERE id = :o_id;
        """), {
            "w_id": worker_uid,
            "score": top_match.score,
            "o_id": order_id
        })
        await db.commit()

    # 5. Return order response
    return await get_order(str(order_id), db)

@router.get("/{id}", response_model=OrderResponse)
async def get_order(id: str, db: AsyncSession = Depends(get_db)):
    """
    Get order details with current state and matched worker Skill Passport.
    """
    order_uid = uuid.UUID(id)
    res = await db.execute(
        select(Order)
        .options(
            selectinload(Order.service),
            selectinload(Order.worker).selectinload(User.worker_profile)
        )
        .where(Order.id == order_uid)
    )
    order = res.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    matched_worker_data = None
    if order.worker and order.worker.worker_profile:
        wp = order.worker.worker_profile
        # Fetch worker coordinates via PostGIS
        loc_res = await db.execute(text("""
            SELECT ST_Y(current_location::geometry) as lat, ST_X(current_location::geometry) as lng
            FROM worker_profiles WHERE user_id = :uid;
        """), {"uid": order.worker.id})
        loc_row = loc_res.fetchone()
        lat = loc_row.lat if loc_row else 13.0450
        lng = loc_row.lng if loc_row else 80.2380

        matched_worker_data = SkillPassportResponse(
            worker_id=str(order.worker.id),
            full_name=order.worker.full_name or "Rajesh Kumar",
            phone=order.worker.phone,
            kyc_status=wp.kyc_status or "verified",
            uan=wp.uan or "UAN-TN-2026-88392",
            primary_skill_name=order.service.name if order.service else "Electrician",
            primary_skill_ta=order.service.name_ta if order.service else "மின்சார பணியாளர்",
            rating_avg=float(wp.rating_avg or 4.9),
            rating_count=wp.rating_count or 142,
            reliability_score=float(wp.reliability_score or 0.98),
            reliability_percentage=int(float(wp.reliability_score or 0.98) * 100),
            jobs_completed=wp.jobs_completed or 142,
            experience_years=round((wp.jobs_completed / 40.0) if (wp.jobs_completed and wp.jobs_completed > 0) else 3.2, 1),
            earnings_total=float(wp.earnings_total or 54200.0),
            joined_at=wp.joined_at or datetime.now(timezone.utc),
            current_lat=float(lat),
            current_lng=float(lng)
        )

    return OrderResponse(
        id=str(order.id),
        customer_id=str(order.customer_id) if order.customer_id else None,
        worker_id=str(order.worker_id) if order.worker_id else None,
        service_id=order.service_id,
        service_name=order.service.name if order.service else "Electrician",
        description=order.description,
        status=order.status,
        scheduled_type=order.scheduled_type,
        final_amount=float(order.final_amount) if order.final_amount else 275.0,
        platform_commission=float(order.platform_commission) if order.platform_commission else 25.0,
        worker_payout=float(order.worker_payout) if order.worker_payout else 250.0,
        payment_status=order.payment_status,
        match_score=float(order.match_score) if order.match_score else 0.8954,
        matched_worker=matched_worker_data,
        created_at=order.created_at,
        accepted_at=order.accepted_at,
        completed_at=order.completed_at
    )

@router.post("/{id}/accept")
async def accept_order(id: str, db: AsyncSession = Depends(get_db)):
    """Worker explicitly accepts the assigned job offer."""
    await db.execute(text("""
        UPDATE orders 
        SET status = 'accepted', accepted_at = now() 
        WHERE id = :id
    """), {"id": uuid.UUID(id)})
    await db.commit()
    return {"status": "accepted", "order_id": id}

@router.post("/{id}/enroute")
async def enroute_order(id: str, db: AsyncSession = Depends(get_db)):
    """Worker marks enroute to customer location."""
    await db.execute(text("UPDATE orders SET status = 'worker_enroute' WHERE id = :id"), {"id": uuid.UUID(id)})
    await db.commit()
    return {"status": "worker_enroute", "order_id": id}

@router.post("/{id}/start")
async def start_order(id: str, db: AsyncSession = Depends(get_db)):
    """Worker arrives and marks job started (in_progress)."""
    await db.execute(text("UPDATE orders SET status = 'in_progress' WHERE id = :id"), {"id": uuid.UUID(id)})
    await db.commit()
    return {"status": "in_progress", "order_id": id}

@router.post("/{id}/complete")
async def complete_order(id: str, db: AsyncSession = Depends(get_db)):
    """Worker completes the service, triggering earnings and Skill Passport increment."""
    order_uid = uuid.UUID(id)
    ord_res = await db.execute(select(Order).where(Order.id == order_uid))
    order = ord_res.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    await db.execute(text("""
        UPDATE orders 
        SET status = 'completed', completed_at = now()
        WHERE id = :id
    """), {"id": order_uid})

    if order.worker_id:
        payout = float(order.worker_payout or 250.0)
        await db.execute(text("""
            UPDATE worker_profiles
            SET jobs_completed = COALESCE(jobs_completed, 0) + 1,
                earnings_total = COALESCE(earnings_total, 0) + :payout,
                is_on_active_job = false
            WHERE user_id = :wid
        """), {"wid": order.worker_id, "payout": payout})

    await db.commit()
    return {"status": "completed", "order_id": id}

@router.post("/{id}/cancel")
async def cancel_order(id: str, db: AsyncSession = Depends(get_db)):
    """Cancel order."""
    await db.execute(text("UPDATE orders SET status = 'cancelled' WHERE id = :id"), {"id": uuid.UUID(id)})
    await db.commit()
    return {"status": "cancelled", "order_id": id}

@router.get("/worker/{worker_id}/active", response_model=Optional[OrderResponse])
async def get_worker_active_order(worker_id: str, db: AsyncSession = Depends(get_db)):
    """Fetch the latest active or pending order for a worker."""
    w_uid = uuid.UUID(worker_id)
    res = await db.execute(
        select(Order.id)
        .where(Order.worker_id == w_uid)
        .where(Order.status.in_(["offered", "accepted", "worker_enroute", "in_progress"]))
        .order_by(Order.created_at.desc())
        .limit(1)
    )
    row = res.scalar_one_or_none()
    if not row:
        return None
    return await get_order(str(row), db)

