from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import get_db
from services.achievement_service import AchievementService
from services.scheduler_service import SchedulerService
from schemas.schemas import AchievementListResponse, ErrorResponse
from api.auth import get_current_user
import asyncio


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
    return await AchievementService.get_achievements(
        current_user["user_id"],
        db,
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
    # Check for new achievements
    newly_unlocked = await AchievementService.check_and_unlock(
        current_user["user_id"],
        db,
    )
    
    # Send notifications for newly unlocked achievements
    for achievement in newly_unlocked:
        asyncio.create_task(
            SchedulerService.schedule_achievement_notification(
                current_user["user_id"],
                achievement.title,
                achievement.emoji,
            )
        )
    
    # Return updated achievement list
    return await AchievementService.get_achievements(
        current_user["user_id"],
        db,
    )
