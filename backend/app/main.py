from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import json
import logging

from app.core.config import settings
from app.api.v1 import auth, services, orders, workers, ratings, payments, admin

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("makkalsevai")

app = FastAPI(
    title="MakkalSevai Core Backend API",
    description="Government-Backed Gig-Economy Marketplace for Verified Blue-Collar Workers (SIH 2026 · PS26089)",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register API v1 Routers
app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(services.router, prefix=settings.API_V1_PREFIX)
app.include_router(orders.router, prefix=settings.API_V1_PREFIX)
app.include_router(workers.router, prefix=settings.API_V1_PREFIX)
app.include_router(ratings.router, prefix=settings.API_V1_PREFIX)
app.include_router(payments.router, prefix=settings.API_V1_PREFIX)
app.include_router(admin.router, prefix=settings.API_V1_PREFIX)

@app.get("/")
async def root():
    return {
        "app": "MakkalSevai",
        "tagline": "Trusted local skills, delivered digitally.",
        "status": "operational",
        "docs": "/docs",
        "version": "1.0.0"
    }

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "makkalsevai-backend"}

# WebSocket for live GPS order tracking simulation
@app.websocket("/ws/orders/{order_id}/tracking")
async def websocket_tracking(websocket: WebSocket, order_id: str):
    await websocket.accept()
    logger.info(f"WebSocket connected for order {order_id}")
    
    # Simulate worker moving from (13.0450, 80.2380) toward customer at (13.0418, 80.2341)
    worker_lat = 13.0450
    worker_lng = 80.2380
    dest_lat = 13.0418
    dest_lng = 80.2341

    steps = 10
    step = 0
    try:
        while True:
            fraction = min(step / steps, 1.0)
            current_lat = worker_lat + fraction * (dest_lat - worker_lat)
            current_lng = worker_lng + fraction * (dest_lng - worker_lng)
            eta_mins = max(12 - step, 1)

            payload = {
                "order_id": order_id,
                "worker_lat": round(current_lat, 5),
                "worker_lng": round(current_lng, 5),
                "eta_mins": eta_mins,
                "status": "arrived" if fraction >= 1.0 else "worker_enroute"
            }
            await websocket.send_text(json.dumps(payload))
            step = (step + 1) % (steps + 1)
            await asyncio.sleep(3)
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for order {order_id}")
