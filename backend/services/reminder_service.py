from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from models.models import Reminder
from schemas.schemas import ReminderCreate, ReminderUpdate, ReminderResponse, ReminderListResponse
from core.redis import redis_client
from datetime import datetime
from typing import List
import uuid
import json


class ReminderService:
    """Service for reminder management."""
    
    @staticmethod
    async def create_reminder(
        user_id: str,
        data: ReminderCreate,
        db: AsyncSession
    ) -> ReminderResponse:
        """Create a new reminder."""
        reminder = Reminder(
            id=uuid.uuid4(),
            user_id=user_id,
            type=data.type,
            title=data.title,
            message=data.message,
            time_hour=data.time_hour,
            time_minute=data.time_minute,
            frequency=data.frequency,
            custom_days=data.custom_days or [],
            is_enabled=data.is_enabled,
        )
        db.add(reminder)
        await db.flush()
        await db.refresh(reminder)
        
        # Clear user's reminders cache
        await redis_client.cache_delete("reminders", user_id)
        
        return ReminderResponse.model_validate(reminder)
    
    @staticmethod
    async def get_reminders(
        user_id: str,
        db: AsyncSession,
        enabled_only: bool = False,
    ) -> ReminderListResponse:
        """Get all reminders for a user."""
        # Try cache first
        cache_key = f"{user_id}:{enabled_only}"
        cached = await redis_client.cache_get("reminders", cache_key)
        if cached:
            try:
                cached_data = json.loads(cached)
                return ReminderListResponse(**cached_data)
            except:
                pass  # Cache miss or invalid data
        
        query = select(Reminder).where(Reminder.user_id == user_id)
        
        if enabled_only:
            query = query.where(Reminder.is_enabled == True)
        
        query = query.order_by(Reminder.time_hour, Reminder.time_minute)
        
        result = await db.execute(query)
        reminders = result.scalars().all()
        
        response = ReminderListResponse(
            reminders=[ReminderResponse.model_validate(r) for r in reminders],
            total=len(reminders),
        )
        
        # Cache response
        await redis_client.cache_set(
            "reminders",
            cache_key,
            response.model_dump_json(),
            ttl=300
        )
        
        return response
    
    @staticmethod
    async def get_reminder_by_id(
        reminder_id: str,
        user_id: str,
        db: AsyncSession
    ) -> ReminderResponse:
        """Get a specific reminder by ID."""
        result = await db.execute(
            select(Reminder)
            .where(Reminder.id == reminder_id)
            .where(Reminder.user_id == user_id)
        )
        reminder = result.scalar_one_or_none()
        
        if not reminder:
            raise ValueError("Reminder not found")
        
        return ReminderResponse.model_validate(reminder)
    
    @staticmethod
    async def update_reminder(
        reminder_id: str,
        user_id: str,
        data: ReminderUpdate,
        db: AsyncSession
    ) -> ReminderResponse:
        """Update a reminder."""
        result = await db.execute(
            select(Reminder)
            .where(Reminder.id == reminder_id)
            .where(Reminder.user_id == user_id)
        )
        reminder = result.scalar_one_or_none()
        
        if not reminder:
            raise ValueError("Reminder not found")
        
        # Update fields
        if data.type is not None:
            reminder.type = data.type
        if data.title is not None:
            reminder.title = data.title
        if data.message is not None:
            reminder.message = data.message
        if data.time_hour is not None:
            reminder.time_hour = data.time_hour
        if data.time_minute is not None:
            reminder.time_minute = data.time_minute
        if data.frequency is not None:
            reminder.frequency = data.frequency
        if data.custom_days is not None:
            reminder.custom_days = data.custom_days
        if data.is_enabled is not None:
            reminder.is_enabled = data.is_enabled
        
        reminder.updated_at = datetime.utcnow()
        
        await db.flush()
        await db.refresh(reminder)
        
        # Clear cache
        await redis_client.cache_delete("reminders", user_id)
        await redis_client.cache_delete("reminders", f"{user_id}:True")
        
        return ReminderResponse.model_validate(reminder)
    
    @staticmethod
    async def delete_reminder(
        reminder_id: str,
        user_id: str,
        db: AsyncSession
    ) -> bool:
        """Delete a reminder."""
        result = await db.execute(
            select(Reminder)
            .where(Reminder.id == reminder_id)
            .where(Reminder.user_id == user_id)
        )
        reminder = result.scalar_one_or_none()
        
        if not reminder:
            return False
        
        await db.delete(reminder)
        
        # Clear cache
        await redis_client.cache_delete("reminders", user_id)
        await redis_client.cache_delete("reminders", f"{user_id}:True")
        
        return True
    
    @staticmethod
    async def toggle_reminder(
        reminder_id: str,
        user_id: str,
        db: AsyncSession
    ) -> ReminderResponse:
        """Toggle reminder enabled status."""
        result = await db.execute(
            select(Reminder)
            .where(Reminder.id == reminder_id)
            .where(Reminder.user_id == user_id)
        )
        reminder = result.scalar_one_or_none()
        
        if not reminder:
            raise ValueError("Reminder not found")
        
        reminder.is_enabled = not reminder.is_enabled
        reminder.updated_at = datetime.utcnow()
        
        await db.flush()
        await db.refresh(reminder)
        
        # Clear cache
        await redis_client.cache_delete("reminders", user_id)
        await redis_client.cache_delete("reminders", f"{user_id}:True")
        
        return ReminderResponse.model_validate(reminder)
    
    @staticmethod
    async def get_enabled_reminders(user_id: str, db: AsyncSession) -> List[ReminderResponse]:
        """Get all enabled reminders for scheduling."""
        result = await db.execute(
            select(Reminder)
            .where(Reminder.user_id == user_id)
            .where(Reminder.is_enabled == True)
            .order_by(Reminder.time_hour, Reminder.time_minute)
        )
        reminders = result.scalars().all()
        
        return [ReminderResponse.model_validate(r) for r in reminders]
