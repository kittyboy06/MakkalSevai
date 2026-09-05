from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
import uuid
import secrets

from app.core.database import get_db
from app.models.entities import Order

router = APIRouter(prefix="/payments", tags=["Payments (Razorpay Test Mode)"])

@router.post("/orders/{order_id}/create-payment")
async def create_razorpay_order(order_id: str, db: AsyncSession = Depends(get_db)):
    """
    Simulate Razorpay Test Mode Order creation for prototype sandbox.
    Computes transparent split: platform_commission vs worker_payout.
    """
    o_uid = uuid.UUID(order_id)
    res = await db.execute(select(Order).where(Order.id == o_uid))
    order = res.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    amount = float(order.final_amount or 275.0)
    rzp_order_id = f"order_test_{secrets.token_hex(8)}"

    await db.execute(text("""
        UPDATE orders 
        SET razorpay_order_id = :rzp_id, payment_status = 'pending'
        WHERE id = :o_id;
    """), {"rzp_id": rzp_order_id, "o_id": o_uid})
    await db.commit()

    return {
        "status": "created",
        "razorpay_order_id": rzp_order_id,
        "amount_inr": amount,
        "amount_paise": int(amount * 100),
        "currency": "INR",
        "key_id": "rzp_test_makkalsevai_mock",
        "split_summary": {
            "worker_payout": float(order.worker_payout or 250.0),
            "platform_commission": float(order.platform_commission or 25.0)
        },
        "mode": "test"
    }

@router.post("/orders/{order_id}/verify-payment")
async def verify_payment(
    order_id: str,
    payment_id: str = "pay_test_success",
    db: AsyncSession = Depends(get_db)
):
    """
    Simulate successful payment callback/webhook.
    Marks payment_status = 'paid' and credits worker earnings.
    """
    o_uid = uuid.UUID(order_id)
    res = await db.execute(select(Order).where(Order.id == o_uid))
    order = res.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # Update order payment status and credit worker earnings
    await db.execute(text("""
        UPDATE orders 
        SET payment_status = 'paid'
        WHERE id = :o_id;
    """), {"o_id": o_uid})

    if order.worker_id:
        payout = float(order.worker_payout or 250.0)
        await db.execute(text("""
            UPDATE worker_profiles
            SET earnings_total = earnings_total + :payout
            WHERE user_id = :w_id;
        """), {"payout": payout, "w_id": order.worker_id})

    await db.commit()

    return {
        "status": "paid",
        "order_id": order_id,
        "payment_id": payment_id,
        "amount": float(order.final_amount or 275.0),
        "worker_credited": float(order.worker_payout or 250.0)
    }
