from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from typing import List, Optional

from app.core.database import get_db
from app.models.entities import ServiceCategory, Service
from app.models.schemas import CategoryItem, ServiceItem

router = APIRouter(prefix="/services", tags=["Services & Ontology"])

@router.get("/categories", response_model=List[CategoryItem])
async def get_categories(db: AsyncSession = Depends(get_db)):
    """
    Get all service categories with nested services (Section 6 taxonomy).
    """
    query = select(ServiceCategory).options(selectinload(ServiceCategory.services)).order_by(ServiceCategory.id)
    res = await db.execute(query)
    categories = res.scalars().all()

    output = []
    for cat in categories:
        output.append(CategoryItem(
            id=cat.id,
            name=cat.name,
            name_ta=cat.name_ta,
            slug=cat.slug,
            icon=cat.icon,
            services=[
                ServiceItem(
                    id=s.id,
                    category_id=s.category_id,
                    name=s.name,
                    name_ta=s.name_ta,
                    slug=s.slug,
                    icon=s.icon,
                    base_diagnostic_fee=float(s.base_diagnostic_fee or 250.0),
                    platform_fee=float(s.platform_fee or 25.0),
                    is_active=s.is_active
                ) for s in cat.services if s.is_active
            ]
        ))
    return output

@router.get("", response_model=List[ServiceItem])
async def get_services(
    category_id: Optional[int] = Query(None, description="Filter by category ID"),
    db: AsyncSession = Depends(get_db)
):
    """
    Get active services list.
    """
    query = select(Service).where(Service.is_active == True)
    if category_id is not None:
        query = query.where(Service.category_id == category_id)
    query = query.order_by(Service.id)

    res = await db.execute(query)
    services = res.scalars().all()

    return [
        ServiceItem(
            id=s.id,
            category_id=s.category_id,
            name=s.name,
            name_ta=s.name_ta,
            slug=s.slug,
            icon=s.icon,
            base_diagnostic_fee=float(s.base_diagnostic_fee or 250.0),
            platform_fee=float(s.platform_fee or 25.0),
            is_active=s.is_active
        ) for s in services
    ]
