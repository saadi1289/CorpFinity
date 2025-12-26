# Database Schema Documentation

## Tables

### users
Core user table for authentication and profile.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique user identifier |
| email | VARCHAR(255) | UNIQUE, NOT NULL | User email address |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt hashed password |
| name | VARCHAR(100) | NOT NULL | User display name |
| avatar_seed | VARCHAR(100) | NULL | Seed for DiceBear avatar |
| created_at | TIMESTAMP | DEFAULT NOW() | Account creation time |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last profile update |
| is_active | BOOLEAN | DEFAULT TRUE | Account active status |

### refresh_tokens
JWT refresh tokens for session management.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique token identifier |
| user_id | UUID | FK -> users.id | Associated user |
| token_hash | VARCHAR(255) | NOT NULL | Hashed refresh token |
| expires_at | TIMESTAMP | NOT NULL | Token expiration |
| created_at | TIMESTAMP | DEFAULT NOW() | Token creation time |
| revoked | BOOLEAN | DEFAULT FALSE | Token revoked status |

### challenge_history
Completed wellness challenges.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique challenge ID |
| user_id | UUID | FK -> users.id | User who completed |
| title | VARCHAR(200) | NOT NULL | Challenge title |
| description | TEXT | NULL | Challenge description |
| duration | VARCHAR(50) | NULL | Duration (e.g., "5 min") |
| emoji | VARCHAR(10) | NULL | Challenge emoji |
| fun_fact | TEXT | NULL | Interesting fact |
| goal_category | VARCHAR(50) | NULL | Category (breathing, stretch) |
| energy_level | VARCHAR(20) | NULL | Energy impact |
| completed_at | TIMESTAMP | DEFAULT NOW() | Completion time |

### user_streaks
Streak tracking data.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique streak ID |
| user_id | UUID | FK -> users.id, UNIQUE | Associated user |
| current_streak | INT | DEFAULT 0 | Current streak count |
| longest_streak | INT | DEFAULT 0 | Best streak ever |
| last_completed_date | DATE | NULL | Last challenge date |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update time |

### user_achievements
Unlocked user achievements.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique record ID |
| user_id | UUID | FK -> users.id | User with achievement |
| achievement_id | VARCHAR(50) | NOT NULL | Achievement identifier |
| unlocked_at | TIMESTAMP | DEFAULT NOW() | Unlock time |

### reminders
User reminders for notifications.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique reminder ID |
| user_id | UUID | FK -> users.id | Associated user |
| type | VARCHAR(50) | NOT NULL | Reminder type |
| title | VARCHAR(200) | NOT NULL | Reminder title |
| message | TEXT | NULL | Reminder message |
| time_hour | INT | NOT NULL | Hour (0-23) |
| time_minute | INT | NOT NULL | Minute (0-59) |
| frequency | VARCHAR(20) | NOT NULL | daily/weekdays/custom |
| custom_days | INTEGER[] | DEFAULT {} | Days for custom freq |
| is_enabled | BOOLEAN | DEFAULT TRUE | Enabled status |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation time |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |

### push_tokens
FCM/APNs tokens for push notifications.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique token ID |
| user_id | UUID | FK -> users.id | Associated user |
| token | VARCHAR(500) | NOT NULL | Push token value |
| platform | VARCHAR(20) | NOT NULL | ios/android/web |
| created_at | TIMESTAMP | DEFAULT NOW() | Token registration |

### daily_tracking
Daily wellness metrics.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique tracking ID |
| user_id | UUID | FK -> users.id | Associated user |
| date | DATE | NOT NULL | Tracking date |
| water_intake | INT | DEFAULT 0 | Water in ml |
| mood | VARCHAR(20) | NULL | Current mood |
| breathing_sessions | INT | DEFAULT 0 | Sessions count |
| posture_checks | INT | DEFAULT 0 | Checks count |
| screen_breaks | INT | DEFAULT 0 | Breaks count |
| morning_stretch | BOOLEAN | DEFAULT FALSE | Stretch completed |
| evening_reflection | BOOLEAN | DEFAULT FALSE | Reflection completed |
| created_at | TIMESTAMP | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |

## Indexes

- `idx_users_email` - Email lookups
- `idx_refresh_token_hash` - Token verification
- `idx_challenge_user_completed` - Challenge history queries
- `idx_reminder_user` - User reminder list
- `idx_daily_tracking_user_date` - Daily tracking queries
