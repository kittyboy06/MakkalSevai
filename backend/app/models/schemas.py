from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
import uuid

# Auth Schemas
class OTPRequest(BaseModel):
    phone: str = Field(..., example="+919876543210")
    role: str = Field(default="customer", example="customer")

class OTPVerifyRequest(BaseModel):
    phone: str = Field(..., example="+919876543210")
    otp: str = Field(..., example="123456")

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    phone: str
    role: str
    full_name: Optional[str] = None

# Services & Ontology Schemas
class ServiceItem(BaseModel):
    id: int
    category_id: int
    name: str
    name_ta: Optional[str] = None
    slug: str
    icon: Optional[str] = None
    base_diagnostic_fee: float
    platform_fee: float
    is_active: bool

class CategoryItem(BaseModel):
    id: int
    name: str
    name_ta: Optional[str] = None
    slug: str
    icon: Optional[str] = None
    services: List[ServiceItem] = []

# Digital Skill Passport Schemas
class SkillPassportResponse(BaseModel):
    worker_id: str
    full_name: str
    phone: str
    kyc_status: str
    uan: Optional[str] = None
    primary_skill_name: str
    primary_skill_ta: Optional[str] = None
    secondary_skills: List[str] = []
    rating_avg: float
    rating_count: int
    reliability_score: float
    reliability_percentage: int
    jobs_completed: int
    experience_years: float
    earnings_total: float
    joined_at: datetime
    current_lat: Optional[float] = None
    current_lng: Optional[float] = None

# Order & Booking Schemas
class OrderCreateRequest(BaseModel):
    service_id: int
    description: Optional[str] = None
    scheduled_type: str = Field(default="immediate", example="immediate")
    scheduled_time: Optional[datetime] = None
    customer_lat: float = Field(..., example=13.0418)
    customer_lng: float = Field(..., example=80.2341)
    address_text: Optional[str] = "Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai"

class OrderResponse(BaseModel):
    id: str
    customer_id: Optional[str] = None
    worker_id: Optional[str] = None
    service_id: Optional[int] = None
    service_name: Optional[str] = None
    description: Optional[str] = None
    status: str
    scheduled_type: str
    final_amount: Optional[float] = None
    platform_commission: Optional[float] = None
    worker_payout: Optional[float] = None
    payment_status: str
    match_score: Optional[float] = None
    matched_worker: Optional[SkillPassportResponse] = None
    created_at: datetime
    accepted_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

# Rating Schema
class RatingCreateRequest(BaseModel):
    stars: int = Field(..., ge=1, le=5)
    review_text: Optional[str] = None

class RatingResponse(BaseModel):
    id: int
    order_id: str
    stars: int
    review_text: Optional[str] = None
    created_at: datetime
