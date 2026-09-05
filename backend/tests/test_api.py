import pytest
import sys
import os
from httpx import AsyncClient, ASGITransport

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app

@pytest.mark.asyncio
async def test_health_and_root():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.get("/health")
        assert res.status_code == 200
        assert res.json()["status"] == "healthy"

        res_root = await client.get("/")
        assert res_root.status_code == 200
        assert res_root.json()["app"] == "MakkalSevai"

@pytest.mark.asyncio
async def test_auth_otp_flow():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        req_res = await client.post("/api/v1/auth/otp/request", json={
            "phone": "+919876543210",
            "role": "customer"
        })
        assert req_res.status_code == 200
        assert "dev_otp" in req_res.json()

        verify_res = await client.post("/api/v1/auth/otp/verify", json={
            "phone": "+919876543210",
            "otp": "123456"
        })
        assert verify_res.status_code == 200
        data = verify_res.json()
        assert "access_token" in data
        assert data["role"] == "customer"

@pytest.mark.asyncio
async def test_service_ontology():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.get("/api/v1/services/categories")
        assert res.status_code == 200
        categories = res.json()
        assert len(categories) >= 6
        core_trades = next((c for c in categories if c["slug"] == "core-trades"), None)
        assert core_trades is not None
        assert len(core_trades["services"]) >= 6

@pytest.mark.asyncio
async def test_full_order_demo_lifecycle():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Create order for Electrician (service_id=1)
        create_res = await client.post("/api/v1/orders", json={
            "service_id": 1,
            "description": "Switchboard sparking in living room",
            "scheduled_type": "immediate",
            "customer_lat": 13.0418,
            "customer_lng": 80.2341,
            "address_text": "Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar"
        })
        assert create_res.status_code == 200
        order_data = create_res.json()
        order_id = order_data["id"]
        assert order_data["status"] == "accepted"
        assert order_data["matched_worker"] is not None
        assert order_data["final_amount"] == 275.0
        assert order_data["platform_commission"] == 25.0
        assert order_data["worker_payout"] == 250.0

        # 2. Worker starts job
        start_res = await client.post(f"/api/v1/orders/{order_id}/start")
        assert start_res.status_code == 200
        assert start_res.json()["status"] == "in_progress"

        # 3. Worker completes job
        comp_res = await client.post(f"/api/v1/orders/{order_id}/complete")
        assert comp_res.status_code == 200
        assert comp_res.json()["status"] == "completed"

        # 4. Create Razorpay Test payment
        pay_res = await client.post(f"/api/v1/payments/orders/{order_id}/create-payment")
        assert pay_res.status_code == 200
        pay_data = pay_res.json()
        assert pay_data["amount_inr"] == 275.0
        assert "order_test_" in pay_data["razorpay_order_id"]

        # 5. Verify payment callback
        verify_pay = await client.post(f"/api/v1/payments/orders/{order_id}/verify-payment")
        assert verify_pay.status_code == 200
        assert verify_pay.json()["status"] == "paid"

        # 6. Customer submits 5-star rating
        rate_res = await client.post(f"/api/v1/orders/{order_id}/rate", json={
            "stars": 5,
            "review_text": "Excellent and safe work done on time!"
        })
        assert rate_res.status_code == 200
        assert rate_res.json()["stars"] == 5

