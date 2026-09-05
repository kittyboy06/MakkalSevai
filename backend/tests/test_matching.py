import pytest
import sys
import os
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.pool import NullPool

# Add backend directory to sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.services.matching_engine import MatchingEngine
from app.core.config import settings

async def _get_session():
    engine = create_async_engine(settings.DATABASE_URL, echo=False, poolclass=NullPool)
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session_factory() as session:
        yield session
    await engine.dispose()

@pytest.mark.asyncio
async def test_matching_finds_verified_electrician():
    """Scenario: Standard customer at T. Nagar requests Electrician. Should return verified candidates."""
    async for session in _get_session():
        candidates = await MatchingEngine.find_candidates(
            session=session,
            service_id=1,  # Electrician
            customer_lat=13.0418,
            customer_lng=80.2341
        )
        assert len(candidates) > 0
        top = candidates[0]
        assert top.primary_skill_name == "Electrician"
        assert top.score > 0
        break
@pytest.mark.asyncio
async def test_worker_unavailable_excluded():
    """Scenario: Worker who is offline/unavailable (Praveen Kumar) must be excluded."""
    async for session in _get_session():
        candidates = await MatchingEngine.find_candidates(
            session=session,
            service_id=1,
            customer_lat=13.0418,
            customer_lng=80.2341
        )
        worker_names = [c.full_name for c in candidates]
        assert "Praveen Kumar (Offline)" not in worker_names
        break

@pytest.mark.asyncio
async def test_worker_on_active_job_excluded():
    """Scenario: Worker who is on an active job (Dinesh Pandian) must be excluded."""
    async for session in _get_session():
        candidates = await MatchingEngine.find_candidates(
            session=session,
            service_id=1,
            customer_lat=13.0418,
            customer_lng=80.2341
        )
        worker_names = [c.full_name for c in candidates]
        assert "Dinesh Pandian (Busy)" not in worker_names
        break

@pytest.mark.asyncio
async def test_worker_unverified_excluded():
    """Scenario: Worker with pending KYC (Suresh Babu) must be excluded."""
    async for session in _get_session():
        candidates = await MatchingEngine.find_candidates(
            session=session,
            service_id=1,
            customer_lat=13.0418,
            customer_lng=80.2341
        )
        worker_names = [c.full_name for c in candidates]
        assert "Suresh Babu (Unverified)" not in worker_names
        break

@pytest.mark.asyncio
async def test_secondary_skill_matching():
    """Scenario: Worker with Electrician as secondary skill (Gopalakrishnan) should be eligible."""
    async for session in _get_session():
        candidates = await MatchingEngine.find_candidates(
            session=session,
            service_id=1,  # Electrician
            customer_lat=13.0418,
            customer_lng=80.2341
        )
        worker_names = [c.full_name for c in candidates]
        assert "Gopalakrishnan" in worker_names
        break

@pytest.mark.asyncio
async def test_fairness_boost_for_new_workers():
    """Scenario: New worker with < 5 jobs (Karthik Subramanian) receives 1.0 fairness boost."""
    async for session in _get_session():
        await session.execute(text(
            "UPDATE worker_profiles SET rating_count = 3, jobs_completed = 3 "
            "WHERE user_id = (SELECT id FROM users WHERE full_name LIKE '%Karthik%')"
        ))
        await session.commit()

        candidates = await MatchingEngine.find_candidates(
            session=session,
            service_id=1,
            customer_lat=13.0418,
            customer_lng=80.2341
        )
        new_worker = next((c for c in candidates if "Karthik" in c.full_name), None)
        assert new_worker is not None
        assert new_worker.rating_count < 5
        assert new_worker.score >= 0.7
        break

@pytest.mark.asyncio
async def test_progressive_radius_expansion():
    """
    Scenario: If customer is at Kolathur (13.1200, 80.2100), worker Shankar is ~1km away,
    but T. Nagar workers are >11km away.
    If we search for Mason from Kolathur where no mason is in 5km, it progressively expands to 10km/15km.
    """
    async for session in _get_session():
        candidates = await MatchingEngine.find_candidates(
            session=session,
            service_id=5,  # Mason
            customer_lat=13.1200,
            customer_lng=80.2100
        )
        assert len(candidates) > 0
        assert any("Balamurugan" in c.full_name for c in candidates)
        break

@pytest.mark.asyncio
async def test_rejection_fallback_next_candidate():
    """Scenario: If top worker rejects or is excluded, the engine returns the next best candidate."""
    async for session in _get_session():
        candidates_all = await MatchingEngine.find_candidates(
            session=session,
            service_id=1,
            customer_lat=13.0418,
            customer_lng=80.2341
        )
        assert len(candidates_all) >= 2
        top_worker_id = candidates_all[0].worker_id

        fallback_candidates = await MatchingEngine.find_candidates(
            session=session,
            service_id=1,
            customer_lat=13.0418,
            customer_lng=80.2341,
            exclude_worker_ids=[top_worker_id]
        )
        assert len(fallback_candidates) > 0
        assert fallback_candidates[0].worker_id != top_worker_id
        assert fallback_candidates[0].worker_id == candidates_all[1].worker_id
        break

