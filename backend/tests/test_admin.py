import pytest
import sys
import os
from httpx import AsyncClient, ASGITransport

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app

@pytest.mark.asyncio
async def test_admin_auth_required():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Request without credentials should be rejected with 401
        res = await client.get("/api/v1/admin/kpis")
        assert res.status_code == 401

@pytest.mark.asyncio
async def test_admin_login_and_kpis():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login with demo municipal officer credentials
        login_res = await client.post("/api/v1/admin/login", json={
            "username": "inspector.meenakshi",
            "password": "makkalsevai2026"
        })
        assert login_res.status_code == 200
        token_data = login_res.json()
        assert "access_token" in token_data
        assert token_data["role"] == "admin"
        token = token_data["access_token"]

        headers = {"Authorization": f"Bearer {token}"}

        # 2. Fetch KPIs
        kpi_res = await client.get("/api/v1/admin/kpis", headers=headers)
        assert kpi_res.status_code == 200
        kpi_data = kpi_res.json()
        assert "active_jobs" in kpi_data
        assert "today_gmv" in kpi_data
        assert "fee_model" in kpi_data

        # 3. Fetch Telemetry
        tele_res = await client.get("/api/v1/admin/workers/telemetry", headers=headers)
        assert tele_res.status_code == 200
        tele_data = tele_res.json()
        assert "fleet" in tele_data
        assert len(tele_data["fleet"]) > 0

        # 4. Fetch KYC Queue
        kyc_res = await client.get("/api/v1/admin/kyc/queue", headers=headers)
        assert kyc_res.status_code == 200
        kyc_data = kyc_res.json()
        assert "queue" in kyc_data
        assert "sandbox_notice" in kyc_data

        # 5. Price Governance
        price_res = await client.get("/api/v1/admin/price-governance", headers=headers)
        assert price_res.status_code == 200
        price_data = price_res.json()
        assert "regulated_trades" in price_data

        # 6. Demand Heatmap
        heat_res = await client.get("/api/v1/admin/analytics/heatmap", headers=headers)
        assert heat_res.status_code == 200
        heat_data = heat_res.json()
        assert heat_data["type"] == "FeatureCollection"
        assert len(heat_data["features"]) > 0
