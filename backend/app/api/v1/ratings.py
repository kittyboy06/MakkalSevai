from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
import uuid

from app.core.database import get_db
from app.models.entities import Order, Rating, WorkerProfile
from app.models.schemas import RatingCreateRequest, RatingResponse

router = APIRouter(prefix="/orders", tags=["Ratings & Reviews"])

@router.post("/{id}/rate", response_model=RatingResponse)
async def submit_rating(
    id: str,
    payload: RatingCreateRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Submit customer rating for a completed order.
    Dynamically recalculates worker rating_avg, rating_count, jobs_completed, and reliability score.
    """
    order_uid = uuid.UUID(id)
    res = await db.execute(select(Order).where(Order.id == order_uid))
    order = res.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # Insert Rating
    rating_res = await db.execute(text("""
        INSERT INTO ratings (order_id, customer_id, worker_id, stars, review_text)
        VALUES (:o_id, :c_id, :w_id, :stars, :review)
        ON CONFLICT (order_id) DO UPDATE SET stars = EXCLUDED.stars, review_text = EXCLUDED.review_text
        RETURNING id, created_at;
    """), {
        "o_id": order_uid,
        "c_id": order.customer_id,
        "w_id": order.worker_id,
        "stars": payload.stars,
        "review": payload.review_text or "Great on-time service"
    })
    rating_row = rating_res.fetchone()

    # Recalculate Worker Skill Passport Metrics
    if order.worker_id:
        await db.execute(text("""
            WITH stats AS (
                SELECT 
                    ROUND(AVG(stars), 2) as new_avg,
                    COUNT(id) as new_cnt
                FROM ratings
                WHERE worker_id = :w_id
            )
            UPDATE worker_profiles
            SET 
                rating_avg = stats.new_avg,
                rating_count = stats.new_cnt,
                jobs_completed = jobs_completed + 1,
                reliability_score = LEAST(1.000, reliability_score + 0.002)
            FROM stats
            WHERE worker_profiles.user_id = :w_id;
        """), {"w_id": order.worker_id})

    await db.commit()

    return RatingResponse(
        id=rating_row.id,
        order_id=str(order.id),
        stars=payload.stars,
        review_text=payload.review_text,
        created_at=rating_row.created_at
    )
