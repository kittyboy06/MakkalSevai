from sqlalchemy import Column, String, Integer, Numeric, Boolean, Text, ForeignKey, DateTime, ARRAY
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    phone = Column(String(20), unique=True, nullable=False, index=True)
    email = Column(String(255), nullable=True)
    role = Column(String(20), nullable=False)  # 'customer', 'worker', 'admin'
    full_name = Column(String(120), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    customer_profile = relationship("CustomerProfile", back_populates="user", uselist=False)
    worker_profile = relationship("WorkerProfile", back_populates="user", uselist=False)

class CustomerProfile(Base):
    __tablename__ = "customer_profiles"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    saved_addresses = Column(JSONB, default=list)
    # default_location stored in PostGIS

    user = relationship("User", back_populates="customer_profile")

class WorkerProfile(Base):
    __tablename__ = "worker_profiles"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    kyc_status = Column(String(20), default="pending")  # 'pending', 'verified', 'rejected'
    id_document_url = Column(Text, nullable=True)
    face_capture_url = Column(Text, nullable=True)
    uan = Column(String(50), nullable=True)  # Mock e-Shram UAN
    primary_skill_id = Column(Integer, ForeignKey("services.id"), nullable=True)
    secondary_skill_ids = Column(ARRAY(Integer), default=list)
    # current_location stored in PostGIS
    is_available = Column(Boolean, default=False)
    is_on_active_job = Column(Boolean, default=False)
    rating_avg = Column(Numeric(3, 2), default=0.00)
    rating_count = Column(Integer, default=0)
    reliability_score = Column(Numeric(4, 3), default=1.000)
    jobs_completed = Column(Integer, default=0)
    earnings_total = Column(Numeric(12, 2), default=0.00)
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    last_location_update = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="worker_profile")
    primary_skill = relationship("Service", foreign_keys=[primary_skill_id])

class ServiceCategory(Base):
    __tablename__ = "service_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    name_ta = Column(String(100), nullable=True)
    icon = Column(String(50), nullable=True)
    slug = Column(String(100), unique=True, nullable=False)

    services = relationship("Service", back_populates="category")

class Service(Base):
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("service_categories.id", ondelete="CASCADE"))
    name = Column(String(100), nullable=False)
    name_ta = Column(String(100), nullable=True)
    slug = Column(String(100), unique=True, nullable=False)
    icon = Column(String(50), nullable=True)
    base_diagnostic_fee = Column(Numeric(10, 2), default=250.00)
    platform_fee = Column(Numeric(10, 2), default=25.00)
    is_active = Column(Boolean, default=True)

    category = relationship("ServiceCategory", back_populates="services")

class Order(Base):
    __tablename__ = "orders"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    customer_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    worker_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="SET NULL"), nullable=True)
    description = Column(Text, nullable=True)
    status = Column(String(30), default="requested", index=True)
    scheduled_type = Column(String(20), default="immediate")
    scheduled_time = Column(DateTime(timezone=True), nullable=True)
    # customer_location stored in PostGIS
    match_score = Column(Numeric(5, 4), nullable=True)
    final_amount = Column(Numeric(10, 2), nullable=True)
    platform_commission = Column(Numeric(10, 2), nullable=True)
    worker_payout = Column(Numeric(10, 2), nullable=True)
    payment_status = Column(String(20), default="pending")
    razorpay_order_id = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    accepted_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    customer = relationship("User", foreign_keys=[customer_id])
    worker = relationship("User", foreign_keys=[worker_id])
    service = relationship("Service", foreign_keys=[service_id])
    rating = relationship("Rating", back_populates="order", uselist=False)

class Rating(Base):
    __tablename__ = "ratings"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(UUID(as_uuid=True), ForeignKey("orders.id", ondelete="CASCADE"), unique=True)
    customer_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    worker_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    stars = Column(Integer, nullable=False)
    review_text = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    order = relationship("Order", back_populates="rating")

class OrderTracking(Base):
    __tablename__ = "order_tracking"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(UUID(as_uuid=True), ForeignKey("orders.id", ondelete="CASCADE"))
    # worker_location stored in PostGIS
    recorded_at = Column(DateTime(timezone=True), server_default=func.now())

class WorkerTransaction(Base):
    __tablename__ = "worker_transactions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    worker_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    order_id = Column(UUID(as_uuid=True), ForeignKey("orders.id", ondelete="SET NULL"), nullable=True)
    type = Column(String(30), nullable=False)  # 'JOB_PAYOUT', 'BANK_TRANSFER', 'WELFARE_CESS', 'REFUND_ADJUSTMENT'
    amount = Column(Numeric(10, 2), nullable=False)
    status = Column(String(20), default="completed")  # 'completed', 'pending', 'failed'
    reference = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    worker = relationship("User", foreign_keys=[worker_id])
    order = relationship("Order", foreign_keys=[order_id])
