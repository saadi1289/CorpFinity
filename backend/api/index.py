from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from core.config import settings
from core.database import init_db, close_db
from core.redis import redis_client
from api import auth, users, challenges, streaks, achievements, reminders, tracking, notifications


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler for startup and shutdown."""
    # Startup
    await init_db()
    await redis_client.connect()
    yield
    # Shutdown
    await redis_client.disconnect()
    await close_db()


# Create FastAPI application
app = FastAPI(
    title="CorpFinity API",
    description="Backend API for CorpFinity wellness app",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api")
app.include_router(users.router, prefix="/api")
app.include_router(challenges.router, prefix="/api")
app.include_router(streaks.router, prefix="/api")
app.include_router(achievements.router, prefix="/api")
app.include_router(reminders.router, prefix="/api")
app.include_router(tracking.router, prefix="/api")
app.include_router(notifications.router, prefix="/api")


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "name": "CorpFinity API",
        "version": "1.0.0",
        "docs": "/api/docs",
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "database": "connected",
        "redis": "connected" if redis_client._client else "disconnected",
    }


@app.get("/api")
async def api_info():
    """API information endpoint."""
    return {
        "name": "CorpFinity API",
        "version": "1.0.0",
        "description": "Backend API for CorpFinity wellness app",
        "endpoints": {
            "auth": "/api/auth",
            "users": "/api/users",
            "challenges": "/api/challenges",
            "streaks": "/api/streaks",
            "achievements": "/api/achievements",
            "reminders": "/api/reminders",
            "tracking": "/api/tracking",
            "notifications": "/api/notifications",
        },
        "documentation": {
            "swagger": "/api/docs",
            "redoc": "/api/redoc",
        },
    }
