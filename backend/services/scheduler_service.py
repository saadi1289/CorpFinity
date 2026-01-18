"""
Scheduler service for background jobs like reminder notifications.
This service handles scheduling and sending reminder notifications.
"""

import asyncio
from datetime import datetime, time, timedelta
from typing import List, Dict, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from core.database import AsyncSessionLocal
from services.reminder_service import ReminderService
from services.notification_service import NotificationService
from models.models import Reminder
import logging

logger = logging.getLogger(__name__)


class SchedulerService:
    """Service for scheduling background tasks like reminder notifications."""
    
    _instance: Optional["SchedulerService"] = None
    _running: bool = False
    _task: Optional[asyncio.Task] = None
    
    def __new__(cls) -> "SchedulerService":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    async def start(self) -> None:
        """Start the scheduler service."""
        if self._running:
            return
        
        self._running = True
        self._task = asyncio.create_task(self._scheduler_loop())
        logger.info("✅ Scheduler service started")
    
    async def stop(self) -> None:
        """Stop the scheduler service."""
        if not self._running:
            return
        
        self._running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        
        logger.info("✅ Scheduler service stopped")
    
    async def _scheduler_loop(self) -> None:
        """Main scheduler loop that runs every minute."""
        while self._running:
            try:
                await self._check_and_send_reminders()
                # Wait for next minute
                await asyncio.sleep(60)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"❌ Scheduler error: {e}")
                await asyncio.sleep(60)  # Continue after error
    
    async def _check_and_send_reminders(self) -> None:
        """Check for due reminders and send notifications."""
        now = datetime.now()
        current_time = now.time()
        current_weekday = now.weekday()  # 0=Monday, 6=Sunday
        
        async with AsyncSessionLocal() as db:
            try:
                # Get all enabled reminders
                all_users_reminders = await self._get_all_enabled_reminders(db)
                
                for user_id, reminders in all_users_reminders.items():
                    for reminder in reminders:
                        if self._should_send_reminder(reminder, current_time, current_weekday):
                            await self._send_reminder_notification(user_id, reminder, db)
                
            except Exception as e:
                logger.error(f"❌ Error checking reminders: {e}")
    
    async def _get_all_enabled_reminders(self, db: AsyncSession) -> Dict[str, List[Reminder]]:
        """Get all enabled reminders grouped by user."""
        from sqlalchemy import select
        
        result = await db.execute(
            select(Reminder)
            .where(Reminder.is_enabled == True)
        )
        reminders = result.scalars().all()
        
        # Group by user
        user_reminders = {}
        for reminder in reminders:
            user_id = str(reminder.user_id)
            if user_id not in user_reminders:
                user_reminders[user_id] = []
            user_reminders[user_id].append(reminder)
        
        return user_reminders
    
    def _should_send_reminder(
        self, 
        reminder: Reminder, 
        current_time: time, 
        current_weekday: int
    ) -> bool:
        """Check if a reminder should be sent now."""
        reminder_time = time(reminder.time_hour, reminder.time_minute)
        
        # Check if it's the right time (within 1 minute window)
        time_diff = abs(
            (current_time.hour * 60 + current_time.minute) - 
            (reminder_time.hour * 60 + reminder_time.minute)
        )
        
        if time_diff > 1:  # Not within 1-minute window
            return False
        
        # Check frequency
        if reminder.frequency == "daily":
            return True
        elif reminder.frequency == "weekdays":
            return current_weekday < 5  # Monday-Friday
        elif reminder.frequency == "custom":
            # Custom days: 0=Sunday, 1=Monday, ..., 6=Saturday
            # Convert from Python weekday (0=Monday) to custom format
            custom_weekday = (current_weekday + 1) % 7
            return custom_weekday in (reminder.custom_days or [])
        
        return False
    
    async def _send_reminder_notification(
        self, 
        user_id: str, 
        reminder: Reminder, 
        db: AsyncSession
    ) -> None:
        """Send a reminder notification to the user."""
        try:
            result = await NotificationService.send_reminder_notification(
                user_id, reminder, db
            )
            
            if result.get("success", 0) > 0:
                logger.info(f"✅ Sent reminder '{reminder.title}' to user {user_id}")
            elif result.get("local", 0) > 0:
                logger.info(f"📱 Local reminder '{reminder.title}' for user {user_id}")
            else:
                logger.warning(f"⚠️ Failed to send reminder '{reminder.title}' to user {user_id}: {result}")
        
        except Exception as e:
            logger.error(f"❌ Error sending reminder notification: {e}")
    
    @staticmethod
    async def schedule_immediate_reminder(
        user_id: str, 
        title: str, 
        message: str, 
        delay_seconds: int = 0
    ) -> None:
        """Schedule an immediate one-time reminder."""
        if delay_seconds > 0:
            await asyncio.sleep(delay_seconds)
        
        async with AsyncSessionLocal() as db:
            try:
                result = await NotificationService.send_notification(
                    user_id, title, message, {"type": "immediate"}, db
                )
                logger.info(f"✅ Sent immediate reminder to user {user_id}: {result}")
            except Exception as e:
                logger.error(f"❌ Error sending immediate reminder: {e}")
    
    @staticmethod
    async def schedule_achievement_notification(
        user_id: str, 
        achievement_title: str, 
        achievement_emoji: str,
        delay_seconds: int = 2
    ) -> None:
        """Schedule an achievement notification with a small delay."""
        if delay_seconds > 0:
            await asyncio.sleep(delay_seconds)
        
        async with AsyncSessionLocal() as db:
            try:
                result = await NotificationService.send_achievement_notification(
                    user_id, achievement_title, achievement_emoji, db
                )
                logger.info(f"✅ Sent achievement notification to user {user_id}: {result}")
            except Exception as e:
                logger.error(f"❌ Error sending achievement notification: {e}")
    
    @staticmethod
    async def schedule_streak_notification(
        user_id: str, 
        streak_count: int,
        delay_seconds: int = 1
    ) -> None:
        """Schedule a streak milestone notification."""
        # Only send for milestone streaks
        if streak_count not in [3, 7, 14, 30, 50, 100]:
            return
        
        if delay_seconds > 0:
            await asyncio.sleep(delay_seconds)
        
        async with AsyncSessionLocal() as db:
            try:
                result = await NotificationService.send_streak_notification(
                    user_id, streak_count, db
                )
                logger.info(f"✅ Sent streak notification to user {user_id}: {result}")
            except Exception as e:
                logger.error(f"❌ Error sending streak notification: {e}")


# Global scheduler instance
scheduler_service = SchedulerService()


async def start_scheduler() -> None:
    """Start the global scheduler service."""
    await scheduler_service.start()


async def stop_scheduler() -> None:
    """Stop the global scheduler service."""
    await scheduler_service.stop()