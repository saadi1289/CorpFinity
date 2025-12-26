from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime, date


# ==================== Auth Schemas ====================

class UserRegister(BaseModel):
    """Schema for user registration."""
    email: EmailStr
    password: str
    name: str


class UserLogin(BaseModel):
    """Schema for user login."""
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """Response containing JWT tokens."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class RefreshTokenRequest(BaseModel):
    """Request to refresh access token."""
    refresh_token: str


class RefreshTokenResponse(BaseModel):
    """Response for successful token refresh."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class LogoutRequest(BaseModel):
    """Request to logout and invalidate tokens."""
    refresh_token: str


# ==================== User Schemas ====================

class UserResponse(BaseModel):
    """User response schema."""
    id: str
    email: str
    name: str
    avatar: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    """Schema for updating user profile."""
    name: Optional[str] = None
    avatar: Optional[str] = None


class UserStats(BaseModel):
    """User statistics schema."""
    total_challenges: int
    total_streak: int
    longest_streak: int
    achievements_unlocked: int
    total_achievements: int
    current_water_intake: int
    join_date: date


# ==================== Challenge Schemas ====================

class ChallengeHistoryCreate(BaseModel):
    """Schema for creating a challenge history entry."""
    title: str
    description: Optional[str] = None
    duration: Optional[str] = None
    emoji: Optional[str] = None
    fun_fact: Optional[str] = None
    goal_category: Optional[str] = None
    energy_level: Optional[str] = None


class ChallengeHistoryResponse(ChallengeHistoryCreate):
    """Challenge history response schema."""
    id: str
    user_id: str
    completed_at: datetime
    
    class Config:
        from_attributes = True


class ChallengeHistoryListResponse(BaseModel):
    """List of challenge history entries."""
    items: List[ChallengeHistoryResponse]
    total: int
    page: int
    page_size: int


# ==================== Streak Schemas ====================

class StreakResponse(BaseModel):
    """Streak response schema."""
    current_streak: int
    longest_streak: int
    last_completed_date: Optional[date] = None
    updated_at: datetime
    
    class Config:
        from_attributes = True


class StreakValidateResponse(BaseModel):
    """Response after validating/updating streak."""
    streak_updated: bool
    current_streak: int
    longest_streak: int
    message: str


# ==================== Achievement Schemas ====================

class AchievementResponse(BaseModel):
    """Achievement response schema."""
    id: str
    title: str
    description: str
    emoji: str
    category: str
    requirement: int
    is_unlocked: bool
    unlocked_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class AchievementListResponse(BaseModel):
    """List of achievements with unlock status."""
    achievements: List[AchievementResponse]
    unlocked_count: int
    total_count: int


# ==================== Reminder Schemas ====================

class ReminderCreate(BaseModel):
    """Schema for creating a reminder."""
    type: str  # hydration, stretchBreak, meditation, custom
    title: str
    message: Optional[str] = None
    time_hour: int
    time_minute: int
    frequency: str  # daily, weekdays, custom
    custom_days: Optional[List[int]] = []
    is_enabled: bool = True


class ReminderUpdate(BaseModel):
    """Schema for updating a reminder."""
    type: Optional[str] = None
    title: Optional[str] = None
    message: Optional[str] = None
    time_hour: Optional[int] = None
    time_minute: Optional[int] = None
    frequency: Optional[str] = None
    custom_days: Optional[List[int]] = None
    is_enabled: Optional[bool] = None


class ReminderResponse(ReminderCreate):
    """Reminder response schema."""
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ReminderListResponse(BaseModel):
    """List of reminders."""
    reminders: List[ReminderResponse]
    total: int


# ==================== Tracking Schemas ====================

class DailyTrackingResponse(BaseModel):
    """Daily tracking response schema."""
    id: str
    user_id: str
    date: date
    water_intake: int
    mood: Optional[str] = None
    breathing_sessions: int
    posture_checks: int
    screen_breaks: int
    morning_stretch: bool
    evening_reflection: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class DailyTrackingUpdate(BaseModel):
    """Schema for updating daily tracking."""
    water_intake: Optional[int] = None
    mood: Optional[str] = None
    breathing_sessions: Optional[int] = None
    posture_checks: Optional[int] = None
    screen_breaks: Optional[int] = None
    morning_stretch: Optional[bool] = None
    evening_reflection: Optional[bool] = None


class TrackingHistoryResponse(BaseModel):
    """Tracking history response."""
    items: List[DailyTrackingResponse]
    total: int


# ==================== Notification Schemas ====================

class PushTokenCreate(BaseModel):
    """Schema for registering a push token."""
    token: str
    platform: str  # ios, android, web


class PushTokenResponse(BaseModel):
    """Push token response schema."""
    id: str
    user_id: str
    token: str
    platform: str
    created_at: datetime
    
    class Config:
        from_attributes = True


# ==================== Error Schemas ====================

class ErrorResponse(BaseModel):
    """Error response schema."""
    detail: str
    error_code: Optional[str] = None


class ValidationErrorResponse(BaseModel):
    """Validation error response schema."""
    detail: List[dict]
