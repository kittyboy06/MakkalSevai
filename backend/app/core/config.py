from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    PROJECT_NAME: str = "MakkalSevai API"
    VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api/v1"
    PORT: int = 8001
    HOST: str = "0.0.0.0"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgrespassword@localhost:5433/makkalsevai"
    SYNC_DATABASE_URL: str = "postgresql://postgres:postgrespassword@localhost:5433/makkalsevai"

    # Matching Engine Parameters (Configurable live during judging demo)
    MATCH_WEIGHT_DISTANCE: float = 0.45
    MATCH_WEIGHT_RATING: float = 0.30
    MATCH_WEIGHT_RELIABILITY: float = 0.15
    MATCH_WEIGHT_FAIRNESS: float = 0.10
    MATCH_DEFAULT_RADIUS_METERS: int = 5000
    MATCH_MAX_RADIUS_METERS: int = 15000

    # Auth
    JWT_SECRET: str = "makkalsevai-hackathon-supersecret-jwt-key-2026"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    # Payment (Razorpay Test Mode Sandbox)
    RAZORPAY_KEY_ID: str = "rzp_test_mockkey"
    RAZORPAY_KEY_SECRET: str = "rzp_test_mocksecret"

    # Mock Government APIs
    ENABLE_MOCK_GOV_APIS: bool = True

    # Supabase (Connected via Supabase MCP)
    SUPABASE_PROJECT_ID: Optional[str] = "ulplesjbvblspibdpspr"
    SUPABASE_URL: Optional[str] = "https://ulplesjbvblspibdpspr.supabase.co"
    SUPABASE_ANON_KEY: Optional[str] = None
    SUPABASE_PUBLISHABLE_KEY: Optional[str] = None


    model_config = {
        "env_file": ".env",
        "extra": "ignore"
    }

settings = Settings()
