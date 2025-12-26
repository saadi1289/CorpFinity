from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import get_db
from services.notification_service import NotificationService
from schemas.schemas import (
    PushTokenCreate,
    PushTokenResponse,
    ErrorResponse,
)
from api.auth import get_current_user


router = APIRouter(prefix="/notifications", tags=["Push Notifications"])


@router.post(
    "/register",
    response_model=PushTokenResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def register_push_token(
    data: PushTokenCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Register a push notification token for the current user."""
    return await NotificationService.register_token(
        current_user["user_id"],
        data,
        db
    )


@router.delete(
    "/unregister",
    status_code=status.HTTP_200_OK,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
        404: {"model": ErrorResponse, "description": "Token not found"},
    },
)
async def unregister_push_token(
    token: str,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Unregister a push notification token."""
    success = await NotificationService.unregister_token(
        current_user["user_id"],
        token,
        db
    )
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Token not found",
        )
    
    return {"message": "Token unregistered successfully"}


@router.post(
    "/test",
    status_code=status.HTTP_200_OK,
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def test_notification(
    title: str = "CorpFinity",
    body: str = "This is a test notification from CorpFinity!",
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Send a test notification to the current user."""
    # Get user's push tokens
    tokens = await NotificationService.get_user_tokens(
        current_user["user_id"],
        db
    )
    
    if not tokens:
        return {
            "message": "No push tokens registered",
            "tokens_count": 0,
        }
    
    # In a real implementation, this would send via FCM/APNs
    # For now, just return success
    return {
        "message": "Test notification queued",
        "title": title,
        "body": body,
        "tokens_count": len(tokens),
    }
