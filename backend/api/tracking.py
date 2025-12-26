from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from datetime import date
from core.database import get_db
from services.tracking_service import TrackingService
from schemas.schemas import (
    DailyTrackingResponse,
    DailyTrackingUpdate,
    TrackingHistoryResponse,
    ErrorResponse,
)
from api.auth import get_current_user


router = APIRouter(prefix="/tracking", tags=["Daily Tracking"])


@router.get(
    "/today",
    response_model=DailyTrackingResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def get_today_tracking(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get today's tracking data."""
    return await TrackingService.get_today(current_user["user_id"], db)


@router.patch(
    "/today",
    response_model=DailyTrackingResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def update_today_tracking(
    data: DailyTrackingUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Update today's tracking data."""
    return await TrackingService.update_today(current_user["user_id"], data, db)


@router.post(
    "/water",
    response_model=DailyTrackingResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def increment_water(
    amount: int = Query(250, ge=1, le=1000, description="Amount in ml to add"),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Increment water intake by the specified amount."""
    return await TrackingService.increment_water(
        current_user["user_id"],
        amount=amount,
        db=db
    )


@router.post(
    "/mood",
    response_model=DailyTrackingResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def set_mood(
    mood: str = Query(..., description="Mood value"),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Set today's mood."""
    return await TrackingService.set_mood(
        current_user["user_id"],
        mood=mood,
        db=db
    )


@router.get(
    "/history",
    response_model=TrackingHistoryResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def get_tracking_history(
    start_date: date = Query(..., description="Start date (YYYY-MM-DD)"),
    end_date: date = Query(..., description="End date (YYYY-MM-DD)"),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get tracking history for a date range."""
    return await TrackingService.get_history(
        current_user["user_id"],
        db,
        start_date=start_date,
        end_date=end_date,
    )
