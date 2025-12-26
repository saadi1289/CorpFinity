from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from models.models import UserStreak
from schemas.schemas import StreakResponse, StreakValidateResponse
from core.redis import redis_client
from datetime import date, datetime, timedelta
import json


class StreakService:
    """Service for streak management."""
    
    @staticmethod
    def _serialize_streak(streak: UserStreak) -> str:
        """Serialize streak to JSON string."""
        return json.dumps({
            "current_streak": streak.current_streak,
            "longest_streak": streak.longest_streak,
            "last_completed_date": str(streak.last_completed_date) if streak.last_completed_date else None,
            "updated_at": streak.updated_at.isoformat() if streak.updated_at else None,
        })
    
    @staticmethod
    async def get_streak(user_id: str, db: AsyncSession) -> StreakResponse:
        """Get current streak information."""
        cached = await redis_client.cache_get("streak", user_id)
        
        result = await db.execute(
            select(UserStreak).where(UserStreak.user_id == user_id)
        )
        streak = result.scalar_one_or_none()
        
        if not streak:
            return StreakResponse(
                current_streak=0,
                longest_streak=0,
                last_completed_date=None,
                updated_at=datetime.utcnow(),
            )
        
        await redis_client.cache_set(
            "streak",
            user_id,
            StreakService._serialize_streak(streak),
            ttl=300
        )
        
        return StreakResponse.model_validate(streak)
    
    @staticmethod
    async def validate_streak(user_id: str, db: AsyncSession) -> StreakValidateResponse:
        """Validate and potentially update streak."""
        result = await db.execute(
            select(UserStreak).where(UserStreak.user_id == user_id)
        )
        streak = result.scalar_one_or_none()
        
        today = date.today()
        streak_updated = False
        message = ""
        
        if not streak:
            streak = UserStreak(
                user_id=user_id,
                current_streak=0,
                longest_streak=0,
                last_completed_date=None,
            )
            message = "Start your streak by completing a challenge today!"
        else:
            if streak.last_completed_date == today:
                message = "You've already completed a challenge today. Keep up the momentum!"
            elif streak.last_completed_date == today - timedelta(days=1):
                streak.current_streak += 1
                if streak.current_streak > streak.longest_streak:
                    streak.longest_streak = streak.current_streak
                streak.last_completed_date = today
                streak_updated = True
                message = f"Streak updated! You're on a {streak.current_streak}-day streak!"
            else:
                streak.current_streak = 1
                streak.last_completed_date = today
                streak_updated = True
                message = "Streak reset! Start a new streak today!"
        
        if streak.id:
            await db.flush()
        else:
            db.add(streak)
            await db.flush()
        
        await redis_client.cache_delete("streak", user_id)
        
        return StreakValidateResponse(
            streak_updated=streak_updated,
            current_streak=streak.current_streak,
            longest_streak=streak.longest_streak,
            message=message,
        )
    
    @staticmethod
    async def reset_streak(user_id: str, db: AsyncSession) -> StreakResponse:
        """Reset user streak (admin or self-service)."""
        result = await db.execute(
            select(UserStreak).where(UserStreak.user_id == user_id)
        )
        streak = result.scalar_one_or_none()
        
        if streak:
            streak.current_streak = 0
            streak.last_completed_date = None
            await db.flush()
        
        await redis_client.cache_delete("streak", user_id)
        
        return await StreakService.get_streak(user_id, db)
