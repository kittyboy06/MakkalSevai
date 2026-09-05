from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, func
from sqlalchemy.orm import selectinload
from typing import List, Optional
import uuid
from datetime import datetime, timezone, timedelta

from app.core.database import get_db
from app.models.entities import User, WorkerProfile, Service, Order, Rating, WorkerTransaction
from app.models.schemas import (
    SkillPassportResponse,
    WorkerJobResponse,
    WorkerWalletResponse,
    WorkerTransactionItem,
    WorkerBankAccount,
    WorkerPayoutRequest,
    WorkerLocationUpdate,
)
from app.api.v1.auth import get_current_worker

router = APIRouter(prefix="/workers", tags=["Workers & Skill Passport"])

async def ensure_worker_tables_and_seed(db: AsyncSession, worker_id: uuid.UUID, worker_name: str = "Rajesh Kumar"):
    """
    Ensure the worker_transactions table exists and seed initial realistic ledger/order
    data for Rajesh Kumar if not already populated.
    """
    # 1. Create table if not exists
    await db.execute(text("""
        CREATE TABLE IF NOT EXISTS worker_transactions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            worker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
            type VARCHAR(30) NOT NULL,
            amount NUMERIC(10, 2) NOT NULL,
            status VARCHAR(20) DEFAULT 'completed',
            reference VARCHAR(100),
            description TEXT,
            created_at TIMESTAMPTZ DEFAULT now()
        )
    """))
    await db.execute(text("""
        CREATE INDEX IF NOT EXISTS idx_worker_transactions_worker_id ON worker_transactions(worker_id)
    """))
    await db.commit()

    # 2. Check if worker has any transactions
    tx_res = await db.execute(select(func.count(WorkerTransaction.id)).where(WorkerTransaction.worker_id == worker_id))
    tx_count = tx_res.scalar() or 0

    if tx_count == 0:
        now = datetime.now(timezone.utc)
        initial_transactions = [
            ("JOB_PAYOUT", 300.00, "completed", "TXN-ORD-TN-771", "Ceiling Fan Installation & Wiring (T. Nagar)", now - timedelta(hours=6)),
            ("JOB_PAYOUT", 350.00, "completed", "TXN-ORD-TN-772", "MCB Main Switch Trip & Breaker Fix (T. Nagar)", now - timedelta(hours=4)),
            ("JOB_PAYOUT", 350.00, "completed", "TXN-ORD-TN-773", "Living Room Rewiring Inspection (Alwarpet)", now - timedelta(hours=2)),
            ("JOB_PAYOUT", 250.00, "completed", "TXN-ORD-TN-774", "Kitchen Power Socket & Earthing (T. Nagar)", now - timedelta(minutes=45)),
            ("JOB_PAYOUT", 1200.00, "completed", "TXN-ORD-TN-750", "Weekly Cumulative Settlements (Batch #41)", now - timedelta(days=2)),
            ("BANK_TRANSFER", 1000.00, "completed", "IMPS-TN-9821034", "Instant Bank Transfer to State Bank of India •••• 4892", now - timedelta(days=1)),
        ]
        for tx_type, amount, tx_status, ref, desc, dt in initial_transactions:
            await db.execute(text("""
                INSERT INTO worker_transactions (id, worker_id, type, amount, status, reference, description, created_at)
                VALUES (:id, :w_id, :type, :amt, :status, :ref, :desc, :dt)
            """), {
                "id": uuid.uuid4(),
                "w_id": worker_id,
                "type": tx_type,
                "amt": amount,
                "status": tx_status,
                "ref": ref,
                "desc": desc,
                "dt": dt
            })
        await db.commit()

    # 3. Check if worker has any orders in orders table
    ord_res = await db.execute(select(func.count(Order.id)).where(Order.worker_id == worker_id))
    ord_count = ord_res.scalar() or 0

    if ord_count == 0:
        # Fetch or create a customer
        cust_res = await db.execute(select(User).where(User.role == "customer").limit(1))
        cust = cust_res.scalar_one_or_none()
        cust_id = cust.id if cust else uuid.uuid4()
        now = datetime.now(timezone.utc)

        seed_orders = [
            ("Kitchen Power Socket Replacement", 1, 275.0, 250.0, 25.0, "completed", 5, "Excellent work! Replaced the faulty socket quickly and checked grounding.", now - timedelta(minutes=45)),
            ("Living Room Rewiring Inspection", 1, 385.0, 350.0, 35.0, "completed", 5, "Very polite and professional. Found the neutral leak in 10 minutes.", now - timedelta(hours=2)),
            ("MCB Main Switch Trip Fix", 1, 385.0, 350.0, 35.0, "completed", 5, "Arrived in 8 minutes. Replaced the melted 32A MCB switch safely.", now - timedelta(hours=4)),
            ("Ceiling Fan Installation", 1, 330.0, 300.0, 30.0, "completed", 4, "Good installation with safety hook. Clean work.", now - timedelta(hours=6)),
        ]

        for desc, svc_id, final_amt, payout, comm, ord_status, stars, review, dt in seed_orders:
            o_id = uuid.uuid4()
            await db.execute(text("""
                INSERT INTO orders (
                    id, customer_id, worker_id, service_id, description, status,
                    scheduled_type, scheduled_time, customer_location,
                    final_amount, platform_commission, worker_payout, payment_status,
                    created_at, accepted_at, completed_at
                ) VALUES (
                    :id, :c_id, :w_id, :s_id, :desc, :status,
                    'immediate', :dt, ST_SetSRID(ST_MakePoint(80.2341, 13.0418), 4326),
                    :final_amt, :comm, :payout, 'paid',
                    :dt, :dt, :dt
                )
            """), {
                "id": o_id,
                "c_id": cust_id,
                "w_id": worker_id,
                "s_id": svc_id,
                "desc": desc,
                "status": ord_status,
                "final_amt": final_amt,
                "comm": comm,
                "payout": payout,
                "dt": dt
            })
            # Insert rating
            await db.execute(text("""
                INSERT INTO ratings (order_id, customer_id, worker_id, stars, review_text, created_at)
                VALUES (:o_id, :c_id, :w_id, :stars, :review, :dt)
            """), {
                "o_id": o_id,
                "c_id": cust_id,
                "w_id": worker_id,
                "stars": stars,
                "review": review,
                "dt": dt
            })
        await db.commit()


@router.get("/me/jobs", response_model=List[WorkerJobResponse])
async def get_my_jobs(
    current_worker: User = Depends(get_current_worker),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all active and completed jobs assigned to the authenticated worker.
    """
    await ensure_worker_tables_and_seed(db, current_worker.id, current_worker.full_name or "Rajesh Kumar")

    res = await db.execute(
        select(Order)
        .options(
            selectinload(Order.service),
            selectinload(Order.customer),
            selectinload(Order.rating)
        )
        .where(Order.worker_id == current_worker.id)
        .order_by(Order.created_at.desc())
    )
    orders = res.scalars().all()

    items: List[WorkerJobResponse] = []
    for o in orders:
        c_name = o.customer.full_name if o.customer else "Citizen Customer"
        c_phone = o.customer.phone if o.customer else "+919876543210"
        s_name = o.service.name if o.service else "Electrician"
        s_name_ta = o.service.name_ta if o.service else "மின்சார பணியாளர்"
        rating_stars = o.rating.stars if o.rating else None
        review = o.rating.review_text if o.rating else None

        items.append(WorkerJobResponse(
            id=str(o.id),
            service_id=o.service_id,
            service_name=s_name,
            service_name_ta=s_name_ta,
            customer_name=c_name,
            customer_phone=c_phone,
            address_text="Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai - 600017",
            customer_lat=13.0418,
            customer_lng=80.2341,
            description=o.description,
            status=o.status,
            scheduled_type=o.scheduled_type or "immediate",
            final_amount=float(o.final_amount or 275.0),
            worker_payout=float(o.worker_payout or 250.0),
            payment_status=o.payment_status or "paid",
            rating=rating_stars,
            review_text=review,
            created_at=o.created_at,
            accepted_at=o.accepted_at,
            completed_at=o.completed_at
        ))

    return items


@router.get("/me/wallet", response_model=WorkerWalletResponse)
async def get_my_wallet(
    current_worker: User = Depends(get_current_worker),
    db: AsyncSession = Depends(get_db)
):
    """
    Get live wallet metrics and transaction ledger for the authenticated worker.
    """
    await ensure_worker_tables_and_seed(db, current_worker.id, current_worker.full_name or "Rajesh Kumar")

    # Fetch all transactions
    tx_res = await db.execute(
        select(WorkerTransaction)
        .where(WorkerTransaction.worker_id == current_worker.id)
        .order_by(WorkerTransaction.created_at.desc())
    )
    transactions = tx_res.scalars().all()

    # Calculate balances from ledger
    total_payouts = sum(float(t.amount) for t in transactions if t.type == "JOB_PAYOUT" and t.status == "completed")
    total_transfers = sum(float(t.amount) for t in transactions if t.type == "BANK_TRANSFER" and t.status == "completed")
    available_balance = max(0.0, total_payouts - total_transfers)

    # Calculate today's earnings
    now = datetime.now(timezone.utc)
    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_earnings = sum(
        float(t.amount) for t in transactions 
        if t.type == "JOB_PAYOUT" and t.status == "completed" and t.created_at >= start_of_day
    )

    # Calculate weekly earnings
    start_of_week = now - timedelta(days=7)
    weekly_earnings = sum(
        float(t.amount) for t in transactions 
        if t.type == "JOB_PAYOUT" and t.status == "completed" and t.created_at >= start_of_week
    )

    # Worker profile total
    wp_res = await db.execute(select(WorkerProfile).where(WorkerProfile.user_id == current_worker.id))
    wp = wp_res.scalar_one_or_none()
    total_life = float(wp.earnings_total or (total_payouts + 50000.0)) if wp else total_payouts

    # Welfare Board 1% contribution calculation (Prototype W-D13)
    welfare_cess = round(total_life * 0.01, 2)

    tx_items = [
        WorkerTransactionItem(
            id=str(t.id),
            type=t.type,
            amount=float(t.amount),
            status=t.status,
            reference=t.reference,
            description=t.description,
            created_at=t.created_at
        )
        for t in transactions
    ]

    bank = WorkerBankAccount(
        bank_name="State Bank of India",
        account_number_masked="•••• •••• 4892",
        ifsc="SBIN0000800",
        account_holder=current_worker.full_name or "Rajesh Kumar",
        status_label="Demo Linked Account"
    )

    return WorkerWalletResponse(
        worker_id=str(current_worker.id),
        available_balance=available_balance,
        today_earnings=today_earnings,
        this_week_earnings=weekly_earnings,
        total_life_earnings=total_life,
        welfare_cess_total=welfare_cess,
        payout_bank=bank,
        transactions=tx_items
    )


@router.post("/me/wallet/payout", response_model=WorkerWalletResponse)
async def request_my_payout(
    payload: WorkerPayoutRequest,
    current_worker: User = Depends(get_current_worker),
    db: AsyncSession = Depends(get_db)
):
    """
    Request instant bank transfer from available wallet balance (test/demo mode).
    """
    await ensure_worker_tables_and_seed(db, current_worker.id, current_worker.full_name or "Rajesh Kumar")

    # Check available balance
    tx_res = await db.execute(
        select(WorkerTransaction)
        .where(WorkerTransaction.worker_id == current_worker.id)
    )
    transactions = tx_res.scalars().all()
    total_payouts = sum(float(t.amount) for t in transactions if t.type == "JOB_PAYOUT" and t.status == "completed")
    total_transfers = sum(float(t.amount) for t in transactions if t.type == "BANK_TRANSFER" and t.status == "completed")
    available_balance = max(0.0, total_payouts - total_transfers)

    if payload.amount > available_balance:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Requested amount ₹{payload.amount:.2f} exceeds available balance ₹{available_balance:.2f}"
        )

    # Insert BANK_TRANSFER transaction
    ref = f"IMPS-TN-{int(datetime.now(timezone.utc).timestamp() * 1000)}"
    new_tx = WorkerTransaction(
        id=uuid.uuid4(),
        worker_id=current_worker.id,
        type="BANK_TRANSFER",
        amount=payload.amount,
        status="completed",
        reference=ref,
        description="Instant Settlement to State Bank of India •••• 4892 (Demo)"
    )
    db.add(new_tx)
    await db.commit()

    return await get_my_wallet(current_worker, db)


@router.get("/me/passport", response_model=SkillPassportResponse)
async def get_my_passport(
    current_worker: User = Depends(get_current_worker),
    db: AsyncSession = Depends(get_db)
):
    """
    Get live Digital Skill Passport for the authenticated worker.
    """
    return await get_worker_passport(str(current_worker.id), db)


@router.post("/me/location")
async def update_my_location(
    payload: WorkerLocationUpdate,
    current_worker: User = Depends(get_current_worker),
    db: AsyncSession = Depends(get_db)
):
    """
    Update worker's live GPS coordinates in PostGIS (Decision W-D12).
    """
    await db.execute(text("""
        UPDATE worker_profiles 
        SET current_location = ST_SetSRID(ST_MakePoint(:lng, :lat), 4326),
            last_location_update = now()
        WHERE user_id = :uid;
    """), {"uid": current_worker.id, "lat": payload.lat, "lng": payload.lng})
    await db.commit()
    return {"status": "ok", "lat": payload.lat, "lng": payload.lng}


@router.post("/me/availability")
async def toggle_my_availability(
    is_available: bool = True,
    current_worker: User = Depends(get_current_worker),
    db: AsyncSession = Depends(get_db)
):
    """
    Toggle online/offline dispatch availability for the authenticated worker.
    """
    await db.execute(text("""
        UPDATE worker_profiles 
        SET is_available = :avail
        WHERE user_id = :uid
    """), {"avail": is_available, "uid": current_worker.id})
    await db.commit()
    return {"status": "ok", "worker_id": str(current_worker.id), "is_available": is_available}


# Backwards compatibility endpoints
@router.get("/{id}/passport", response_model=SkillPassportResponse)
async def get_worker_passport(id: str, db: AsyncSession = Depends(get_db)):
    """
    Get live Digital Skill Passport data for a worker by ID.
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
        secondary_skills=["AC Repair", "Inverter Servicing"],
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
    """Toggle worker availability for dispatch matching by ID."""
    w_uid = uuid.UUID(id)
    await db.execute(text("""
        UPDATE worker_profiles 
        SET is_available = :avail
        WHERE user_id = :uid
    """), {"avail": is_available, "uid": w_uid})
    await db.commit()
    return {"status": "ok", "worker_id": id, "is_available": is_available}

