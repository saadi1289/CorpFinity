from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from models.models import ChallengeHistory, UserStreak
from schemas.schemas import ChallengeHistoryCreate, ChallengeHistoryResponse, ChallengeHistoryListResponse
from core.redis import redis_client
from datetime import datetime, date, timedelta


class ChallengeService:
    """Service for challenge history management."""
    
    @staticmethod
    async def complete_challenge(
        user_id: str,
        data: ChallengeHistoryCreate,
        db: AsyncSession
    ) -> ChallengeHistoryResponse:
        """Record a completed challenge and update streak."""
        # Create challenge history entry
        challenge = ChallengeHistory(
            user_id=user_id,
            title=data.title,
            description=data.description,
            duration=data.duration,
            emoji=data.emoji,
            fun_fact=data.fun_fact,
            goal_category=data.goal_category,
            energy_level=data.energy_level,
        )
        db.add(challenge)
        await db.flush()
        await db.refresh(challenge)
        
        # Update streak
        await ChallengeService._update_streak(user_id, db)
        
        # Clear cache
        await redis_client.cache_delete("streak", user_id)
        
        return ChallengeHistoryResponse.model_validate(challenge)
    
    @staticmethod
    async def get_history(
        user_id: str,
        db: AsyncSession,
        page: int = 1,
        page_size: int = 20,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> ChallengeHistoryListResponse:
        """Get user challenge history with pagination."""
        cache_key = f"{user_id}:{page}:{page_size}:{start_date}:{end_date}"
        
        # Try cache first
        cached = await redis_client.cache_get("challenges", cache_key)
        if cached:
            # Parse cached response
            pass  # Return cached data
        
        # Build query
        query = select(ChallengeHistory).where(
            ChallengeHistory.user_id == user_id
        )
        
        if start_date:
            query = query.where(ChallengeHistory.completed_at >= start_date)
        if end_date:
            query = query.where(ChallengeHistory.completed_at <= end_date)
        
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        count_result = await db.execute(count_query)
        total = count_result.scalar() or 0
        
        # Add pagination
        query = query.order_by(ChallengeHistory.completed_at.desc())
        query = query.offset((page - 1) * page_size).limit(page_size)
        
        result = await db.execute(query)
        challenges = result.scalars().all()
        
        response = ChallengeHistoryListResponse(
            items=[ChallengeHistoryResponse.model_validate(c) for c in challenges],
            total=total,
            page=page,
            page_size=page_size,
        )
        
        # Cache response
        # await redis_client.cache_set("challenges", cache_key, response.model_dump_json(), 300)
        
        return response
    
    @staticmethod
    async def get_today_challenges(user_id: str, db: AsyncSession) -> list[ChallengeHistoryResponse]:
        """Get today's completed challenges."""
        today = date.today()
        
        result = await db.execute(
            select(ChallengeHistory)
            .where(ChallengeHistory.user_id == user_id)
            .where(func.date(ChallengeHistory.completed_at) == today)
            .order_by(ChallengeHistory.completed_at.desc())
        )
        challenges = result.scalars().all()
        
        return [ChallengeHistoryResponse.model_validate(c) for c in challenges]
    
    @staticmethod
    async def get_challenge_by_id(
        challenge_id: str,
        user_id: str,
        db: AsyncSession
    ) -> Optional[ChallengeHistoryResponse]:
        """Get a specific challenge by ID."""
        result = await db.execute(
            select(ChallengeHistory)
            .where(ChallengeHistory.id == challenge_id)
            .where(ChallengeHistory.user_id == user_id)
        )
        challenge = result.scalar_one_or_none()
        
        if challenge:
            return ChallengeHistoryResponse.model_validate(challenge)
        return None
    
    @staticmethod
    async def _update_streak(user_id: str, db: AsyncSession) -> None:
        """Update user streak after completing a challenge."""
        today = date.today()
        
        result = await db.execute(
            select(UserStreak).where(UserStreak.user_id == user_id)
        )
        streak = result.scalar_one_or_none()
        
        if not streak:
            # Create new streak record
            streak = UserStreak(
                user_id=user_id,
                current_streak=1,
                longest_streak=1,
                last_completed_date=today,
            )
            db.add(streak)
        else:
            # Update existing streak
            if streak.last_completed_date == today:
                # Already completed today, no change
                return
            
            if streak.last_completed_date == today - timedelta(days=1):
                # Consecutive day
                streak.current_streak += 1
            else:
                # Streak broken, start fresh
                streak.current_streak = 1
            
            # Update longest streak
            if streak.current_streak > streak.longest_streak:
                streak.longest_streak = streak.current_streak
            
            streak.last_completed_date = today
        
        await db.flush()
    
    @staticmethod
    async def get_streak_data(user_id: str, db: AsyncSession) -> UserStreak:
        """Get user streak data."""
        # Try cache first
        cached = await redis_client.cache_get("streak", user_id)
        if cached:
            # Parse cached data
            pass
        
        result = await db.execute(
            select(UserStreak).where(UserStreak.user_id == user_id)
        )
        streak = result.scalar_one_or_none()
        
        if streak:
            # Cache streak data
            await redis_client.cache_set(
                "streak",
                user_id,
                streak.model_dump_json(),
                ttl=300
            )
        
        return streak
