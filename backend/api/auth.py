from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from core.database import get_db
from core.security import decode_token, verify_refresh_token
from core.redis import redis_client, get_redis
from services.auth_service import AuthService
from schemas.schemas import (
    UserRegister,
    UserLogin,
    TokenResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
    LogoutRequest,
    ErrorResponse,
)
from datetime import datetime


router = APIRouter(prefix="/auth", tags=["Authentication"])


async def get_current_user(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Dependency to get current authenticated user from JWT token."""
    auth_header = request.headers.get("Authorization")
    
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    token = auth_header.split(" ")[1]
    
    # Check if token is blacklisted
    if await redis_client.is_blacklisted(token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Decode token
    payload = decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return {"user_id": user_id, "payload": payload}


async def get_optional_user(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Dependency to get current user if token is present, otherwise return None."""
    auth_header = request.headers.get("Authorization")
    
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    
    token = auth_header.split(" ")[1]
    payload = decode_token(token)
    
    if payload:
        user_id = payload.get("sub")
        if user_id:
            return {"user_id": user_id, "payload": payload}
    
    return None


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    responses={
        400: {"model": ErrorResponse, "description": "Bad Request"},
        409: {"model": ErrorResponse, "description": "Email already registered"},
    },
)
async def register(
    data: UserRegister,
    db: AsyncSession = Depends(get_db),
):
    """Register a new user account."""
    try:
        return await AuthService.register(data, db)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e),
        )


@router.post(
    "/login",
    response_model=TokenResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Invalid credentials"},
    },
)
async def login(
    data: UserLogin,
    db: AsyncSession = Depends(get_db),
):
    """Authenticate user and return JWT tokens."""
    try:
        return await AuthService.login(data.email, data.password, db)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )


@router.post(
    "/refresh",
    response_model=RefreshTokenResponse,
    responses={
        401: {"model": ErrorResponse, "description": "Invalid refresh token"},
    },
)
async def refresh_token(
    data: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    """Refresh access token using refresh token."""
    try:
        token_response = await AuthService.refresh(data.refresh_token, db)
        return RefreshTokenResponse(
            access_token=token_response.access_token,
            refresh_token=token_response.refresh_token,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )


@router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
    responses={
        401: {"model": ErrorResponse, "description": "Invalid token"},
    },
)
async def logout(
    data: LogoutRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Logout and invalidate refresh token."""
    await AuthService.logout(data.refresh_token, db)
    
    # Optionally blacklist the access token too
    return {"message": "Successfully logged out"}


@router.post(
    "/logout-all",
    status_code=status.HTTP_200_OK,
)
async def logout_all_devices(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """Logout from all devices by revoking all refresh tokens."""
    count = await AuthService.revoke_all_tokens(current_user["user_id"], db)
    return {
        "message": f"Revoked {count} sessions",
        "devices_logged_out": count,
    }


@router.get(
    "/me",
    responses={
        401: {"model": ErrorResponse, "description": "Unauthorized"},
    },
)
async def get_current_user_info(
    current_user: dict = Depends(get_current_user),
):
    """Get information about the currently authenticated user."""
    return {
        "user_id": current_user["user_id"],
        "token_exp": datetime.fromtimestamp(current_user["payload"]["exp"]),
    }
