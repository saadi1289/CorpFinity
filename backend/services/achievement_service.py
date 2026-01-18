from typing import List, Dict
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from models.models import UserAchievement, AchievementDefinition, UserStreak, ChallengeHistory
from schemas.schemas import AchievementResponse, AchievementListResponse
from core.redis import redis_client
from datetime import datetime
import json


# Static achievement definitions matching Flutter app
ACHIEVEMENT_DEFINITIONS = [
    {
        "id": "streak_3",
        "title": "Getting Started",
        "description": "Maintain a 3-day streak",
        "emoji": "🌱",
        "category": "streak",
        "requirement": 3,
    },
    {
        "id": "streak_7",
        "title": "Week Warrior",
        "description": "Maintain a 7-day streak",
        "emoji": "🔥",
        "category": "streak",
        "requirement": 7,
    },
    {
        "id": "streak_30",
        "title": "Monthly Master",
        "description": "Maintain a 30-day streak",
        "emoji": "⭐",
        "category": "streak",
        "requirement": 30,
    },
    {
        "id": "streak_100",
        "title": "Century Club",
        "description": "Maintain a 100-day streak",
        "emoji": "👑",
        "category": "streak",
        "requirement": 100,
    },
    {
        "id": "challenges_5",
        "title": "First Steps",
        "description": "Complete 5 challenges",
        "emoji": "🎯",
        "category": "challenges",
        "requirement": 5,
    },
    {
        "id": "challenges_25",
        "title": "Dedicated",
        "description": "Complete 25 challenges",
        "emoji": "💪",
        "category": "challenges",
        "requirement": 25,
    },
    {
        "id": "challenges_50",
        "title": "Wellness Pro",
        "description": "Complete 50 challenges",
        "emoji": "🏆",
        "category": "challenges",
        "requirement": 50,
    },
    {
        "id": "challenges_100",
        "title": "Legend",
        "description": "Complete 100 challenges",
        "emoji": "🌟",
        "category": "challenges",
        "requirement": 100,
    },
]


class AchievementService:
    """Service for achievements."""
    
    @staticmethod
    async def get_achievements(
        user_id: str,
        db: AsyncSession,
    ) -> AchievementListResponse:
        """Get all achievements with unlock status."""
        # Get user's unlocked achievements
        unlocked_result = await db.execute(
            select(UserAchievement)
            .where(UserAchievement.user_id == user_id)
        )
        unlocked_achievements = {ua.achievement_id: ua.unlocked_at for ua in unlocked_result.scalars().all()}
        
        # Get user stats for checking unlock conditions
        streak_result = await db.execute(
            select(UserStreak).where(UserStreak.user_id == user_id)
        )
        streak = streak_result.scalar_one_or_none()
        current_streak = streak.current_streak if streak else 0
        longest_streak = streak.longest_streak if streak else 0
        
        challenge_count_result = await db.execute(
            select(func.count(ChallengeHistory.id))
            .where(ChallengeHistory.user_id == user_id)
        )
        challenge_count = challenge_count_result.scalar() or 0
        
        achievements = []
        unlocked_count = 0
        
        for defn in ACHIEVEMENT_DEFINITIONS:
            is_unlocked = defn["id"] in unlocked_achievements
            unlocked_at = unlocked_achievements.get(defn["id"])
            
            # Check if should be unlocked but isn't yet
            should_unlock = False
            if defn["category"] == "streak":
                should_unlock = longest_streak >= defn["requirement"]
            elif defn["category"] == "challenges":
                should_unlock = challenge_count >= defn["requirement"]
            
            # Auto-unlock if conditions are met
            if should_unlock and not is_unlocked:
                await AchievementService._unlock_achievement(user_id, defn["id"], db)
                is_unlocked = True
                unlocked_at = datetime.utcnow()
            
            if is_unlocked:
                unlocked_count += 1
            
            achievements.append(AchievementResponse(
                id=defn["id"],
                title=defn["title"],
                description=defn["description"],
                emoji=defn["emoji"],
                category=defn["category"],
                requirement=defn["requirement"],
                is_unlocked=is_unlocked,
                unlocked_at=unlocked_at,
            ))
        
        return AchievementListResponse(
            achievements=achievements,
            unlocked_count=unlocked_count,
            total_count=len(ACHIEVEMENT_DEFINITIONS),
        )
    
    @staticmethod
    async def check_and_unlock(
        user_id: str,
        db: AsyncSession,
    ) -> List[AchievementResponse]:
        """Check and unlock new achievements. Returns newly unlocked achievements."""
        # Get current user stats
        streak_result = await db.execute(
            select(UserStreak).where(UserStreak.user_id == user_id)
        )
        streak = streak_result.scalar_one_or_none()
        current_streak = streak.current_streak if streak else 0
        longest_streak = streak.longest_streak if streak else 0
        
        challenge_count_result = await db.execute(
            select(func.count(ChallengeHistory.id))
            .where(ChallengeHistory.user_id == user_id)
        )
        total_challenges = challenge_count_result.scalar() or 0
        
        # Get already unlocked achievements
        unlocked_result = await db.execute(
            select(UserAchievement.achievement_id)
            .where(UserAchievement.user_id == user_id)
        )
        unlocked_ids = set(unlocked_result.scalars().all())
        
        newly_unlocked = []
        
        for defn in ACHIEVEMENT_DEFINITIONS:
            if defn["id"] in unlocked_ids:
                continue  # Already unlocked
            
            should_unlock = False
            
            if defn["category"] == "streak":
                should_unlock = longest_streak >= defn["requirement"]
            elif defn["category"] == "challenges":
                should_unlock = total_challenges >= defn["requirement"]
            
            if should_unlock:
                # Unlock achievement
                await AchievementService._unlock_achievement(user_id, defn["id"], db)
                
                newly_unlocked.append(AchievementResponse(
                    id=defn["id"],
                    title=defn["title"],
                    description=defn["description"],
                    emoji=defn["emoji"],
                    category=defn["category"],
                    requirement=defn["requirement"],
                    is_unlocked=True,
                    unlocked_at=datetime.utcnow(),
                ))
        
        return newly_unlocked
    
    @staticmethod
    async def _unlock_achievement(user_id: str, achievement_id: str, db: AsyncSession) -> None:
        """Unlock an achievement for a user."""
        # Check if already unlocked
        existing = await db.execute(
            select(UserAchievement)
            .where(UserAchievement.user_id == user_id)
            .where(UserAchievement.achievement_id == achievement_id)
        )
        
        if existing.scalar_one_or_none():
            return  # Already unlocked
        
        # Create achievement unlock record
        user_achievement = UserAchievement(
            user_id=user_id,
            achievement_id=achievement_id,
        )
        db.add(user_achievement)
        await db.flush()
    
    @staticmethod
    def get_achievement_definitions() -> List[Dict]:
        """Get all achievement definitions."""
        return ACHIEVEMENT_DEFINITIONS
    
    @staticmethod
    async def seed_achievement_definitions(db: AsyncSession) -> None:
        """Seed achievement definitions into database."""
        for defn in ACHIEVEMENT_DEFINITIONS:
            # Check if already exists
            existing = await db.execute(
                select(AchievementDefinition)
                .where(AchievementDefinition.id == defn["id"])
            )
            
            if not existing.scalar_one_or_none():
                achievement_def = AchievementDefinition(
                    id=defn["id"],
                    title=defn["title"],
                    description=defn["description"],
                    emoji=defn["emoji"],
                    category=defn["category"],
                    requirement=defn["requirement"],
                )
                db.add(achievement_def)
        
        await db.flush()
