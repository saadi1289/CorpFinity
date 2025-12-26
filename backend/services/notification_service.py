from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from models.models import PushToken
from schemas.schemas import PushTokenCreate, PushTokenResponse
from core.redis import redis_client
import uuid


class NotificationService:
    """Service for push notification token management."""
    
    @staticmethod
    async def register_token(
        user_id: str,
        data: PushTokenCreate,
        db: AsyncSession
    ) -> PushTokenResponse:
        """Register a push notification token."""
        # Check if token already exists
        result = await db.execute(
            select(PushToken)
            .where(PushToken.token == data.token)
            .where(PushToken.user_id == user_id)
        )
        existing = result.scalar_one_or_none()
        
        if existing:
            # Token already registered for this user
            return PushTokenResponse.model_validate(existing)
        
        # Create new token entry
        token = PushToken(
            id=uuid.uuid4(),
            user_id=user_id,
            token=data.token,
            platform=data.platform,
        )
        db.add(token)
        await db.flush()
        await db.refresh(token)
        
        return PushTokenResponse.model_validate(token)
    
    @staticmethod
    async def unregister_token(
        user_id: str,
        token: str,
        db: AsyncSession
    ) -> bool:
        """Unregister a push notification token."""
        result = await db.execute(
            select(PushToken)
            .where(PushToken.token == token)
            .where(PushToken.user_id == user_id)
        )
        token_entry = result.scalar_one_or_none()
        
        if not token_entry:
            return False
        
        await db.delete(token_entry)
        return True
    
    @staticmethod
    async def get_user_tokens(user_id: str, db: AsyncSession) -> list[str]:
        """Get all push tokens for a user."""
        result = await db.execute(
            select(PushToken.token)
            .where(PushToken.user_id == user_id)
        )
        tokens = result.scalars().all()
        return list(tokens)
    
    @staticmethod
    async def get_tokens_by_platform(
        user_id: str,
        platform: str,
        db: AsyncSession
    ) -> list[str]:
        """Get all push tokens for a user on a specific platform."""
        result = await db.execute(
            select(PushToken.token)
            .where(PushToken.user_id == user_id)
            .where(PushToken.platform == platform)
        )
        tokens = result.scalars().all()
        return list(tokens)
    
    @staticmethod
    async def delete_all_user_tokens(user_id: str, db: AsyncSession) -> int:
        """Delete all push tokens for a user."""
        result = await db.execute(
            select(PushToken)
            .where(PushToken.user_id == user_id)
        )
        tokens = result.scalars().all()
        
        for token in tokens:
            await db.delete(token)
        
        return len(tokens)
