from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import get_db
from services.achievement_service import AchievementService
from services.challenge_service import ChallengeService
from services.streak_service import StreakService
from schemas.schemas import AchievementListResponse, ErrorResponse
from api.auth import get_current_user


router = APIRouter(prefix="/achievements", tags=["Achievements"])


@router.get(
    "",
    response_model=AchievementListResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def get_achievements(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get all achievements with unlock status."""
    # Get current streak data
    streak = await StreakService.get_streak(current_user["user_id"], db)
    
    # Get total challenge count
    history = await ChallengeService.get_history(
        current_user["user_id"],
        db,
        page=1,
        page_size=1,
    )
    
    return await AchievementService.get_achievements(
        current_user["user_id"],
        db,
        streak_data={
            "current_streak": streak.current_streak,
            "longest_streak": streak.longest_streak,
        },
        challenge_count=history.total,
    )


@router.post(
    "/check",
    response_model=AchievementListResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def check_achievements(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Check and unlock new achievements."""
    # Get current streak data
    streak = await StreakService.get_streak(current_user["user_id"], db)
    
    # Get total challenge count
    history = await ChallengeService.get_history(
        current_user["user_id"],
        db,
        page=1,
        page_size=1,
    )
    
    # Check for new achievements
    newly_unlocked = await AchievementService.check_and_unlock(
        current_user["user_id"],
        db,
        current_streak=streak.current_streak,
        total_challenges=history.total,
    )
    
    # Return updated achievement list
    return await AchievementService.get_achievements(
        current_user["user_id"],
        db,
        streak_data={
            "current_streak": streak.current_streak,
            "longest_streak": streak.longest_streak,
        },
        challenge_count=history.total,
    )
