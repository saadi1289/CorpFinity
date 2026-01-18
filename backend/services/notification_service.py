from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from models.models import PushToken, User, Reminder
from schemas.schemas import PushTokenCreate, PushTokenResponse
from core.redis import redis_client
from core.config import settings
import uuid
import asyncio
from typing import List, Dict, Optional
import json

# Firebase Admin SDK (optional - for push notifications)
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False


class NotificationService:
    """Service for push notification token management and sending."""
    
    _firebase_app = None
    
    @classmethod
    def initialize_firebase(cls):
        """Initialize Firebase Admin SDK if available."""
        if not FIREBASE_AVAILABLE:
            print("⚠️ Firebase Admin SDK not available. Push notifications disabled.")
            return
        
        if not cls._firebase_app:
            try:
                # Initialize Firebase Admin SDK
                # In production, use service account key file or environment variables
                cls._firebase_app = firebase_admin.initialize_app()
                print("✅ Firebase Admin SDK initialized")
            except Exception as e:
                print(f"❌ Failed to initialize Firebase: {e}")
    
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
    async def get_user_tokens(user_id: str, db: AsyncSession) -> List[str]:
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
    ) -> List[str]:
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
    
    @staticmethod
    async def send_notification(
        user_id: str,
        title: str,
        body: str,
        data: Optional[Dict] = None,
        db: AsyncSession = None
    ) -> Dict[str, int]:
        """Send push notification to all user's devices."""
        if not FIREBASE_AVAILABLE or not NotificationService._firebase_app:
            print(f"📱 Local notification: {title} - {body}")
            return {"success": 0, "failure": 0, "local": 1}
        
        if not db:
            return {"success": 0, "failure": 0, "error": "Database session required"}
        
        # Get user tokens
        tokens = await NotificationService.get_user_tokens(user_id, db)
        
        if not tokens:
            return {"success": 0, "failure": 0, "no_tokens": 1}
        
        # Create message
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            tokens=tokens,
        )
        
        try:
            # Send notification
            response = messaging.send_multicast(message)
            
            # Handle failed tokens (remove invalid ones)
            if response.failure_count > 0:
                failed_tokens = []
                for idx, resp in enumerate(response.responses):
                    if not resp.success:
                        failed_tokens.append(tokens[idx])
                
                # Remove invalid tokens from database
                if failed_tokens:
                    await db.execute(
                        select(PushToken)
                        .where(PushToken.user_id == user_id)
                        .where(PushToken.token.in_(failed_tokens))
                    )
                    for token in failed_tokens:
                        await NotificationService.unregister_token(user_id, token, db)
            
            return {
                "success": response.success_count,
                "failure": response.failure_count,
            }
        
        except Exception as e:
            print(f"❌ Failed to send notification: {e}")
            return {"success": 0, "failure": len(tokens), "error": str(e)}
    
    @staticmethod
    async def send_reminder_notification(
        user_id: str,
        reminder: Reminder,
        db: AsyncSession
    ) -> Dict[str, int]:
        """Send a reminder notification."""
        title = reminder.title
        body = reminder.message or f"Time for your {reminder.type} reminder!"
        
        data = {
            "type": "reminder",
            "reminder_id": str(reminder.id),
            "reminder_type": reminder.type,
        }
        
        return await NotificationService.send_notification(
            user_id, title, body, data, db
        )
    
    @staticmethod
    async def send_achievement_notification(
        user_id: str,
        achievement_title: str,
        achievement_emoji: str,
        db: AsyncSession
    ) -> Dict[str, int]:
        """Send achievement unlock notification."""
        title = f"Achievement Unlocked! {achievement_emoji}"
        body = f"Congratulations! You've earned '{achievement_title}'"
        
        data = {
            "type": "achievement",
            "achievement_title": achievement_title,
        }
        
        return await NotificationService.send_notification(
            user_id, title, body, data, db
        )
    
    @staticmethod
    async def send_streak_notification(
        user_id: str,
        streak_count: int,
        db: AsyncSession
    ) -> Dict[str, int]:
        """Send streak milestone notification."""
        title = f"🔥 {streak_count}-Day Streak!"
        body = f"Amazing! You're on a {streak_count}-day wellness streak. Keep it up!"
        
        data = {
            "type": "streak",
            "streak_count": str(streak_count),
        }
        
        return await NotificationService.send_notification(
            user_id, title, body, data, db
        )
    
    @staticmethod
    async def send_test_notification(
        user_id: str,
        db: AsyncSession
    ) -> Dict[str, int]:
        """Send a test notification."""
        title = "CorpFinity Test"
        body = "This is a test notification from CorpFinity!"
        
        data = {
            "type": "test",
            "timestamp": str(int(asyncio.get_event_loop().time())),
        }
        
        return await NotificationService.send_notification(
            user_id, title, body, data, db
        )


# Initialize Firebase on module import
NotificationService.initialize_firebase()
