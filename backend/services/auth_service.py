from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from models.models import User, RefreshToken
from core.security import hash_password, verify_password, create_access_token, create_refresh_token
from schemas.schemas import UserRegister, TokenResponse, UserResponse
from core.redis import redis_client
from datetime import datetime, timedelta
import json


class AuthService:
    """Authentication service for user registration and login."""
    
    @staticmethod
    def _serialize_user(user: User) -> str:
        """Serialize user to JSON string."""
        return json.dumps({
            "id": str(user.id),
            "email": user.email,
            "name": user.name,
            "avatar_seed": user.avatar_seed,
            "created_at": user.created_at.isoformat() if user.created_at else None,
            "updated_at": user.updated_at.isoformat() if user.updated_at else None,
            "is_active": user.is_active,
        })
    
    @staticmethod
    async def register(data: UserRegister, db: AsyncSession) -> TokenResponse:
        """Register a new user."""
        existing = await db.execute(
            select(User).where(User.email == data.email)
        )
        if existing.scalar_one_or_none():
            raise ValueError("Email already registered")
        
        user = User(
            email=data.email,
            password_hash=hash_password(data.password),
            name=data.name,
            avatar_seed=data.email,
        )
        db.add(user)
        await db.flush()
        await db.refresh(user)
        
        access_token = create_access_token(data={"sub": str(user.id)})
        refresh_token = create_refresh_token(data={"sub": str(user.id)})
        
        token_hash = hash_password(refresh_token)
        expires_at = datetime.utcnow() + timedelta(days=7)
        refresh_token_entry = RefreshToken(
            user_id=user.id,
            token_hash=token_hash,
            expires_at=expires_at,
        )
        db.add(refresh_token_entry)
        
        await redis_client.cache_set(
            "user",
            str(user.id),
            AuthService._serialize_user(user),
            ttl=3600
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserResponse.model_validate(user),
        )
    
    @staticmethod
    async def login(email: str, password: str, db: AsyncSession) -> TokenResponse:
        """Authenticate user and return tokens."""
        result = await db.execute(
            select(User).where(User.email == email)
        )
        user = result.scalar_one_or_none()
        
        if not user or not verify_password(password, user.password_hash):
            raise ValueError("Invalid email or password")
        
        if not user.is_active:
            raise ValueError("Account is deactivated")
        
        access_token = create_access_token(data={"sub": str(user.id)})
        refresh_token = create_refresh_token(data={"sub": str(user.id)})
        
        token_hash = hash_password(refresh_token)
        expires_at = datetime.utcnow() + timedelta(days=7)
        refresh_token_entry = RefreshToken(
            user_id=user.id,
            token_hash=token_hash,
            expires_at=expires_at,
        )
        db.add(refresh_token_entry)
        
        await redis_client.cache_set(
            "user",
            str(user.id),
            AuthService._serialize_user(user),
            ttl=3600
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserResponse.model_validate(user),
        )
    
    @staticmethod
    async def refresh(refresh_token: str, db: AsyncSession) -> TokenResponse:
        """Refresh access token using refresh token."""
        result = await db.execute(
            select(RefreshToken)
            .where(RefreshToken.token_hash == hash_password(refresh_token))
            .options(selectinload(RefreshToken.user))
        )
        token_entry = result.scalar_one_or_none()
        
        if not token_entry or token_entry.revoked:
            raise ValueError("Invalid refresh token")
        
        if token_entry.expires_at < datetime.utcnow():
            raise ValueError("Refresh token expired")
        
        user = token_entry.user
        token_entry.revoked = True
        
        access_token = create_access_token(data={"sub": str(user.id)})
        new_refresh_token = create_refresh_token(data={"sub": str(user.id)})
        
        new_token_hash = hash_password(new_refresh_token)
        expires_at = datetime.utcnow() + timedelta(days=7)
        new_token_entry = RefreshToken(
            user_id=user.id,
            token_hash=new_token_hash,
            expires_at=expires_at,
        )
        db.add(new_token_entry)
        
        await redis_client.cache_set(
            "user",
            str(user.id),
            AuthService._serialize_user(user),
            ttl=3600
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=new_refresh_token,
            user=UserResponse.model_validate(user),
        )
    
    @staticmethod
    async def logout(refresh_token: str, db: AsyncSession) -> bool:
        """Logout and invalidate refresh token."""
        result = await db.execute(
            select(RefreshToken)
            .where(RefreshToken.token_hash == hash_password(refresh_token))
        )
        token_entry = result.scalar_one_or_none()
        
        if token_entry:
            token_entry.revoked = True
            return True
        
        return False
    
    @staticmethod
    async def revoke_all_tokens(user_id: str, db: AsyncSession) -> int:
        """Revoke all refresh tokens for a user."""
        result = await db.execute(
            select(RefreshToken)
            .where(RefreshToken.user_id == user_id)
            .where(RefreshToken.revoked == False)
        )
        tokens = result.scalars().all()
        
        for token in tokens:
            token.revoked = True
        
        return len(tokens)
