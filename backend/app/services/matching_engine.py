from typing import List, Optional, Tuple, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class MatchingCandidate:
    def __init__(
        self,
        worker_id: str,
        full_name: str,
        phone: str,
        uan: Optional[str],
        primary_skill_id: int,
        primary_skill_name: str,
        primary_skill_ta: Optional[str],
        secondary_skill_ids: List[int],
        distance_km: float,
        rating_avg: float,
        rating_count: int,
        reliability_score: float,
        jobs_completed: int,
        earnings_total: float,
        joined_at: Any,
        score: float,
        lat: float,
        lng: float
    ):
        self.worker_id = worker_id
        self.full_name = full_name
        self.phone = phone
        self.uan = uan
        self.primary_skill_id = primary_skill_id
        self.primary_skill_name = primary_skill_name
        self.primary_skill_ta = primary_skill_ta
        self.secondary_skill_ids = secondary_skill_ids or []
        self.distance_km = distance_km
        self.rating_avg = rating_avg
        self.rating_count = rating_count
        self.reliability_score = reliability_score
        self.jobs_completed = jobs_completed
        self.earnings_total = earnings_total
        self.joined_at = joined_at
        self.score = score
        self.lat = lat
        self.lng = lng

    def to_dict(self) -> Dict[str, Any]:
        return {
            "worker_id": self.worker_id,
            "full_name": self.full_name,
            "phone": self.phone,
            "uan": self.uan,
            "primary_skill_name": self.primary_skill_name,
            "primary_skill_ta": self.primary_skill_ta,
            "distance_km": round(self.distance_km, 2),
            "rating_avg": round(float(self.rating_avg), 2),
            "rating_count": self.rating_count,
            "reliability_score": round(float(self.reliability_score), 3),
            "reliability_percentage": int(float(self.reliability_score) * 100),
            "jobs_completed": self.jobs_completed,
            "experience_years": round((self.jobs_completed / 40.0) if self.jobs_completed > 0 else 0.1, 1),
            "earnings_total": float(self.earnings_total),
            "joined_at": self.joined_at,
            "match_score": round(self.score, 4),
            "current_lat": self.lat,
            "current_lng": self.lng
        }

class MatchingEngine:
    """
    Implements Section 8 of MakkalSevai specification:
    Spatial Filter -> Skill Filter -> Availability & KYC -> Deterministic Weighted Scoring
    """

    @classmethod
    async def get_config_weights(cls, session: AsyncSession) -> Dict[str, float]:
        """Fetch live configurable weights from DB or fall back to settings."""
        weights = {
            "alpha": settings.MATCH_WEIGHT_DISTANCE,
            "beta": settings.MATCH_WEIGHT_RATING,
            "gamma": settings.MATCH_WEIGHT_RELIABILITY,
            "delta": settings.MATCH_WEIGHT_FAIRNESS
        }
        try:
            res = await session.execute(text("SELECT param_key, param_value FROM matching_config;"))
            rows = res.fetchall()
            for key, val in rows:
                if key == "weight_distance":
                    weights["alpha"] = float(val)
                elif key == "weight_rating":
                    weights["beta"] = float(val)
                elif key == "weight_reliability":
                    weights["gamma"] = float(val)
                elif key == "weight_fairness":
                    weights["delta"] = float(val)
        except Exception as e:
            logger.warning(f"Could not load matching_config from DB: {e}. Using defaults.")
        return weights

    @classmethod
    async def find_candidates(
        cls,
        session: AsyncSession,
        service_id: int,
        customer_lat: float,
        customer_lng: float,
        exclude_worker_ids: Optional[List[str]] = None
    ) -> List[MatchingCandidate]:
        """
        Progressively expands search radius (5km -> 10km -> 15km)
        until at least 1 verified and eligible candidate is found.
        """
        weights = await cls.get_config_weights(session)
        radii = [5000, 10000, 15000]
        exclude_ids = exclude_worker_ids or []

        for radius_meters in radii:
            query = text("""
                SELECT 
                    u.id as worker_id,
                    u.full_name,
                    u.phone,
                    w.uan,
                    w.primary_skill_id,
                    s.name as primary_skill_name,
                    s.name_ta as primary_skill_ta,
                    w.secondary_skill_ids,
                    (ST_Distance(
                        w.current_location,
                        ST_SetSRID(ST_MakePoint(:c_lng, :c_lat), 4326)::geography
                    ) / 1000.0) as distance_km,
                    COALESCE(w.rating_avg, 0.0) as rating_avg,
                    COALESCE(w.rating_count, 0) as rating_count,
                    COALESCE(w.reliability_score, 1.0) as reliability_score,
                    COALESCE(w.jobs_completed, 0) as jobs_completed,
                    COALESCE(w.earnings_total, 0.0) as earnings_total,
                    w.joined_at,
                    ST_Y(w.current_location::geometry) as lat,
                    ST_X(w.current_location::geometry) as lng
                FROM worker_profiles w
                JOIN users u ON u.id = w.user_id
                JOIN services s ON s.id = w.primary_skill_id
                WHERE 
                    w.kyc_status = 'verified'
                    AND w.is_available = true
                    AND w.is_on_active_job = false
                    AND (w.primary_skill_id = :service_id OR :service_id = ANY(w.secondary_skill_ids))
                    AND ST_DWithin(
                        w.current_location,
                        ST_SetSRID(ST_MakePoint(:c_lng, :c_lat), 4326)::geography,
                        :radius_meters
                    )
            """)

            res = await session.execute(query, {
                "c_lat": customer_lat,
                "c_lng": customer_lng,
                "service_id": service_id,
                "radius_meters": radius_meters
            })
            rows = res.fetchall()

            candidates: List[MatchingCandidate] = []
            for r in rows:
                w_id = str(r.worker_id)
                if w_id in exclude_ids:
                    continue

                dist_km = max(float(r.distance_km), 0.1)  # avoid division by zero
                rating_norm = min(float(r.rating_avg) / 5.0, 1.0)
                rel_norm = min(float(r.reliability_score), 1.0)
                # Fairness rule: workers with < 5 reviews get a 1.0 fairness boost; otherwise 0.3
                fairness = 1.0 if int(r.rating_count) < 5 else 0.3

                # Score formula:
                # Score_i = (alpha * (1 / distance_i)) + (beta * rating_norm) + (gamma * rel_norm) + (delta * fairness)
                inv_distance = min(1.0 / dist_km, 5.0)  # clamp max inverse distance to 5
                score = (
                    (weights["alpha"] * inv_distance) +
                    (weights["beta"] * rating_norm) +
                    (weights["gamma"] * rel_norm) +
                    (weights["delta"] * fairness)
                )

                candidates.append(MatchingCandidate(
                    worker_id=w_id,
                    full_name=r.full_name or "Verified Tradesperson",
                    phone=r.phone,
                    uan=r.uan,
                    primary_skill_id=r.primary_skill_id,
                    primary_skill_name=r.primary_skill_name,
                    primary_skill_ta=r.primary_skill_ta,
                    secondary_skill_ids=r.secondary_skill_ids or [],
                    distance_km=dist_km,
                    rating_avg=float(r.rating_avg),
                    rating_count=int(r.rating_count),
                    reliability_score=float(r.reliability_score),
                    jobs_completed=int(r.jobs_completed),
                    earnings_total=float(r.earnings_total),
                    joined_at=r.joined_at,
                    score=score,
                    lat=float(r.lat) if r.lat else customer_lat + 0.005,
                    lng=float(r.lng) if r.lng else customer_lng + 0.005
                ))

            if candidates:
                # Sort descending by score
                candidates.sort(key=lambda c: c.score, reverse=True)
                logger.info(f"Found {len(candidates)} candidates within {radius_meters}m radius.")
                return candidates

        return []
