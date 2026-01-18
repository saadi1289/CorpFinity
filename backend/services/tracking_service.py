from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from models.models import DailyTracking
from schemas.schemas import (
    DailyTrackingResponse,
    DailyTrackingUpdate,
    TrackingHistoryResponse,
)
from core.redis import redis_client
from datetime import date, datetime
import json


class TrackingService:
    """Service for daily tracking management."""
    
    @staticmethod
    async def get_today(user_id: str, db: AsyncSession) -> DailyTrackingResponse:
        """Get today's tracking data."""
        today = date.today()
        cache_key = f"{user_id}:{today}"
        
        # Try cache first
        cached = await redis_client.cache_get("tracking", cache_key)
        if cached:
            try:
                cached_data = json.loads(cached)
                return DailyTrackingResponse(**cached_data)
            except:
                pass  # Cache miss or invalid data
        
        result = await db.execute(
            select(DailyTracking)
            .where(DailyTracking.user_id == user_id)
            .where(DailyTracking.date == today)
        )
        tracking = result.scalar_one_or_none()
        
        if not tracking:
            # Create today's tracking record
            tracking = DailyTracking(
                user_id=user_id,
                date=today,
            )
            db.add(tracking)
            await db.flush()
            await db.refresh(tracking)
        
        response = DailyTrackingResponse.model_validate(tracking)
        
        # Cache response
        await redis_client.cache_set(
            "tracking",
            cache_key,
            response.model_dump_json(),
            ttl=300
        )
        
        return response
    
    @staticmethod
    async def update_today(
        user_id: str,
        data: DailyTrackingUpdate,
        db: AsyncSession
    ) -> DailyTrackingResponse:
        """Update today's tracking data."""
        today = date.today()
        
        # Get or create today's tracking
        result = await db.execute(
            select(DailyTracking)
            .where(DailyTracking.user_id == user_id)
            .where(DailyTracking.date == today)
        )
        tracking = result.scalar_one_or_none()
        
        if not tracking:
            tracking = DailyTracking(
                user_id=user_id,
                date=today,
            )
            db.add(tracking)
            await db.flush()
        
        # Update fields
        if data.water_intake is not None:
            tracking.water_intake = data.water_intake
        if data.mood is not None:
            tracking.mood = data.mood
        if data.breathing_sessions is not None:
            tracking.breathing_sessions = data.breathing_sessions
        if data.posture_checks is not None:
            tracking.posture_checks = data.posture_checks
        if data.screen_breaks is not None:
            tracking.screen_breaks = data.screen_breaks
        if data.morning_stretch is not None:
            tracking.morning_stretch = data.morning_stretch
        if data.evening_reflection is not None:
            tracking.evening_reflection = data.evening_reflection
        
        tracking.updated_at = datetime.utcnow()
        
        await db.flush()
        await db.refresh(tracking)
        
        # Invalidate cache
        await redis_client.cache_delete("tracking", f"{user_id}:{today}")
        
        return DailyTrackingResponse.model_validate(tracking)
    
    @staticmethod
    async def get_history(
        user_id: str,
        db: AsyncSession,
        start_date: date,
        end_date: date,
    ) -> TrackingHistoryResponse:
        """Get tracking history for a date range."""
        result = await db.execute(
            select(DailyTracking)
            .where(DailyTracking.user_id == user_id)
            .where(DailyTracking.date >= start_date)
            .where(DailyTracking.date <= end_date)
            .order_by(DailyTracking.date.desc())
        )
        trackings = result.scalars().all()
        
        return TrackingHistoryResponse(
            items=[DailyTrackingResponse.model_validate(t) for t in trackings],
            total=len(trackings),
        )
    
    @staticmethod
    async def increment_water(
        user_id: str,
        amount: int = 250,
        db: AsyncSession
    ) -> DailyTrackingResponse:
        """Increment water intake by amount (default 250ml)."""
        today = date.today()
        
        result = await db.execute(
            select(DailyTracking)
            .where(DailyTracking.user_id == user_id)
            .where(DailyTracking.date == today)
        )
        tracking = result.scalar_one_or_none()
        
        if not tracking:
            tracking = DailyTracking(
                user_id=user_id,
                date=today,
                water_intake=amount,
            )
            db.add(tracking)
        else:
            tracking.water_intake = (tracking.water_intake or 0) + amount
        
        tracking.updated_at = datetime.utcnow()
        
        await db.flush()
        await db.refresh(tracking)
        
        # Invalidate cache
        await redis_client.cache_delete("tracking", f"{user_id}:{today}")
        
        return DailyTrackingResponse.model_validate(tracking)
    
    @staticmethod
    async def set_mood(
        user_id: str,
        mood: str,
        db: AsyncSession
    ) -> DailyTrackingResponse:
        """Set today's mood."""
        today = date.today()
        
        result = await db.execute(
            select(DailyTracking)
            .where(DailyTracking.user_id == user_id)
            .where(DailyTracking.date == today)
        )
        tracking = result.scalar_one_or_none()
        
        if not tracking:
            tracking = DailyTracking(
                user_id=user_id,
                date=today,
                mood=mood,
            )
            db.add(tracking)
        else:
            tracking.mood = mood
        
        tracking.updated_at = datetime.utcnow()
        
        await db.flush()
        await db.refresh(tracking)
        
        # Invalidate cache
        await redis_client.cache_delete("tracking", f"{user_id}:{today}")
        
        return DailyTrackingResponse.model_validate(tracking)
