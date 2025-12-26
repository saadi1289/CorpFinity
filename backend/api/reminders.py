from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from core.database import get_db
from services.reminder_service import ReminderService
from schemas.schemas import (
    ReminderCreate,
    ReminderUpdate,
    ReminderResponse,
    ReminderListResponse,
    ErrorResponse,
)
from api.auth import get_current_user


router = APIRouter(prefix="/reminders", tags=["Reminders"])


@router.get(
    "",
    response_model=ReminderListResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def get_reminders(
    enabled_only: bool = Query(False, description="Only return enabled reminders"),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get all reminders for the current user."""
    return await ReminderService.get_reminders(
        current_user["user_id"],
        db,
        enabled_only=enabled_only,
    )


@router.post(
    "",
    response_model=ReminderResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def create_reminder(
    data: ReminderCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Create a new reminder."""
    return await ReminderService.create_reminder(
        current_user["user_id"],
        data,
        db
    )


@router.get(
    "/{reminder_id}",
    response_model=ReminderResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
        404: {"model": ErrorResponse, "description": "Reminder not found"},
    },
)
async def get_reminder_by_id(
    reminder_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Get a specific reminder by ID."""
    try:
        return await ReminderService.get_reminder_by_id(
            reminder_id,
            current_user["user_id"],
            db
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )


@router.patch(
    "/{reminder_id}",
    response_model=ReminderResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
        404: {"model": ErrorResponse, "description": "Reminder not found"},
    },
)
async def update_reminder(
    reminder_id: str,
    data: ReminderUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Update a reminder."""
    try:
        return await ReminderService.update_reminder(
            reminder_id,
            current_user["user_id"],
            data,
            db
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )


@router.delete(
    "/{reminder_id}",
    status_code=status.HTTP_200_OK,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
        404: {"model": ErrorResponse, "description": "Reminder not found"},
    },
)
async def delete_reminder(
    reminder_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Delete a reminder."""
    success = await ReminderService.delete_reminder(
        reminder_id,
        current_user["user_id"],
        db
    )
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reminder not found",
        )
    
    return {"message": "Reminder deleted successfully"}


@router.post(
    "/{reminder_id}/toggle",
    response_model=ReminderResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
        404: {"model": ErrorResponse, "description": "Reminder not found"},
    },
)
async def toggle_reminder(
    reminder_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Toggle reminder enabled status."""
    try:
        return await ReminderService.toggle_reminder(
            reminder_id,
            current_user["user_id"],
            db
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )
