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
async def test_auth_email_flow():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Existing user login with senthil.nathan@example.com
        res1 = await client.post("/api/v1/auth/email/login", json={
            "email": "senthil.nathan@example.com",
            "otp": "123456"
        })
        assert res1.status_code == 200
        data1 = res1.json()
        assert "access_token" in data1
        assert data1["email"] == "senthil.nathan@example.com"
        assert data1["full_name"] == "Senthil Nathan"
        assert data1["role"] == "customer"

        # 2. Check profile endpoint with this token
        token1 = data1["access_token"]
        prof1 = await client.get("/api/v1/customers/me/profile", headers={"Authorization": f"Bearer {token1}"})
        assert prof1.status_code == 200
        pdata1 = prof1.json()
        assert pdata1["full_name"] == "Senthil Nathan"
        assert pdata1["email"] == "senthil.nathan@example.com"
        assert len(pdata1["saved_addresses"]) >= 1

        # 3. New user login with novel email
        res2 = await client.post("/api/v1/auth/email/login", json={
            "email": "chennai.citizen.new@example.com",
            "full_name": "Kavitha Sundaram"
        })
        assert res2.status_code == 200
        data2 = res2.json()
        assert data2["full_name"] == "Kavitha Sundaram"
        assert data2["email"] == "chennai.citizen.new@example.com"

        # 4. Profile endpoint for new user returns clean 0 stats
        token2 = data2["access_token"]
        prof2 = await client.get("/api/v1/customers/me/profile", headers={"Authorization": f"Bearer {token2}"})
        assert prof2.status_code == 200
        pdata2 = prof2.json()
        assert pdata2["full_name"] == "Kavitha Sundaram"
        assert pdata2["stats"]["total_bookings"] == 0

        # 5. Test dedicated Email & Password Sign Up endpoint with unique email
        import uuid as _uuid
        unique_email = f"deepak.raj.{_uuid.uuid4().hex[:6]}@example.com"
        res3 = await client.post("/api/v1/auth/email/signup", json={
            "full_name": "Deepak Raj",
            "email": unique_email,
            "password": "securepassword123",
            "phone": f"+91987{_uuid.uuid4().int % 10000000:07d}"
        })
        assert res3.status_code == 200
        data3 = res3.json()
        assert data3["full_name"] == "Deepak Raj"
        assert data3["email"] == unique_email
        assert "access_token" in data3

        # 6. Test logging in with password for the newly registered user
        login_res = await client.post("/api/v1/auth/email/login", json={
            "email": unique_email,
            "password": "securepassword123"
        })
        assert login_res.status_code == 200
        assert login_res.json()["email"] == unique_email

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

@pytest.mark.asyncio
async def test_customer_me_and_orders_flow():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Authenticate customer
        verify_res = await client.post("/api/v1/auth/otp/verify", json={
            "phone": "+919876543210",
            "otp": "123456"
        })
        assert verify_res.status_code == 200
        token = verify_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Get customer profile
        prof_res = await client.get("/api/v1/customers/me/profile", headers=headers)
        assert prof_res.status_code == 200
        prof_data = prof_res.json()
        assert prof_data["phone"] == "+919876543210"
        assert "stats" in prof_data
        assert "saved_addresses" in prof_data

        # 3. Add a saved address
        addr_res = await client.post("/api/v1/customers/me/addresses", headers=headers, json={
            "label": "Work",
            "address": "45, Anna Salai, Thousand Lights, Chennai - 600006",
            "lat": 13.0604,
            "lng": 80.2496,
            "is_default": False
        })
        assert addr_res.status_code == 200
        updated_prof = addr_res.json()
        assert any(a["label"] == "Work" for a in updated_prof["saved_addresses"])

        # 4. Fetch customer orders
        orders_res = await client.get("/api/v1/orders/me", headers=headers)
        assert orders_res.status_code == 200
        assert isinstance(orders_res.json(), list)

        # 5. Check active order
        active_res = await client.get("/api/v1/orders/me/active", headers=headers)
        assert active_res.status_code == 200
        # Either None or active order object


@pytest.mark.asyncio
async def test_worker_me_and_wallet_flow():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login with Rajesh Kumar's email
        res = await client.post("/api/v1/auth/email/login", json={
            "email": "rajesh.kumar@example.com",
            "password": "password123"
        })
        assert res.status_code == 200
        data = res.json()
        assert data["role"] == "worker"
        assert "access_token" in data
        token = data["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Fetch /workers/me/jobs
        jobs_res = await client.get("/api/v1/workers/me/jobs", headers=headers)
        assert jobs_res.status_code == 200
        jobs = jobs_res.json()
        assert len(jobs) >= 1
        assert "status" in jobs[0]
        assert "worker_payout" in jobs[0]
        assert "service_name" in jobs[0]

        # 3. Fetch /workers/me/wallet
        wallet_res = await client.get("/api/v1/workers/me/wallet", headers=headers)
        assert wallet_res.status_code == 200
        wallet = wallet_res.json()
        assert "available_balance" in wallet
        assert wallet["available_balance"] > 0
        assert "today_earnings" in wallet
        assert "welfare_cess_total" in wallet
        assert "payout_bank" in wallet
        assert wallet["payout_bank"]["status_label"] == "Demo Linked Account"
        assert len(wallet["transactions"]) >= 1

        # 4. Test instant payout
        orig_balance = wallet["available_balance"]
        payout_res = await client.post("/api/v1/workers/me/wallet/payout", headers=headers, json={
            "amount": 100.0
        })
        assert payout_res.status_code == 200
        payout_data = payout_res.json()
        assert payout_data["available_balance"] == round(orig_balance - 100.0, 2)
        # Verify BANK_TRANSFER is in transactions
        assert any(t["type"] == "BANK_TRANSFER" and t["amount"] == 100.0 for t in payout_data["transactions"])

        # 5. Fetch /workers/me/passport
        passport_res = await client.get("/api/v1/workers/me/passport", headers=headers)
        assert passport_res.status_code == 200
        passport = passport_res.json()
        assert passport["rating_avg"] >= 4.0
        assert passport["kyc_status"] == "verified"

        # 6. Update GPS location
        loc_res = await client.post("/api/v1/workers/me/location", headers=headers, json={
            "lat": 13.0455,
            "lng": 80.2385
        })
        assert loc_res.status_code == 200
        assert loc_res.json()["status"] == "ok"

        # 7. Toggle availability
        avail_res = await client.post("/api/v1/workers/me/availability?is_available=true", headers=headers)
        assert avail_res.status_code == 200
        assert avail_res.json()["is_available"] is True

