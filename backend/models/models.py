from sqlalchemy import Column, String, Integer, Boolean, DateTime, Date, Text, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid
from core.database import Base


class User(Base):
    """User model for authentication and profile."""
    
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    name = Column(String(100), nullable=False)
    avatar_seed = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    
    # Relationships
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    challenges = relationship("ChallengeHistory", back_populates="user", cascade="all, delete-orphan")
    streak = relationship("UserStreak", back_populates="user", uselist=False, cascade="all, delete-orphan")
    achievements = relationship("UserAchievement", back_populates="user", cascade="all, delete-orphan")
    reminders = relationship("Reminder", back_populates="user", cascade="all, delete-orphan")
    push_tokens = relationship("PushToken", back_populates="user", cascade="all, delete-orphan")
    daily_tracking = relationship("DailyTracking", back_populates="user", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, name={self.name})>"


class RefreshToken(Base):
    """Refresh token model for session management."""
    
    __tablename__ = "refresh_tokens"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token_hash = Column(String(255), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    revoked = Column(Boolean, default=False)
    
    # Relationships
    user = relationship("User", back_populates="refresh_tokens")
    
    __table_args__ = (
        Index("idx_refresh_token_hash", "token_hash"),
        Index("idx_refresh_user_expires", "user_id", "expires_at"),
    )
    
    def __repr__(self):
        return f"<RefreshToken(id={self.id}, user_id={self.user_id})>"


class ChallengeHistory(Base):
    """Challenge completion history."""
    
    __tablename__ = "challenge_history"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    duration = Column(String(50), nullable=True)
    emoji = Column(String(10), nullable=True)
    fun_fact = Column(Text, nullable=True)
    goal_category = Column(String(50), nullable=True)
    energy_level = Column(String(20), nullable=True)
    completed_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="challenges")
    
    __table_args__ = (
        Index("idx_challenge_user_completed", "user_id", "completed_at"),
    )
    
    def __repr__(self):
        return f"<ChallengeHistory(id={self.id}, user_id={self.user_id}, title={self.title})>"


class UserStreak(Base):
    """User streak tracking."""
    
    __tablename__ = "user_streaks"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    current_streak = Column(Integer, default=0)
    longest_streak = Column(Integer, default=0)
    last_completed_date = Column(Date, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="streak")
    
    def __repr__(self):
        return f"<UserStreak(id={self.id}, user_id={self.user_id}, current={self.current_streak})>"


class AchievementDefinition(Base):
    """Static achievement definitions (not stored in DB, used for reference)."""
    
    __tablename__ = "achievement_definitions"
    
    id = Column(String(50), primary_key=True)
    title = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    emoji = Column(String(10), nullable=False)
    category = Column(String(50), nullable=False)  # streak, challenges, hydration, etc.
    requirement = Column(Integer, nullable=False)
    
    def __repr__(self):
        return f"<AchievementDefinition(id={self.id}, title={self.title})>"


class UserAchievement(Base):
    """User unlocked achievements."""
    
    __tablename__ = "user_achievements"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    achievement_id = Column(String(50), nullable=False)
    unlocked_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="achievements")
    
    __table_args__ = (
        Index("idx_user_achievement", "user_id", "achievement_id", unique=True),
    )
    
    def __repr__(self):
        return f"<UserAchievement(id={self.id}, user_id={self.user_id}, achievement_id={self.achievement_id})>"


class Reminder(Base):
    """User reminders for notifications."""
    
    __tablename__ = "reminders"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(String(50), nullable=False)  # hydration, stretchBreak, meditation, custom
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=True)
    time_hour = Column(Integer, nullable=False)
    time_minute = Column(Integer, nullable=False)
    frequency = Column(String(20), nullable=False)  # daily, weekdays, custom
    custom_days = Column(ARRAY(Integer), default={})
    is_enabled = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="reminders")
    
    __table_args__ = (
        Index("idx_reminder_user", "user_id"),
        Index("idx_reminder_enabled", "user_id", "is_enabled"),
    )
    
    def __repr__(self):
        return f"<Reminder(id={self.id}, user_id={self.user_id}, type={self.type})>"


class PushToken(Base):
    """FCM/APNs push notification tokens."""
    
    __tablename__ = "push_tokens"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token = Column(String(500), nullable=False)
    platform = Column(String(20), nullable=False)  # ios, android, web
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="push_tokens")
    
    __table_args__ = (
        Index("idx_push_token_user", "user_id", "token", unique=True),
    )
    
    def __repr__(self):
        return f"<PushToken(id={self.id}, user_id={self.user_id}, platform={self.platform})>"


class DailyTracking(Base):
    """Daily tracking for water intake, mood, etc."""
    
    __tablename__ = "daily_tracking"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    date = Column(Date, nullable=False)
    water_intake = Column(Integer, default=0)
    mood = Column(String(20), nullable=True)
    breathing_sessions = Column(Integer, default=0)
    posture_checks = Column(Integer, default=0)
    screen_breaks = Column(Integer, default=0)
    morning_stretch = Column(Boolean, default=False)
    evening_reflection = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="daily_tracking")
    
    __table_args__ = (
        Index("idx_daily_tracking_user_date", "user_id", "date", unique=True),
    )
    
    def __repr__(self):
        return f"<DailyTracking(id={self.id}, user_id={self.user_id}, date={self.date})>"
