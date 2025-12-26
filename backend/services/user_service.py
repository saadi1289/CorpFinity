from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from models.models import User, UserStreak, ChallengeHistory
from schemas.schemas import UserUpdate, UserResponse, UserStats
from core.redis import redis_client
from datetime import date, datetime, timedelta


class UserService:
    """User service for profile management."""
    
    @staticmethod
    async def get_user(user_id: str, db: AsyncSession) -> User:
        """Get user by ID, using cache if available."""
        # Try cache first
        cached = await redis_client.cache_get("user", user_id)
        if cached:
            result = await db.execute(
                select(User).where(User.id == user_id)
            )
            return result.scalar_one_or_none()
        
        # Fetch from database
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()
        
        if user:
            # Cache user data
            await redis_client.cache_set(
                "user",
                user_id,
                user.model_dump_json(),
                ttl=3600
            )
        
        return user
    
    @staticmethod
    async def update_user(
        user_id: str,
        data: UserUpdate,
        db: AsyncSession
    ) -> UserResponse:
        """Update user profile."""
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()
        
        if not user:
            raise ValueError("User not found")
        
        # Update fields
        if data.name:
            user.name = data.name
        if data.avatar:
            user.avatar_seed = data.avatar
        
        user.updated_at = datetime.utcnow()
        
        await db.flush()
        await db.refresh(user)
        
        # Update cache
        await redis_client.cache_set(
            "user",
            user_id,
            user.model_dump_json(),
            ttl=3600
        )
        
        return UserResponse.model_validate(user)
    
    @staticmethod
    async def get_user_stats(user_id: str, db: AsyncSession) -> UserStats:
        """Get user statistics."""
        # Get challenge count
        challenge_count = await db.execute(
            select(func.count(ChallengeHistory.id))
            .where(ChallengeHistory.user_id == user_id)
        )
        total_challenges = challenge_count.scalar() or 0
        
        # Get streak data
        streak_result = await db.execute(
            select(UserStreak).where(UserStreak.user_id == user_id)
        )
        streak = streak_result.scalar_one_or_none()
        current_streak = streak.current_streak if streak else 0
        longest_streak = streak.longest_streak if streak else 0
        
        # Get achievements count (static for now)
        achievements_unlocked = 0  # Would query user_achievements table
        
        # Get today's water intake
        today = date.today()
        daily_result = await db.execute(
            select(ChallengeHistory)
            .where(ChallengeHistory.user_id == user_id)
            .where(func.date(ChallengeHistory.completed_at) == today)
        )
        today_challenges = len(daily_result.scalars().all())
        
        return UserStats(
            total_challenges=total_challenges,
            total_streak=current_streak,
            longest_streak=longest_streak,
            achievements_unlocked=achievements_unlocked,
            total_achievements=8,  # Static number based on achievement definitions
            current_water_intake=today_challenges * 250,  # Estimate: 250ml per challenge
            join_date=user.created_at.date() if hasattr(user, 'created_at') else date.today(),
        )
    
    @staticmethod
    async def delete_user(user_id: str, db: AsyncSession) -> bool:
        """Delete user account."""
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()
        
        if not user:
            return False
        
        # Clear cache
        await redis_client.cache_delete("user", user_id)
        await redis_client.clear_cache("user")
        
        # Delete user (cascade will delete related records)
        await db.delete(user)
        
        return True
    
    @staticmethod
    async def invalidate_cache(user_id: str) -> None:
        """Invalidate user cache."""
        await redis_client.cache_delete("user", user_id)
