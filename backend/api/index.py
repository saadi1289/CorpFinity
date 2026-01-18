from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from core.config import settings
from core.database import init_db, close_db
from core.redis import redis_client
from services.scheduler_service import start_scheduler, stop_scheduler
from services.achievement_service import AchievementService
from api import auth, users, challenges, challenge_db, streaks, achievements, reminders, tracking, notifications


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler for startup and shutdown."""
    # Startup
    print("🚀 Starting CorpFinity API...")
    await init_db()
    await redis_client.connect()
    
    # Seed achievement definitions
    try:
        from core.database import AsyncSessionLocal
        async with AsyncSessionLocal() as db:
            await AchievementService.seed_achievement_definitions(db)
            await db.commit()
        print("✅ Achievement definitions seeded")
    except Exception as e:
        print(f"⚠️ Failed to seed achievements: {e}")
    
    # Start scheduler for reminder notifications
    await start_scheduler()
    
    print("✅ CorpFinity API started successfully")
    
    yield
    
    # Shutdown
    print("🛑 Shutting down CorpFinity API...")
    await stop_scheduler()
    await redis_client.disconnect()
    await close_db()
    print("✅ CorpFinity API shutdown complete")


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
    """Health check endpoint for Render and monitoring."""
    from core.database import health_check_db
    from core.redis import redis_client
    
    # Check database connection
    db_healthy = await health_check_db()
    
    # Check Redis connection
    redis_healthy = False
    try:
        await redis_client.connect()
        redis_healthy = await redis_client.exists("health_check") >= 0
    except Exception:
        redis_healthy = False
    
    status = "healthy" if db_healthy and redis_healthy else "unhealthy"
    
    return {
        "status": status,
        "database": "connected" if db_healthy else "disconnected",
        "redis": "connected" if redis_healthy else "disconnected",
        "supabase_url": settings.SUPABASE_URL,
        "environment": settings.ENVIRONMENT,
        "version": "1.0.0"
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
