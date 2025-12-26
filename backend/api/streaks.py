from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import get_db
from services.streak_service import StreakService
from schemas.schemas import StreakResponse, StreakValidateResponse, ErrorResponse
from api.auth import get_current_user


router = APIRouter(prefix="/streaks", tags=["Streaks"])


@router.get(
    "",
    response_model=StreakResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def get_streak(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get current streak information."""
    return await StreakService.get_streak(current_user["user_id"], db)


@router.post(
    "/validate",
    response_model=StreakValidateResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def validate_streak(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Validate and update streak based on today's activity."""
    return await StreakService.validate_streak(current_user["user_id"], db)


@router.post(
    "/reset",
    response_model=StreakResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def reset_streak(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Reset user streak (for self-service or admin)."""
    return await StreakService.reset_streak(current_user["user_id"], db)
