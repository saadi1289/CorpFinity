from typing import List, Dict
from schemas.schemas import AchievementResponse, AchievementListResponse
from datetime import datetime


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
        db,
        streak_data: dict = None,
        challenge_count: int = 0,
    ) -> AchievementListResponse:
        """Get all achievements with unlock status."""
        achievements = []
        unlocked_count = 0
        
        for defn in ACHIEVEMENT_DEFINITIONS:
            is_unlocked = False
            unlocked_at = None
            
            # Check if achievement is unlocked based on type
            if defn["category"] == "streak" and streak_data:
                is_unlocked = streak_data.get("current_streak", 0) >= defn["requirement"]
            elif defn["category"] == "challenges":
                is_unlocked = challenge_count >= defn["requirement"]
            
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
        db,
        current_streak: int = 0,
        total_challenges: int = 0,
    ) -> List[AchievementResponse]:
        """Check and unlock new achievements. Returns newly unlocked achievements."""
        newly_unlocked = []
        
        for defn in ACHIEVEMENT_DEFINITIONS:
            should_unlock = False
            
            if defn["category"] == "streak":
                should_unlock = current_streak >= defn["requirement"]
            elif defn["category"] == "challenges":
                should_unlock = total_challenges >= defn["requirement"]
            
            if should_unlock:
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
    def get_achievement_definitions() -> List[Dict]:
        """Get all achievement definitions."""
        return ACHIEVEMENT_DEFINITIONS
