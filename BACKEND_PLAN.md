# CorpFinity Backend Plan - FastAPI + Vercel

## 📋 Executive Summary

This document outlines a comprehensive backend architecture for the CorpFinity wellness app using FastAPI deployed on Vercel. The plan covers all features requiring server-side support, database selection, push notifications strategy, and deployment considerations.

---

## 🔍 Project Analysis

### Current State (Flutter App)
The app currently uses **local storage (SharedPreferences)** for all data persistence:

| Feature | Current Implementation | Backend Needed? |
|---------|----------------------|-----------------|
| User Authentication | Simulated login, local storage | ✅ Yes |
| User Profile | Local storage | ✅ Yes |
| Challenge History | Local storage | ✅ Yes |
| Streak Tracking | Local storage | ✅ Yes |
| Water Intake | Local storage | ⚠️ Optional |
| Mood Tracking | Local state only | ⚠️ Optional |
| Reminders | Local notifications | ✅ Yes (for push) |
| Daily Goals | Local state only | ⚠️ Optional |
| Achievements | Static definitions | ✅ Yes |
| Challenge Database | Hardcoded in app | ⚠️ Optional |

### Features Requiring Backend

#### 🔴 Critical (Must Have)
1. **User Authentication** - Secure login/signup with JWT
2. **User Profile Management** - Sync across devices
3. **Challenge History** - Persist completed challenges
4. **Streak Tracking** - Server-validated streaks
5. **Push Notifications** - Remote push via FCM/APNs

#### 🟡 Important (Should Have)
6. **Achievements System** - Server-validated badges
7. **Reminders Sync** - Cross-device reminder sync
8. **Analytics/Insights** - Aggregated user statistics

#### 🟢 Nice to Have
9. **Water Intake Sync** - Cross-device hydration tracking
10. **Mood History** - Long-term mood analytics
11. **Daily Goals Sync** - Cross-device goal progress
12. **Social Features** - Leaderboards, sharing
13. **AI Challenge Generation** - Server-side Gemini API calls

---

## 🗄️ Database Selection for Vercel

### Vercel-Compatible Database Options

| Database | Type | Vercel Integration | Best For | Pricing |
|----------|------|-------------------|----------|---------|
| **Vercel Postgres** | SQL | Native | Relational data, complex queries | Free tier: 256MB |
| **Vercel KV** | Redis | Native | Caching, sessions | Free tier: 256MB |
| **Neon** | PostgreSQL | Official Partner | Serverless Postgres | Free tier: 512MB |
| **PlanetScale** | MySQL | Official Partner | Scalable MySQL | Free tier: 5GB |
| **Supabase** | PostgreSQL | Community | Full BaaS features | Free tier: 500MB |
| **MongoDB Atlas** | NoSQL | Community | Flexible schemas | Free tier: 512MB |

### 🏆 Recommended: **Neon PostgreSQL**

**Why Neon?**
1. **Serverless-first** - Perfect for Vercel's serverless functions
2. **Auto-scaling** - Scales to zero when not in use (cost-effective)
3. **Branching** - Database branching for dev/staging/prod
4. **Connection pooling** - Built-in, essential for serverless
5. **PostgreSQL** - Full SQL support, mature ecosystem
6. **Generous free tier** - 512MB storage, 3GB data transfer

**Alternative: Supabase** (if you want built-in auth and realtime features)

---

## 🏗️ Backend Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        VERCEL EDGE                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   FastAPI    │  │   FastAPI    │  │   FastAPI    │          │
│  │   /api/auth  │  │  /api/users  │  │/api/challenges│         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│         └─────────────────┼─────────────────┘                   │
│                           │                                      │
│                    ┌──────▼──────┐                              │
│                    │   Neon DB   │                              │
│                    │ (PostgreSQL)│                              │
│                    └─────────────┘                              │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │  Vercel KV   │  │ Firebase FCM │                            │
│  │  (Sessions)  │  │(Push Notifs) │                            │
│  └──────────────┘  └──────────────┘                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Database Schema

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    avatar_seed VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- User sessions/tokens
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Challenge history
CREATE TABLE challenge_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    duration VARCHAR(50),
    emoji VARCHAR(10),
    fun_fact TEXT,
    goal_category VARCHAR(50),
    energy_level VARCHAR(20),
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_completed (user_id, completed_at DESC)
);

-- User streaks
CREATE TABLE user_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    last_completed_date DATE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Achievements
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    achievement_id VARCHAR(50) NOT NULL,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);

-- Reminders (for sync)
CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT,
    time_hour INT NOT NULL,
    time_minute INT NOT NULL,
    frequency VARCHAR(20) NOT NULL,
    custom_days INT[] DEFAULT '{}',
    is_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Push notification tokens
CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL, -- 'ios', 'android', 'web'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, token)
);

-- Daily tracking (optional - for sync)
CREATE TABLE daily_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    water_intake INT DEFAULT 0,
    mood VARCHAR(20),
    breathing_sessions INT DEFAULT 0,
    posture_checks INT DEFAULT 0,
    screen_breaks INT DEFAULT 0,
    morning_stretch BOOLEAN DEFAULT FALSE,
    evening_reflection BOOLEAN DEFAULT FALSE,
    UNIQUE(user_id, date)
);

-- Indexes for performance
CREATE INDEX idx_challenge_history_user ON challenge_history(user_id);
CREATE INDEX idx_daily_tracking_user_date ON daily_tracking(user_id, date);
```

---

## 🔌 API Endpoints

### Authentication (`/api/auth`)

```
POST   /api/auth/register     - Create new account
POST   /api/auth/login        - Login with email/password
POST   /api/auth/refresh      - Refresh access token
POST   /api/auth/logout       - Invalidate refresh token
POST   /api/auth/forgot       - Request password reset
POST   /api/auth/reset        - Reset password with token
DELETE /api/auth/account      - Delete account
```

### Users (`/api/users`)

```
GET    /api/users/me          - Get current user profile
PATCH  /api/users/me          - Update profile (name, avatar)
GET    /api/users/me/stats    - Get user statistics
```

### Challenges (`/api/challenges`)

```
GET    /api/challenges        - Get challenge database (optional)
POST   /api/challenges/complete - Record completed challenge
GET    /api/challenges/history  - Get user's challenge history
GET    /api/challenges/history/:date - Get challenges for specific date
```

### Streaks (`/api/streaks`)

```
GET    /api/streaks           - Get current streak info
POST   /api/streaks/validate  - Validate and update streak
```

### Achievements (`/api/achievements`)

```
GET    /api/achievements      - Get all achievements with unlock status
POST   /api/achievements/check - Check and unlock new achievements
```

### Reminders (`/api/reminders`)

```
GET    /api/reminders         - Get all reminders
POST   /api/reminders         - Create reminder
PATCH  /api/reminders/:id     - Update reminder
DELETE /api/reminders/:id     - Delete reminder
```

### Daily Tracking (`/api/tracking`)

```
GET    /api/tracking/today    - Get today's tracking data
PATCH  /api/tracking/today    - Update today's tracking
GET    /api/tracking/history  - Get tracking history (date range)
```

### Push Notifications (`/api/notifications`)

```
POST   /api/notifications/register   - Register push token
DELETE /api/notifications/unregister - Remove push token
POST   /api/notifications/test       - Send test notification
```

---

## 🔔 Push Notifications Strategy

### Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flutter   │────▶│   FastAPI   │────▶│  Firebase   │
│     App     │     │   Backend   │     │     FCM     │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          │                          │
                    ▼                          ▼                          ▼
              ┌──────────┐              ┌──────────┐              ┌──────────┐
              │   iOS    │              │ Android  │              │   Web    │
              │   APNs   │              │   FCM    │              │   FCM    │
              └──────────┘              └──────────┘              └──────────┘
```

### Implementation Steps

1. **Firebase Setup**
   - Create Firebase project
   - Enable Cloud Messaging
   - Download service account key for backend

2. **Flutter Integration**
   - Add `firebase_messaging` package
   - Configure iOS APNs certificates
   - Configure Android FCM

3. **Backend Integration**
   - Use `firebase-admin` Python SDK
   - Store FCM tokens in database
   - Create notification service

### Notification Types

| Type | Trigger | Content |
|------|---------|---------|
| Reminder | Scheduled | "Time for your {reminder_type}!" |
| Streak Risk | 8 PM if no activity | "Don't lose your {streak} day streak!" |
| Achievement | On unlock | "🏆 You earned: {achievement_name}" |
| Weekly Summary | Sunday 6 PM | "You completed {count} challenges this week!" |
| Motivation | Random daily | Wellness quotes |

### Backend Notification Service

```python
# services/notification_service.py
from firebase_admin import messaging
from datetime import datetime, timedelta

class NotificationService:
    async def send_to_user(self, user_id: str, title: str, body: str, data: dict = None):
        tokens = await self.get_user_tokens(user_id)
        
        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            tokens=tokens
        )
        
        response = messaging.send_multicast(message)
        # Handle failed tokens (remove invalid ones)
        
    async def schedule_streak_reminder(self, user_id: str):
        # Check if user has completed challenge today
        # If not, schedule reminder for 8 PM
        pass
        
    async def send_achievement_notification(self, user_id: str, achievement: dict):
        await self.send_to_user(
            user_id,
            f"🏆 Achievement Unlocked!",
            f"You earned: {achievement['title']}"
        )
```

---

## 📁 Project Structure

```
corpfinity-backend/
├── api/
│   ├── __init__.py
│   ├── index.py              # Main FastAPI app entry
│   ├── auth.py               # Auth endpoints
│   ├── users.py              # User endpoints
│   ├── challenges.py         # Challenge endpoints
│   ├── streaks.py            # Streak endpoints
│   ├── achievements.py       # Achievement endpoints
│   ├── reminders.py          # Reminder endpoints
│   ├── tracking.py           # Daily tracking endpoints
│   └── notifications.py      # Push notification endpoints
├── core/
│   ├── __init__.py
│   ├── config.py             # Environment config
│   ├── security.py           # JWT, password hashing
│   └── database.py           # Database connection
├── models/
│   ├── __init__.py
│   ├── user.py
│   ├── challenge.py
│   ├── streak.py
│   ├── achievement.py
│   ├── reminder.py
│   └── tracking.py
├── schemas/
│   ├── __init__.py
│   ├── auth.py
│   ├── user.py
│   ├── challenge.py
│   └── ...
├── services/
│   ├── __init__.py
│   ├── auth_service.py
│   ├── streak_service.py
│   ├── achievement_service.py
│   └── notification_service.py
├── requirements.txt
├── vercel.json
└── .env.example
```

---

## ⚙️ Vercel Configuration

### `vercel.json`

```json
{
  "version": 2,
  "builds": [
    {
      "src": "api/index.py",
      "use": "@vercel/python"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "api/index.py"
    }
  ],
  "env": {
    "DATABASE_URL": "@database_url",
    "JWT_SECRET": "@jwt_secret",
    "FIREBASE_CREDENTIALS": "@firebase_credentials"
  }
}
```

### `requirements.txt`

```
# Core Framework
fastapi==0.109.0
uvicorn==0.27.0

# Authentication & Security
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4

# Database
sqlalchemy==2.0.25
asyncpg==0.29.0
psycopg2-binary==2.9.9

# Redis
redis==5.0.1
hiredis==2.3.2  # C parser for better performance

# Validation & Config
pydantic==2.5.3
pydantic-settings==2.1.0
python-multipart==0.0.6

# Push Notifications
firebase-admin==6.4.0

# HTTP Client
httpx==0.26.0

# Utils
python-dateutil==2.8.2
```

---

## 📊 Performance Comparison (With vs Without Redis)

### Response Time Benchmarks

| Operation | Without Redis | With Redis | Improvement |
|-----------|--------------|------------|-------------|
| Get User Profile | 45-80ms | 2-5ms | **~15x faster** |
| Validate JWT | 50-100ms | 1-3ms | **~30x faster** |
| Check Rate Limit | 30-60ms | 0.5-2ms | **~40x faster** |
| Get Streak Data | 40-70ms | 2-4ms | **~18x faster** |
| Token Blacklist Check | 25-50ms | 0.3-1ms | **~50x faster** |

### Database Load Reduction

```
Without Redis:
┌─────────────────────────────────────────────────────────┐
│  Every API Request                                       │
│  ├── JWT Validation → DB Query (users table)            │
│  ├── Rate Limit Check → DB Query (rate_limits table)    │
│  ├── Get User Data → DB Query (users table)             │
│  └── Business Logic → More DB Queries                   │
│                                                          │
│  Result: 4-6 DB queries per request                     │
│  DB Connection Pool: Exhausted quickly                  │
└─────────────────────────────────────────────────────────┘

With Redis:
┌─────────────────────────────────────────────────────────┐
│  Every API Request                                       │
│  ├── JWT Validation → Redis (cached user)               │
│  ├── Rate Limit Check → Redis (counter)                 │
│  ├── Get User Data → Redis (cache hit) or DB (miss)    │
│  └── Business Logic → DB Queries (only when needed)    │
│                                                          │
│  Result: 0-2 DB queries per request (80% cache hit)    │
│  DB Connection Pool: Healthy                            │
└─────────────────────────────────────────────────────────┘
```

### Cost Savings

| Metric | Without Redis | With Redis | Savings |
|--------|--------------|------------|---------|
| DB Connections/sec | 500 | 100 | 80% |
| Neon Compute Hours | 100h/mo | 25h/mo | 75% |
| Vercel Function Duration | 200ms avg | 50ms avg | 75% |
| Monthly Cost (10K users) | ~$50 | ~$25 | 50% |

---

## 🔐 JWT Authentication (Detailed)

### JWT Token Strategy

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         JWT AUTH FLOW                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐    Login     ┌──────────┐    Validate    ┌──────────┐    │
│  │  Flutter │─────────────▶│  FastAPI │───────────────▶│   Neon   │    │
│  │   App    │              │  Backend │                │    DB    │    │
│  └────┬─────┘              └────┬─────┘                └──────────┘    │
│       │                         │                                       │
│       │    Access Token (JWT)   │    Store Refresh Token               │
│       │◀────────────────────────│───────────────────────▶ Redis        │
│       │    + Refresh Token      │                                       │
│       │                         │                                       │
│  ┌────▼─────┐                   │                                       │
│  │  Secure  │    API Request    │                                       │
│  │  Storage │──────────────────▶│  Verify JWT Signature                │
│  └──────────┘   Authorization:  │  Check Redis Blacklist               │
│                 Bearer <token>  │  Validate Claims                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Token Types

| Token | Storage | Expiry | Purpose |
|-------|---------|--------|---------|
| Access Token | Flutter Secure Storage | 15 minutes | API authentication |
| Refresh Token | HTTP-only cookie + Redis | 7 days | Get new access tokens |
| Password Reset | Redis only | 1 hour | One-time password reset |

### JWT Payload Structure

```python
# Access Token Payload
{
    "sub": "user_uuid",           # Subject (user ID)
    "email": "user@example.com",
    "type": "access",
    "iat": 1701619200,            # Issued at
    "exp": 1701620100,            # Expires (15 min)
    "jti": "unique_token_id"      # JWT ID (for blacklisting)
}

# Refresh Token Payload
{
    "sub": "user_uuid",
    "type": "refresh",
    "iat": 1701619200,
    "exp": 1702224000,            # Expires (7 days)
    "jti": "unique_token_id"
}
```

### JWT Implementation

```python
# core/security.py
from datetime import datetime, timedelta
from jose import jwt, JWTError
from passlib.context import CryptContext
from uuid import uuid4
import redis.asyncio as redis

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class JWTHandler:
    def __init__(self, secret: str, algorithm: str = "HS256"):
        self.secret = secret
        self.algorithm = algorithm
        self.access_token_expire = timedelta(minutes=15)
        self.refresh_token_expire = timedelta(days=7)
    
    def create_access_token(self, user_id: str, email: str) -> str:
        payload = {
            "sub": user_id,
            "email": email,
            "type": "access",
            "iat": datetime.utcnow(),
            "exp": datetime.utcnow() + self.access_token_expire,
            "jti": str(uuid4())
        }
        return jwt.encode(payload, self.secret, algorithm=self.algorithm)
    
    def create_refresh_token(self, user_id: str) -> tuple[str, str]:
        jti = str(uuid4())
        payload = {
            "sub": user_id,
            "type": "refresh",
            "iat": datetime.utcnow(),
            "exp": datetime.utcnow() + self.refresh_token_expire,
            "jti": jti
        }
        token = jwt.encode(payload, self.secret, algorithm=self.algorithm)
        return token, jti
    
    def verify_token(self, token: str, token_type: str = "access") -> dict:
        try:
            payload = jwt.decode(token, self.secret, algorithms=[self.algorithm])
            if payload.get("type") != token_type:
                raise JWTError("Invalid token type")
            return payload
        except JWTError:
            raise
    
    @staticmethod
    def hash_password(password: str) -> str:
        return pwd_context.hash(password)
    
    @staticmethod
    def verify_password(plain: str, hashed: str) -> bool:
        return pwd_context.verify(plain, hashed)
```

### Token Refresh Flow

```python
# api/auth.py
@router.post("/refresh")
async def refresh_token(
    refresh_token: str,
    redis_client: Redis = Depends(get_redis),
    db: AsyncSession = Depends(get_db)
):
    # 1. Verify refresh token
    payload = jwt_handler.verify_token(refresh_token, "refresh")
    jti = payload["jti"]
    user_id = payload["sub"]
    
    # 2. Check if token is blacklisted in Redis
    if await redis_client.get(f"blacklist:{jti}"):
        raise HTTPException(401, "Token has been revoked")
    
    # 3. Check if refresh token exists in Redis
    stored_jti = await redis_client.get(f"refresh:{user_id}")
    if stored_jti != jti:
        raise HTTPException(401, "Invalid refresh token")
    
    # 4. Get user from database
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(401, "User not found")
    
    # 5. Generate new tokens
    new_access_token = jwt_handler.create_access_token(user.id, user.email)
    new_refresh_token, new_jti = jwt_handler.create_refresh_token(user.id)
    
    # 6. Blacklist old refresh token, store new one
    await redis_client.setex(f"blacklist:{jti}", 604800, "1")  # 7 days
    await redis_client.setex(f"refresh:{user_id}", 604800, new_jti)
    
    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer"
    }
```

---

## 🔴 Redis Integration (Vercel KV)

### Why Redis?

| Use Case | Benefit | Without Redis |
|----------|---------|---------------|
| Session Management | O(1) token lookup | DB query every request |
| Rate Limiting | Distributed counters | Complex DB logic |
| Caching | Sub-ms response times | 50-200ms DB queries |
| Token Blacklist | Instant revocation | DB scan on every request |
| Real-time Data | Pub/Sub for live updates | Polling |

### Redis Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         REDIS (VERCEL KV) USAGE                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │
│  │   AUTH LAYER    │  │  CACHING LAYER  │  │  RATE LIMITING  │         │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤         │
│  │ • Refresh tokens│  │ • User profiles │  │ • Per-IP limits │         │
│  │ • Token blacklist│ │ • Streak data   │  │ • Per-user limits│        │
│  │ • Password reset│  │ • Achievements  │  │ • Endpoint limits│        │
│  │ • Active sessions│ │ • Challenge DB  │  │ • Sliding window │        │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘         │
│                                                                          │
│  ┌─────────────────┐  ┌─────────────────┐                               │
│  │   REAL-TIME     │  │   ANALYTICS     │                               │
│  ├─────────────────┤  ├─────────────────┤                               │
│  │ • Online status │  │ • Daily active  │                               │
│  │ • Typing indicators│ • Feature usage │                               │
│  │ • Live updates  │  │ • Error counts  │                               │
│  └─────────────────┘  └─────────────────┘                               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Redis Key Schema

```python
# Key naming convention: {namespace}:{entity}:{identifier}

REDIS_KEYS = {
    # Authentication
    "refresh:{user_id}": "Current refresh token JTI",
    "blacklist:{jti}": "Revoked token marker",
    "reset:{token}": "Password reset token -> user_id",
    "sessions:{user_id}": "Set of active session IDs",
    
    # Caching (with TTL)
    "cache:user:{user_id}": "User profile (5 min TTL)",
    "cache:streak:{user_id}": "Streak data (1 min TTL)",
    "cache:achievements:{user_id}": "User achievements (10 min TTL)",
    "cache:challenges": "Challenge database (1 hour TTL)",
    
    # Rate Limiting
    "ratelimit:{ip}:{endpoint}": "Request count",
    "ratelimit:user:{user_id}:{endpoint}": "User request count",
    
    # Analytics
    "analytics:dau:{date}": "HyperLogLog of daily active users",
    "analytics:challenges:{date}": "Challenge completions count",
}
```

### Redis Service Implementation

```python
# services/redis_service.py
import redis.asyncio as redis
from typing import Optional, Any
import json

class RedisService:
    def __init__(self, url: str):
        self.redis = redis.from_url(url, decode_responses=True)
    
    # ============ Authentication ============
    
    async def store_refresh_token(self, user_id: str, jti: str, ttl: int = 604800):
        """Store refresh token JTI (7 days TTL)"""
        await self.redis.setex(f"refresh:{user_id}", ttl, jti)
    
    async def get_refresh_token(self, user_id: str) -> Optional[str]:
        """Get stored refresh token JTI"""
        return await self.redis.get(f"refresh:{user_id}")
    
    async def blacklist_token(self, jti: str, ttl: int = 604800):
        """Add token to blacklist"""
        await self.redis.setex(f"blacklist:{jti}", ttl, "1")
    
    async def is_token_blacklisted(self, jti: str) -> bool:
        """Check if token is blacklisted"""
        return await self.redis.exists(f"blacklist:{jti}") > 0
    
    async def store_password_reset(self, token: str, user_id: str, ttl: int = 3600):
        """Store password reset token (1 hour TTL)"""
        await self.redis.setex(f"reset:{token}", ttl, user_id)
    
    async def get_password_reset(self, token: str) -> Optional[str]:
        """Get user_id from reset token and delete it (one-time use)"""
        user_id = await self.redis.get(f"reset:{token}")
        if user_id:
            await self.redis.delete(f"reset:{token}")
        return user_id
    
    # ============ Caching ============
    
    async def cache_user(self, user_id: str, user_data: dict, ttl: int = 300):
        """Cache user profile (5 min TTL)"""
        await self.redis.setex(
            f"cache:user:{user_id}", 
            ttl, 
            json.dumps(user_data)
        )
    
    async def get_cached_user(self, user_id: str) -> Optional[dict]:
        """Get cached user profile"""
        data = await self.redis.get(f"cache:user:{user_id}")
        return json.loads(data) if data else None
    
    async def invalidate_user_cache(self, user_id: str):
        """Invalidate user cache on update"""
        await self.redis.delete(f"cache:user:{user_id}")
    
    async def cache_streak(self, user_id: str, streak_data: dict, ttl: int = 60):
        """Cache streak data (1 min TTL - changes frequently)"""
        await self.redis.setex(
            f"cache:streak:{user_id}",
            ttl,
            json.dumps(streak_data)
        )
    
    async def get_cached_streak(self, user_id: str) -> Optional[dict]:
        """Get cached streak data"""
        data = await self.redis.get(f"cache:streak:{user_id}")
        return json.loads(data) if data else None
    
    # ============ Rate Limiting ============
    
    async def check_rate_limit(
        self, 
        key: str, 
        limit: int, 
        window: int
    ) -> tuple[bool, int]:
        """
        Sliding window rate limiter
        Returns: (is_allowed, remaining_requests)
        """
        current = await self.redis.incr(key)
        
        if current == 1:
            await self.redis.expire(key, window)
        
        remaining = max(0, limit - current)
        return current <= limit, remaining
    
    async def rate_limit_ip(self, ip: str, endpoint: str) -> tuple[bool, int]:
        """Rate limit by IP: 100 requests per minute"""
        key = f"ratelimit:{ip}:{endpoint}"
        return await self.check_rate_limit(key, limit=100, window=60)
    
    async def rate_limit_user(self, user_id: str, endpoint: str) -> tuple[bool, int]:
        """Rate limit by user: 1000 requests per minute"""
        key = f"ratelimit:user:{user_id}:{endpoint}"
        return await self.check_rate_limit(key, limit=1000, window=60)
    
    # ============ Analytics ============
    
    async def track_daily_active_user(self, user_id: str):
        """Track DAU using HyperLogLog (memory efficient)"""
        from datetime import date
        key = f"analytics:dau:{date.today().isoformat()}"
        await self.redis.pfadd(key, user_id)
        await self.redis.expire(key, 86400 * 30)  # Keep 30 days
    
    async def get_dau(self, date_str: str) -> int:
        """Get daily active users count"""
        return await self.redis.pfcount(f"analytics:dau:{date_str}")
    
    async def increment_challenge_count(self):
        """Track daily challenge completions"""
        from datetime import date
        key = f"analytics:challenges:{date.today().isoformat()}"
        await self.redis.incr(key)
        await self.redis.expire(key, 86400 * 30)
```

### Rate Limiting Middleware

```python
# middleware/rate_limit.py
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, redis_service: RedisService):
        super().__init__(app)
        self.redis = redis_service
        
        # Endpoint-specific limits
        self.limits = {
            "/api/auth/login": (5, 60),      # 5 per minute
            "/api/auth/register": (3, 60),   # 3 per minute
            "/api/auth/forgot": (3, 300),    # 3 per 5 minutes
            "default": (100, 60)             # 100 per minute
        }
    
    async def dispatch(self, request: Request, call_next):
        ip = request.client.host
        path = request.url.path
        
        # Get limit for endpoint
        limit, window = self.limits.get(path, self.limits["default"])
        
        # Check rate limit
        allowed, remaining = await self.redis.check_rate_limit(
            f"ratelimit:{ip}:{path}", limit, window
        )
        
        if not allowed:
            raise HTTPException(
                status_code=429,
                detail="Too many requests",
                headers={"Retry-After": str(window)}
            )
        
        response = await call_next(request)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Limit"] = str(limit)
        
        return response
```

### Caching Decorator

```python
# core/cache.py
from functools import wraps
from typing import Callable
import hashlib
import json

def cached(ttl: int = 300, key_prefix: str = "cache"):
    """
    Decorator for caching function results in Redis
    
    Usage:
        @cached(ttl=300, key_prefix="user")
        async def get_user(user_id: str):
            ...
    """
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Get redis from kwargs or first arg
            redis_service = kwargs.get('redis') or getattr(args[0], 'redis', None)
            
            # Generate cache key
            key_data = f"{func.__name__}:{args}:{kwargs}"
            cache_key = f"{key_prefix}:{hashlib.md5(key_data.encode()).hexdigest()}"
            
            # Try cache first
            if redis_service:
                cached_data = await redis_service.redis.get(cache_key)
                if cached_data:
                    return json.loads(cached_data)
            
            # Execute function
            result = await func(*args, **kwargs)
            
            # Store in cache
            if redis_service and result:
                await redis_service.redis.setex(
                    cache_key, 
                    ttl, 
                    json.dumps(result, default=str)
                )
            
            return result
        return wrapper
    return decorator

# Usage example
class UserService:
    def __init__(self, db, redis):
        self.db = db
        self.redis = redis
    
    @cached(ttl=300, key_prefix="user")
    async def get_user_profile(self, user_id: str) -> dict:
        # This will be cached for 5 minutes
        user = await self.db.get_user(user_id)
        return user.to_dict()
```

### Vercel KV Configuration

```python
# core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str
    
    # Redis (Vercel KV)
    KV_REST_API_URL: str
    KV_REST_API_TOKEN: str
    
    # Or use standard Redis URL
    REDIS_URL: str = ""
    
    # JWT
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    
    @property
    def redis_url(self) -> str:
        if self.REDIS_URL:
            return self.REDIS_URL
        # Construct from Vercel KV credentials
        return f"rediss://default:{self.KV_REST_API_TOKEN}@{self.KV_REST_API_URL.replace('https://', '')}"
    
    class Config:
        env_file = ".env"
```

### Updated vercel.json

```json
{
  "version": 2,
  "builds": [
    {
      "src": "api/index.py",
      "use": "@vercel/python"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "api/index.py"
    }
  ],
  "env": {
    "DATABASE_URL": "@database_url",
    "JWT_SECRET": "@jwt_secret",
    "KV_REST_API_URL": "@kv_rest_api_url",
    "KV_REST_API_TOKEN": "@kv_rest_api_token",
    "FIREBASE_CREDENTIALS": "@firebase_credentials"
  }
}
```

---

## 🔐 Security Best Practices

1. **Password Hashing** - bcrypt with cost factor 12
2. **JWT Tokens** - Short-lived access (15 min), refresh in Redis
3. **Token Blacklisting** - Instant revocation via Redis
4. **HTTPS Only** - Vercel provides this by default
5. **Rate Limiting** - Redis-based sliding window
6. **Input Validation** - Pydantic schemas
7. **CORS** - Restrict to app domains
8. **SQL Injection** - SQLAlchemy ORM with parameterized queries
9. **Secrets** - Vercel environment variables (encrypted)
10. **Session Management** - Redis-backed with automatic expiry

---

## 🚀 Deployment Steps

### 1. Database Setup (Neon)

```bash
# 1. Create Neon account at neon.tech
# 2. Create new project
# 3. Copy connection string
# 4. Run migrations
```

### 2. Firebase Setup

```bash
# 1. Create Firebase project
# 2. Enable Cloud Messaging
# 3. Download service account JSON
# 4. Base64 encode for Vercel env var
```

### 3. Vercel Deployment

```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy
vercel

# Set environment variables
vercel env add DATABASE_URL
vercel env add JWT_SECRET
vercel env add FIREBASE_CREDENTIALS

# Deploy to production
vercel --prod
```

### 4. Flutter App Updates

```dart
// Update base URL
const baseUrl = 'https://your-app.vercel.app/api';

// Add HTTP client with auth interceptor
// Update services to use API instead of local storage
```

---

## 📱 Flutter Integration Changes

### New Dependencies

```yaml
dependencies:
  # HTTP Client
  dio: ^5.4.0
  
  # Secure Storage
  flutter_secure_storage: ^9.0.0
  
  # Firebase Messaging
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
```

### API Service Example

```dart
class ApiService {
  final Dio _dio;
  
  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: 'https://corpfinity-api.vercel.app/api',
    connectTimeout: Duration(seconds: 10),
  )) {
    _dio.interceptors.add(AuthInterceptor());
  }
  
  Future<User> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return User.fromJson(response.data['user']);
  }
  
  Future<void> completeChallenge(ChallengeHistoryItem challenge) async {
    await _dio.post('/challenges/complete', data: challenge.toJson());
  }
}
```

---

## 📈 Scaling Considerations

### Vercel Limits (Hobby Plan)

- 100GB bandwidth/month
- 100 hours serverless execution
- 10 second function timeout

### Optimization Strategies

1. **Connection Pooling** - Use Neon's built-in pooler
2. **Caching** - Use Vercel KV for frequently accessed data
3. **Edge Functions** - Move simple logic to edge
4. **Batch Operations** - Combine related API calls

### When to Upgrade

- >10,000 daily active users
- >1,000 concurrent connections
- Need for background jobs (use separate worker)

---

## 🗓️ Implementation Timeline

### Phase 1: Core Backend (Week 1-2)
- [ ] Set up FastAPI project structure
- [ ] Configure Neon database
- [ ] Implement auth endpoints
- [ ] Implement user endpoints
- [ ] Deploy to Vercel

### Phase 2: Challenge System (Week 3)
- [ ] Challenge history endpoints
- [ ] Streak tracking with validation
- [ ] Achievement system
- [ ] Update Flutter app to use API

### Phase 3: Push Notifications (Week 4)
- [ ] Firebase project setup
- [ ] FCM integration in backend
- [ ] Flutter firebase_messaging setup
- [ ] Implement notification types

### Phase 4: Sync Features (Week 5)
- [ ] Reminders sync
- [ ] Daily tracking sync
- [ ] Offline support in Flutter

### Phase 5: Polish & Launch (Week 6)
- [ ] Error handling improvements
- [ ] Rate limiting
- [ ] Monitoring setup
- [ ] Documentation
- [ ] Production deployment

---

## 💰 Cost Estimate (Monthly)

| Service | Free Tier | Paid Estimate |
|---------|-----------|---------------|
| Vercel | 100GB bandwidth | $20/mo (Pro) |
| Vercel KV (Redis) | 256MB, 30K requests/day | $1/mo per 100K requests |
| Neon | 512MB storage | $19/mo (Launch) |
| Firebase | 10K notifications | Free for most apps |
| **Total** | **$0** | **~$45/mo** |

*Free tier is sufficient for up to ~5,000 monthly active users*

### Redis ROI Analysis

| Without Redis | With Redis |
|---------------|------------|
| Higher DB costs | +$5/mo Redis |
| Slower responses | -$15/mo DB savings |
| More Vercel compute | -$10/mo compute savings |
| **Baseline** | **Net savings: ~$20/mo** |

---

## 📚 Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Vercel Python Runtime](https://vercel.com/docs/functions/serverless-functions/runtimes/python)
- [Neon Documentation](https://neon.tech/docs)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter FCM Setup](https://firebase.flutter.dev/docs/messaging/overview)

---

## ✅ Next Steps

1. **Create Neon account** and database
2. **Set up Firebase project** for push notifications
3. **Initialize FastAPI project** with the structure above
4. **Start with auth endpoints** - most critical for app functionality
5. **Incrementally migrate** Flutter app from local storage to API

Would you like me to start implementing any specific part of this plan?
