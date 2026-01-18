from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from datetime import date
from core.database import get_db
from services.challenge_service import ChallengeService
from services.achievement_service import AchievementService
from services.scheduler_service import SchedulerService
from schemas.schemas import (
    ChallengeHistoryCreate,
    ChallengeHistoryResponse,
    ChallengeHistoryListResponse,
    StreakResponse,
    StreakValidateResponse,
    ErrorResponse,
)
from api.auth import get_current_user
import asyncio


router = APIRouter(prefix="/challenges", tags=["Challenges"])


@router.post(
    "/complete",
    response_model=ChallengeHistoryResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def complete_challenge(
    data: ChallengeHistoryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Record a completed challenge."""
    # Complete the challenge
    challenge = await ChallengeService.complete_challenge(
        current_user["user_id"],
        data,
        db
    )
    
    # Check for new achievements (async)
    asyncio.create_task(
        _check_achievements_after_challenge(current_user["user_id"], db)
    )
    
    # Get updated streak for potential notification
    streak_data = await ChallengeService.get_streak_data(current_user["user_id"], db)
    if streak_data:
        asyncio.create_task(
            SchedulerService.schedule_streak_notification(
                current_user["user_id"],
                streak_data.current_streak,
            )
        )
    
    return challenge


async def _check_achievements_after_challenge(user_id: str, db: AsyncSession) -> None:
    """Check for new achievements after completing a challenge."""
    try:
        newly_unlocked = await AchievementService.check_and_unlock(user_id, db)
        
        # Send notifications for newly unlocked achievements
        for achievement in newly_unlocked:
            asyncio.create_task(
                SchedulerService.schedule_achievement_notification(
                    user_id,
                    achievement.title,
                    achievement.emoji,
                )
            )
    except Exception as e:
        print(f"❌ Error checking achievements: {e}")


@router.get(
    "/history",
    response_model=ChallengeHistoryListResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def get_challenge_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get user's challenge history with pagination."""
    return await ChallengeService.get_history(
        current_user["user_id"],
        db,
        page=page,
        page_size=page_size,
        start_date=start_date,
        end_date=end_date,
    )


@router.get(
    "/today",
    response_model=list[ChallengeHistoryResponse],
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def get_today_challenges(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get today's completed challenges."""
    return await ChallengeService.get_today_challenges(
        current_user["user_id"],
        db
    )


@router.get(
    "/history/{challenge_id}",
    response_model=ChallengeHistoryResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
        404: {"model": ErrorResponse, "description": "Challenge not found"},
    },
)
async def get_challenge_by_id(
    challenge_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get a specific challenge by ID."""
    challenge = await ChallengeService.get_challenge_by_id(
        challenge_id,
        current_user["user_id"],
        db
    )
    
    if not challenge:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Challenge not found",
        )
    
    return challenge
