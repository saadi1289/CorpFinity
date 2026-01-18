from pydantic_settings import BaseSettings
from typing import Optional
from functools import lru_cache


class Settings(BaseSettings):
    # Supabase Database Configuration
    DATABASE_URL: str = "postgresql://postgres.ywmeiptfbgraabvcxhgc:YOUR_DB_PASSWORD@aws-0-us-east-1.pooler.supabase.com:6543/postgres"
    SUPABASE_URL: str = "https://ywmeiptfbgraabvcxhgc.supabase.co"
    SUPABASE_ANON_KEY: str = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3bWVpcHRmYmdyYWFidmN4aGdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc0NzE2NzQsImV4cCI6MjA1MzA0NzY3NH0.Op7-orO7Os-LgslcJZ27Zg_JJElD57m"
    SUPABASE_SERVICE_ROLE_KEY: Optional[str] = None  # For admin operations
    
    # JWT Configuration
    SECRET_KEY: str = "your-new-production-secret-key-change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days
    
    # Redis Configuration (Render Redis or external)
    REDIS_URL: str = "redis://localhost:6379"
    REDIS_PASSWORD: Optional[str] = None
    
    # Application Configuration
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000
    DEBUG: bool = False
    ENVIRONMENT: str = "development"  # development, staging, production
    
    # CORS Configuration
    CORS_ORIGINS: list = [
        "http://localhost:3000", 
        "http://localhost:8080", 
        "http://localhost:8000",
        "https://your-flutter-web-app.com",  # Add your production Flutter web URL
        "https://corpfinity-backend.onrender.com"  # Add your Render app URL
    ]
    
    # Supabase Configuration
    SUPABASE_REALTIME_ENABLED: bool = True
    
    # Security
    ALLOWED_HOSTS: list = ["*"]  # Configure properly for production
    
    # Logging
    LOG_LEVEL: str = "INFO"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()


# Supabase connection string builder
def get_supabase_db_url() -> str:
    """Build Supabase database URL with proper SSL configuration."""
    if settings.ENVIRONMENT == "production":
        # Production Supabase connection
        return settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://") + "?sslmode=require"
    else:
        # Development/local connection
        return settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")


def get_supabase_sync_url() -> str:
    """Build Supabase database URL for synchronous operations."""
    if settings.ENVIRONMENT == "production":
        return settings.DATABASE_URL + "?sslmode=require"
    else:
        return settings.DATABASE_URL
