# CorpFinity - Complete App Flow Documentation

## 📱 Application Overview

CorpFinity is a corporate wellness platform that helps employees maintain healthy habits through personalized
challenges, mood tracking, hydration monitoring, and achievement systems.

---

## 🗺️ App Navigation Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ APP ENTRY POINT │
├─────────────────────────────────────────────────────────────────────────────┤
│ │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │
│ │ Splash │────▶│ Onboarding │────▶│ Auth │ │
│ │ Screen │ │ (4 pages) │ │ Login/Signup│ │
│ └──────────────┘ └──────────────┘ └──────┬───────┘ │
│ │ │
│ ┌────────────────────┘ │
│ ▼ │
│ ┌──────────────────────────────────────────────────────────────────────┐ │
│ │ MAIN APP (Bottom Navigation) │ │
│ ├──────────────┬──────────────┬──────────────┬──────────────┬─────────┤ │
│ │ Home │ Challenges │ Insights │ Profile │ │ │
│ │ (Index 0) │ (Index 1) │ (Index 2) │ (Index 3) │ │ │
│ └──────────────┴──────────────┴──────────────┴──────────────┴─────────┘ │
│ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 1. Authentication Flow

### 1.1 Splash Screen
```
┌─────────────────────────────────────────────────────────────────┐
│ SPLASH SCREEN │
├─────────────────────────────────────────────────────────────────┤
│ Duration: 2 seconds │
│ Actions: │
│ 1. Display app logo with animation │
│ 2. Check local storage for existing user │
│ 3. Route to appropriate screen │
│ │
│ Frontend: │
│ - AnimatedOpacity for logo fade-in │
│ - StorageService.getUser() check │
│ │
│ Backend API: GET /api/auth/verify │
│ - Validates stored JWT token │
│ - Returns user data if valid │
│ - Returns 401 if expired (trigger refresh) │
│ │
│ Redis: │
│ - Check token blacklist │
│ - Cache user session │
└─────────────────────────────────────────────────────────────────┘
```


### 1.2 Onboarding Flow
```
┌─────────────────────────────────────────────────────────────────┐
│ ONBOARDING (4 Pages) │
├─────────────────────────────────────────────────────────────────┤
│ │
│ Page 1: Welcome to CorpFinity │
│ - App logo with floating animation │
│ - "Your personal wellness companion" │
│ │
│ Page 2: Personalized Challenges │
│ - Target icon │
│ - "Get wellness challenges tailored to your goals" │
│ │
│ Page 3: Smart Reminders │
│ - Bell icon │
│ - "Set reminders for hydration, stretching, meditation" │
│ │
│ Page 4: Track Your Progress │
│ - Trophy icon │
│ - "Build streaks, complete daily goals" │
│ │
│ Actions: │
│ - Skip button → Go to Auth │
│ - Continue/Get Started → Next page or Auth │
│ - Page indicators (swipeable) │
│ │
│ Frontend Only: No backend calls │
│ Storage: Mark onboarding complete in SharedPreferences │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Authentication Page
```
┌─────────────────────────────────────────────────────────────────┐
│ AUTH PAGE (Login/Signup) │
├─────────────────────────────────────────────────────────────────┤
│ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ LOGIN MODE │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ Fields: │ │
│ │ - Email Address (required, email validation) │ │
│ │ - Password (required, obscured) │ │
│ │ │ │
│ │ Actions: │ │
│ │ - Sign In → Submit login │ │
│ │ - Forgot Password? → ForgotPasswordPage │ │
│ │ - Google/Facebook → Social login (coming soon) │ │
│ │ - Sign Up → Toggle to signup mode │ │
│ └─────────────────────────────────────────────────────────┘ │
│ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ SIGNUP MODE │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ Fields: │ │
│ │ - Full Name (required) │ │
│ │ - Email Address (required, email validation) │ │
│ │ - Password (required, min 6 chars) │ │
│ │ │ │
│ │ Actions: │ │
│ │ - Get Started → Submit registration │ │
│ │ - Sign In → Toggle to login mode │ │
│ └─────────────────────────────────────────────────────────┘ │
│ │
│ Backend API: │
│ POST /api/auth/login │
│ Request: { email, password } │
│ Response: { user, access_token, refresh_token } │
│ │
│ POST /api/auth/register │
│ Request: { name, email, password } │
│ Response: { user, access_token, refresh_token } │
│ │
│ Redis: │
│ - Store refresh token JTI │
│ - Rate limit: 5 login attempts/minute per IP │
│ - Rate limit: 3 registrations/minute per IP │
│ │
│ Database: │
│ - users table: Create/validate user │
│ - Password hashed with bcrypt │
│ │
│ Flutter Storage: │
│ - flutter_secure_storage: Store tokens │
│ - SharedPreferences: Store user data │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4 Forgot Password Flow
```
┌─────────────────────────────────────────────────────────────────┐
│ FORGOT PASSWORD PAGE │
├─────────────────────────────────────────────────────────────────┤
│ │
│ Step 1: Enter Email │
│ - Email input field │
│ - "Send Reset Link" button │
│ │
│ Step 2: Check Email (UI feedback) │
│ - Success message displayed │
│ - "Back to Login" button │
│ │
│ Backend API: │
│ POST /api/auth/forgot │
│ Request: { email } │
│ Response: { message: "Reset email sent" } │
│ │
│ POST /api/auth/reset │
│ Request: { token, new_password } │
│ Response: { message: "Password updated" } │
│ │
│ Redis: │
│ - Store reset token (1 hour TTL) │
│ - Key: reset:{token} → user_id │
│ - One-time use (deleted after use) │
│ - Rate limit: 3 requests/5 minutes per email │
│ │
│ Email Service: │
│ - Send password reset email via SendGrid/SES │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🏠 2. Home Page Flow

### 2.1 Dashboard (Welcome State)
```
┌─────────────────────────────────────────────────────────────────┐
│ HOME DASHBOARD │
├─────────────────────────────────────────────────────────────────┤
│ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ HEADER │ │
│ │ - Time-based greeting (Morning/Afternoon/Evening) │ │
│ │ - User's first name │ │
│ │ - Bell icon → Reminders page │ │
│ │ (Badge shows active reminder count) │ │
│ └─────────────────────────────────────────────────────────┘ │
│ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ HERO CARD (Start Your Flow) │ │
│ │ - Gradient background (primary → secondary) │ │
│ │ - Sparkles icon │ │
│ │ - "Start Your Flow" title │ │
│ │ - "Personalized CorpFinity challenges" │ │
│ │ - Animated floating icons (bolt, lightbulb, heart) │ │
│ │ - "Go" button │ │
│ │ - Tap → Start wellness flow (Goal Selection) │ │
│ └─────────────────────────────────────────────────────────┘ │
│ │
│ Frontend: Local state management │
│ Backend: None for dashboard display │
└─────────────────────────────────────────────────────────────────┘
```


### 2.2 Mood Tracker
```
┌─────────────────────────────────────────────────────────────────┐
│ MOOD TRACKER │
├─────────────────────────────────────────────────────────────────┤
│ │
│ "How are you feeling?" │
│ │
│ Mood Options (5 choices): │
│ 🌞 Great - Sun icon, warm gold color │
│ 😊 Good - Smile icon, soft blue color │
│ 😐 Okay - Meh icon, neutral gray color │
│ ☁️ Tired - Cloud icon, soft lavender color │
│ 😟 Stressed - Frown icon, dusty coral color │
│ │
│ On Selection: │
│ - Animated highlight on selected mood │
│ - Contextual tip card appears below: │
│ │
│ Great → "Radiate Joy" - Share a kind word │
│ Good → "Ride the Wave" - Tackle something meaningful │
│ Okay → "Small Steps" - Complete one small win │
│ Tired → "Gentle Recharge" - Fresh air, water, breathe │
│ Stressed → "Ground Yourself" - 5-4-3-2-1 technique │
│ │
│ Frontend: Local state (_selectedMood) │
│ │
│ Backend API (Optional - for analytics): │
│ POST /api/tracking/mood │
│ Request: { mood, timestamp } │
│ Response: { success: true } │
│ │
│ Database: │
│ daily_tracking table: mood column │
│ │
│ Redis: │
│ - Cache today's mood for quick retrieval │
│ - Analytics: Track mood distribution │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Hydration Tracker
```
┌─────────────────────────────────────────────────────────────────┐
│ HYDRATION TRACKER │
├─────────────────────────────────────────────────────────────────┤
│ │
│ Display: │
│ - 💧 Hydration label │
│ - "X / 8 glasses today" counter │
│ - Progress bar (0-100%) │
│ - Plus button to add glass │
│ │
│ Behavior: │
│ - Tap + → Increment water count (max 8) │
│ - Resets daily at midnight │
│ - Progress bar fills as glasses increase │
│ - Plus button disabled at 8 glasses │
│ │
│ Frontend: │
│ - _waterIntake state variable │
│ - StorageService.saveWaterIntake(count, date) │
│ - Date check on load (reset if new day) │
│ │
│ Backend API: │
│ PATCH /api/tracking/today │
│ Request: { water_intake: 5 } │
│ Response: { water_intake: 5, date: "2024-12-03" } │
│ │
│ GET /api/tracking/today │
│ Response: { water_intake, mood, goals... } │
│ │
│ Database: │
│ daily_tracking table: water_intake column │
│ Unique constraint on (user_id, date) │
│ │
│ Redis: │
│ - Cache today's tracking data (1 min TTL) │
│ - Invalidate on update │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 Reminders Card (Dashboard)
```
┌─────────────────────────────────────────────────────────────────┐
│ REMINDERS CARD (Home) │
├─────────────────────────────────────────────────────────────────┤
│ │
│ Display: │
│ - 🔔 Reminders header │
│ - "X active" badge │
│ - Preview of up to 2 reminders (emoji, title, time) │
│ - "+X more" if more than 2 │
│ - Empty state: "Set up reminders to stay on track" │
│ │
│ Tap Action: │
│ - Navigate to RemindersPage │
│ │
│ Frontend: │
│ - _reminders list from StorageService │
│ - Filter by isEnabled for active count │
│ │
│ Backend API: │
│ GET /api/reminders │
│ Response: [{ id, type, title, time, frequency, enabled }] │
│ │
│ Redis: │
│ - Cache reminders list (5 min TTL) │
└─────────────────────────────────────────────────────────────────┘
```

### 2.5 Quick Relief Challenges
```
┌─────────────────────────────────────────────────────────────────┐
│ QUICK RELIEF SECTION │
├─────────────────────────────────────────────────────────────────┤
│ │
│ "Quick Relief" header with "Fast Track" subtitle │
│ │
│ Horizontal scrollable cards (3 pre-defined): │
│ │
│ 1. 🌬️ Instant Calm (1 min) │
│ "Box breathing: Inhale 4s, Hold 4s, Exhale 4s, Hold 4s" │
│ │
│ 2. 👀 Vision Reset (30 sec) │
│ "Look at something 20 feet away for 20 seconds" │
│ │
│ 3. 🙆 Desk Stretch (45 sec) │
│ "Raise shoulders to ears, hold 5s, drop suddenly" │
│ │
│ Tap Action: │
│ - Skip goal/energy selection │
│ - Go directly to Challenge View with selected challenge │
│ │
│ Frontend: │
│ - ChallengeService.quickChallenges (static list) │
│ - _initializeChallenge(challenge) on tap │
│ │
│ Backend: None (challenges are hardcoded) │
│ Future: GET /api/challenges/quick for dynamic quick challenges │
└─────────────────────────────────────────────────────────────────┘
```

### 2.6 Daily Wisdom
```
┌─────────────────────────────────────────────────────────────────┐
│ DAILY WISDOM │
├─────────────────────────────────────────────────────────────────┤
│ │
│ Display: │
│ - Random wellness quote │
│ - Quote author attribution │
│ - Decorative quote marks │
│ │
│ Quote Examples: │
│ "Almost everything will work again if you unplug it │
│ for a few minutes, including you." - Anne Lamott │
│ │
│ "Your calm mind is the ultimate weapon against your │
│ challenges." - Bryant McGill │
│ │
│ Frontend: │
│ - AppConstants.quotes (6 pre-defined quotes) │
│ - Random selection on page load │
│ │
│ Backend (Future): │
│ GET /api/quotes/daily │
│ Response: { text, author } │
│ - Could be personalized based on mood/time │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 3. Wellness Challenge Flow

### 3.1 Goal Selection
```
┌─────────────────────────────────────────────────────────────────┐
│ GOAL SELECTION │
├─────────────────────────────────────────────────────────────────┤
│ │
│ "What would you like to focus on?" │
│ │
│ 6 Goal Options (2x3 grid): │
│ │
│ 🧠 Stress Relief (Blue) │
│ "Calm your mind, find your center" │
│ ID: stress_reduction │
│ │
│ ⚡ Energy Boost (Yellow) │
│ "Recharge and feel alive" │
│ ID: increased_energy │
│ │
│ 🌙 Better Sleep (Indigo) │
│ "Wind down peacefully" │
│ ID: better_sleep │
│ │
│ 🏃 Movement (Red) │
│ "Get your body moving" │
│ ID: physical_fitness │
│ │
│ 🥗 Nourishment (Green) │
│ "Fuel your wellness" │
│ ID: healthy_eating │
│ │
│ ❤️ Connection (Pink) │
│ "Nurture relationships" │
│ ID: social_connection │
│ │
│ Tap Action: │
│ - Set _selectedGoal │
│ - Navigate to Energy Selection │
│ │
│ Frontend: AppConstants.goalOptions │
│ Backend: None │
└─────────────────────────────────────────────────────────────────┘
```


### 3.2 Energy Level Selection
```
┌─────────────────────────────────────────────────────────────────┐
│ ENERGY LEVEL SELECTION │
├─────────────────────────────────────────────────────────────────┤
│ │
│ "How's your energy right now?" │
│ │
│ 3 Energy Options: │
│ │
│ 🍃 Low Energy (Dusty Coral) │
│ - Gentle, minimal effort challenges │
│ - Seated exercises, breathing │
│ │
│ 🔥 Medium Energy (Amber Gold) │
│ - Moderate effort challenges │
│ - Standing exercises, light movement │
│ │
│ ⚡ High Energy (Sage Green) │
│ - Active challenges │
│ - Walking, more intense exercises │
│ │
│ Tap Action: │
│ - Navigate to Generating state │
│ - Fetch challenge based on goal + energy │
│ │
│ Frontend: AppConstants.energyOptions │
│ Backend: None (challenge selection is local) │
│ │
│ Future Backend: │
│ POST /api/challenges/generate │
│ Request: { goal_id, energy_level } │
│ Response: { challenge } │
│ - AI-powered challenge generation │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 Challenge Generation
```
┌─────────────────────────────────────────────────────────────────┐
│ GENERATING CHALLENGE │
├─────────────────────────────────────────────────────────────────┤
│ │
│ Display: │
│ - Loading spinner animation │
│ - "Finding your perfect challenge..." │
│ - Duration: 1.5 seconds (simulated) │
│ │
│ Process: │
│ 1. Show generating UI │
│ 2. ChallengeService.getChallengeFromDb(goalId, energy) │
│ 3. Random selection from matching challenges │
│ 4. Navigate to Challenge View │
│ │
│ Challenge Database (18 challenges total): │
│ - 6 goals × 3 energy levels │
│ - 1-2 challenges per combination │
│ │
│ Frontend: │
│ - _database map in ChallengeService │
│ - Random().nextInt() for selection │
│ │
│ Backend (Future - AI Generation): │
│ POST /api/challenges/generate │
│ Request: { goal_id, energy_level, user_history } │
│ Response: { title, description, duration, emoji, funFact } │
│ - Uses Gemini API for personalized challenges │
│ - Considers user's past completions │
└─────────────────────────────────────────────────────────────────┘
```

### 3.4 Challenge View (Timer)
```
┌─────────────────────────────────────────────────────────────────┐
│ CHALLENGE VIEW │
├─────────────────────────────────────────────────────────────────┤
│ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ CHALLENGE CARD │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ - Emoji icon (large, centered) │ │
│ │ - Challenge title │ │
│ │ - Challenge description │ │
│ │ - Fun fact (expandable) │ │
│ └─────────────────────────────────────────────────────────┘ │
│ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ CIRCULAR TIMER │ │
│ ├─────────────────────────────────────────────────────────┤ │
│ │ - Circular progress indicator │ │
│ │ - Time remaining (MM:SS format) │ │
│ │ - Progress fills as time decreases │ │
│ └─────────────────────────────────────────────────────────┘ │
│ │
│ Controls: │
│ - Play/Pause button (toggle timer) │
│ - Reset button (restart timer) │
│ - "Complete" button (appears when timer finishes) │
│ - "Skip" option (complete without timer) │
│ │
│ Timer Logic: │
│ - Parse duration string ("2 mins" → 120 seconds) │
│ - Timer.periodic(1 second) countdown │
│ - _isTimerActive, _timerFinished states │
│ │
│ Frontend: │
│ - CircularTimer widget │
│ - _timeLeft, _totalTime state │
│ - _toggleTimer(), _resetTimer() methods │
│ │
│ Backend: None during challenge │
└─────────────────────────────────────────────────────────────────┘
```

### 3.5 Challenge Completion
```
┌─────────────────────────────────────────────────────────────────┐
│ CHALLENGE COMPLETED │
├─────────────────────────────────────────────────────────────────┤
│ │
│ Display: │
│ - 🎉 Celebration animation │
│ - "Challenge Complete!" title │
│ - Streak counter update │
│ - Motivational message │
│ │
│ Actions: │
│ - "Do Another" → Back to Goal Selection │
│ - "Done" → Back to Dashboard │
│ - Share button → Share achievement │
│ │
│ On Completion (_completeChallenge): │
│ 1. Create ChallengeHistoryItem │
│ 2. Add to history (StorageService.saveHistory) │
│ 3. Update streak if new day │
│ 4. Save state (StorageService.saveState) │
│ 5. Check for new achievements │
│ │
│ Backend API: │
│ POST /api/challenges/complete │
│ Request: { │
│ title, description, duration, emoji, │
│ fun_fact, goal_category, energy_level │
│ } │
│ Response: { │
│ history_id, │
│ new_streak, │
│ achievements_unlocked: [] │
│ } │
│ │
│ Database: │
│ - INSERT into challenge_history │
│ - UPDATE user_streaks (if new day) │
│ - INSERT into user_achievements (if unlocked) │
│ │
│ Redis: │
│ - Invalidate streak cache │
│ - Invalidate history cache │
│ - Track daily challenge count (analytics) │
│ │
│ Push Notification (if achievement unlocked): │
│ - Send achievement notification via FCM │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 4. Challenges Page

### 4.1 Daily Goals Tab
```
┌─────────────────────────────────────────────────────────────────┐
│ DAILY GOALS TAB │
├─────────────────────────────────────────────────────────────────┤
│ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ PROGRESS SUMMARY │ │
│ │ - Circular progress (X% complete) │ │
│ │ - "X of 5 goals completed" │ │
│ │ - Motivational message based on progress │ │
│ │ 0-19%: "Let's begin!" 🌟 │ │
│ │ 20-39%: "Good start!" 🌱 │ │
│ │ 40-59%: "Keep going!" 👍 │ │
│ │ 60-79%: "Great progress!" ⚡ │ │
│ │ 80-99%: "Almost there!" 🔥 │ │
│ │ 100%: "Perfect day!" 🎉 │ │
│ └─────────────────────────────────────────────────────────┘ │
│ │
│ TODAY'S GOALS (3 trackable): │
│ │
│ 🌬️ Breathing Sessions (0-3) │
│ - Progress bar │
│ - Tap + to increment │
│ - Auto-counts from challenge history │
│ │
│ 🪑 Posture Checks (0-5) │
│ - Manual tracking │
│ - Tap + to increment │
│ │
│ 👁️ Screen Breaks (0-4) │
│ - Manual tracking │
│ - Tap + to increment │
│ │
│ DAILY RITUALS (2 toggles): │
│ │
│ 🌅 Morning Stretch │
│ - Checkbox toggle │
│ │
│ 🌙 Evening Reflection │
│ - Checkbox toggle │
│ │
│ Frontend: Local state (resets daily) │
│ │
│ Backend API: │
│ PATCH /api/tracking/today │
│ Request: { │
│ breathing_sessions, posture_checks, screen_breaks, │
│ morning_stretch, evening_reflection │
│ } │
│ │
│ Database: │
│ daily_tracking table: All goal columns │
└─────────────────────────────────────────────────────────────────┘
```


### 4.2 Weekly Challenge
```
┌─────────────────────────────────────────────────────────────────┐
│ WEEKLY CHALLENGE │
├─────────────────────────────────────────────────────────────────┤
│ │
│ "WEEKLY CHALLENGE" badge │
│ │
│ 🏆 Wellness Warrior │
│ "Complete 7 wellness challenges this week to earn the badge" │
│ │
│ Progress: X/7 (progress bar) │
│ │
│ Calculation: │
│ - Filter history by current week │
│ - Count challenges completed since Monday │
│ │
│ Frontend: │
│ - Calculate from _history list │
│ - DateTime comparison for week start │
│ │
│ Backend API: │
│ GET /api/challenges/weekly-progress │
│ Response: { completed: 5, target: 7, badge_earned: false } │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 History Tab
```
┌─────────────────────────────────────────────────────────────────┐
│ HISTORY TAB │
├─────────────────────────────────────────────────────────────────┤
│ │
│ Grouped by Date: │
│ - "Today" │
│ - "Yesterday" │
│ - "Dec 1" (older dates) │
│ │
│ Each History Item: │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ [Emoji] Challenge Title ✓ │ │
│ │ 🕐 14:30 • 2 mins │ │
│ └─────────────────────────────────────────────────────┘ │
│ │
│ Empty State: │
│ - History icon │
│ - "No challenges completed yet" │
│ - "Complete wellness challenges to see them here" │
│ │
│ Frontend: │
│ - StorageService.getHistory() │
│ - Group by date using _formatDateKey() │
│ │
│ Backend API: │
│ GET /api/challenges/history │
│ Query: ?limit=50&offset=0 │
│ Response: { │
│ items: [{ id, title, emoji, duration, completed_at }], │
│ total: 150, │
│ has_more: true │
│ } │
│ │
│ Database: │
│ SELECT * FROM challenge_history │
│ WHERE user_id = ? │
│ ORDER BY completed_at DESC │
│ LIMIT 50 OFFSET 0 │
│ │
│ Redis: │
│ - Cache recent history (5 min TTL) │
│ - Invalidate on new completion │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📈 5. Insights Page

### 5.1 Stats Overview
```
┌─────────────────────────────────────────────────────────────────┐
│ INSIGHTS PAGE │
├─────────────────────────────────────────────────────────────────┤
│ │
│ "Wellness Insights" header │
│ "Your progress at a glance" │
│ │
│ ┌─────────────────────┐ ┌─────────────────────┐ │
│ │ 🔥 STREAK │ │ 🏆 TOTAL │ │
│ │ 42 │ │ 156 │ │
│ │ Days in a row │ │ Sessions completed │ │
│ │ (Gradient card) │ │ (White card) │ │
│ └─────────────────────┘ └─────────────────────┘ │
│ │
│ Data Sources: │
│ - _streak from StorageService.getState() │
│ - _history.length for total sessions │
│ │
│ Backend API: │
│ GET /api/users/me/stats │
│ Response: { │
│ current_streak: 42, │
│ longest_streak: 67, │
│ total_sessions: 156, │
│ total_minutes: 312, │
│ this_week: 12, │
│ this_month: 45 │
│ } │
│ │
│ Redis: │
│ - Cache stats (1 min TTL) │
│ - Key: cache:stats:{user_id} │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Calendar Heatmap
```
┌─────────────────────────────────────────────────────────────────┐
│ CALENDAR HEATMAP │
├─────────────────────────────────────────────────────────────────┤
│ │
│ Month Navigation: │
│ < December 2024> │
    │ │
    │ Week Headers: │
    │ S M T W T F S │
    │ │
    │ Calendar Grid: │
    │ - Empty cells for padding │
    │ - Day numbers (1-31) │
    │ - Filled circle = Activity on that day │
    │ - Ring = Today (if no activity) │
    │ - Glow effect on active days │
    │ │
    │ Legend: │
    │ ● Completed ○ Today │
    │ │
    │ Activity Check (_hasActivity): │
    │ - Filter history by date │
    │ - Match year, month, day │
    │ │
    │ Frontend: │
    │ - _getCalendarDays() generates grid │
    │ - _changeMonth(delta) for navigation │
    │ │
    │ Backend API: │
    │ GET /api/challenges/history?month=2024-12 │
    │ Response: { │
    │ dates_with_activity: ["2024-12-01", "2024-12-03", ...] │
    │ } │
    │ │
    │ Database: │
    │ SELECT DISTINCT DATE(completed_at) as date │
    │ FROM challenge_history │
    │ WHERE user_id = ? AND completed_at >= ? AND completed_at < ? │
        └─────────────────────────────────────────────────────────────────┘ ``` ### 5.3 Weekly Activity Graph ```
        ┌─────────────────────────────────────────────────────────────────┐ │ WEEKLY RHYTHM GRAPH │
        ├─────────────────────────────────────────────────────────────────┤ │ │ │ Dark card with gradient bars │ │ │
        │ "WEEKLY RHYTHM" │ │ "Activity Level" │ │ │ │ Bar Chart: │ │ M T W T F S S │ │ █ █ █ █ █ █ █ │ │ 65% 40% 100%
        30% 80% 20% 50% │ │ │ │ Note: Currently uses static demo data │ │ │ │ Future Backend API: │ │ GET
        /api/insights/weekly-activity │ │ Response: { │ │ monday: 3, │ │ tuesday: 2, │ │ wednesday: 5, │ │ thursday: 1,
        │ │ friday: 4, │ │ saturday: 1, │ │ sunday: 2 │ │ } │ │ │ │ Database: │ │ SELECT EXTRACT(DOW FROM completed_at)
        as day, │ │ COUNT(*) as count │ │ FROM challenge_history │ │ WHERE user_id=? AND completed_at>= NOW() - INTERVAL
        '7d' │
        │ GROUP BY day │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 👤 6. Profile Page

        ### 6.1 Profile View Mode
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ PROFILE PAGE │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ Header: "Profile" with Edit (pencil) button │
        │ │
        │ ┌─────────────────────────────────────────────────────────┐ │
        │ │ PROFILE CARD │ │
        │ │ - Avatar (DiceBear avataaars) │ │
        │ │ - User name │ │
        │ │ - Email address │ │
        │ │ - "Wellness Member" badge │ │
        │ └─────────────────────────────────────────────────────────┘ │
        │ │
        │ ┌─────────────────────────────────────────────────────────┐ │
        │ │ STATS ROW │ │
        │ │ 🔥 42 Day Streak | 🎯 156 Challenges | 🕐 312 Minutes │ │
        │ └─────────────────────────────────────────────────────────┘ │
        │ │
        │ QUICK ACTIONS: │
        │ 🏆 Achievements → AchievementsPage │
        │ 📤 Share Progress → ShareService │
        │ 🔔 Reminders → RemindersPage │
        │ 📜 Activity History → ChallengesPage (history tab) │
        │ │
        │ SETTINGS: │
        │ 🔔 Push Notifications (toggle) │
        │ ⚙️ Notification Settings → Bottom sheet │
        │ ❓ Help & Support (coming soon) │
        │ 📄 Terms & Privacy → TermsPrivacyPage │
        │ │
        │ DANGER ZONE: │
        │ 🗑️ Delete Account → Confirmation dialog │
        │ │
        │ [Log Out] button │
        │ │
        │ "CorpFinity v1.3.0" footer │
        │ │
        │ Backend API: │
        │ GET /api/users/me │
        │ Response: { id, name, email, avatar_seed, created_at } │
        │ │
        │ GET /api/users/me/stats │
        │ Response: { streak, total_challenges, total_minutes } │
        └─────────────────────────────────────────────────────────────────┘
        ```


        ### 6.2 Profile Edit Mode
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ EDIT PROFILE MODE │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ Header: "Edit Profile" │
        │ │
        │ Avatar Section: │
        │ - Current avatar (large) │
        │ - 🎲 "Shuffle" button → Random new avatar seed │
        │ - Uses DiceBear API with random seed │
        │ │
        │ Form Fields: │
        │ - Full Name (TextFormField) │
        │ - Email (read-only, displayed) │
        │ │
        │ Actions: │
        │ - [Cancel] → Revert changes, exit edit mode │
        │ - [Save Changes] → Submit updates │
        │ │
        │ Frontend: │
        │ - _nameController, _editAvatarSeed state │
        │ - _shuffleAvatar() generates random seed │
        │ - _handleSave() updates user │
        │ │
        │ Backend API: │
        │ PATCH /api/users/me │
        │ Request: { name: "New Name", avatar_seed: "abc123" } │
        │ Response: { id, name, email, avatar_seed, updated_at } │
        │ │
        │ Database: │
        │ UPDATE users SET name = ?, avatar_seed = ?, updated_at = NOW()│
        │ WHERE id = ? │
        │ │
        │ Redis: │
        │ - Invalidate user cache on update │
        │ - Key: cache:user:{user_id} │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ### 6.3 Delete Account Flow
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ DELETE ACCOUNT FLOW │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ Step 1: Tap "Delete Account" │
        │ │
        │ Step 2: Confirmation Dialog │
        │ ⚠️ "Delete Account?" │
        │ "This action is permanent and cannot be undone." │
        │ "All your data will be deleted including:" │
        │ ✗ Your profile information │
        │ ✗ Challenge history │
        │ ✗ Streak progress │
        │ ✗ All reminders │
        │ │
        │ Type "DELETE" to confirm: [________] │
        │ │
        │ [Cancel] [Delete Account] (disabled until "DELETE" typed) │
        │ │
        │ Step 3: On Confirm │
        │ - Clear all local data │
        │ - Logout user │
        │ - Navigate to Auth page │
        │ │
        │ Frontend: │
        │ - _showDeleteAccountDialog() │
        │ - _deleteAccount() clears StorageService │
        │ │
        │ Backend API: │
        │ DELETE /api/auth/account │
        │ Response: { message: "Account deleted" } │
        │ │
        │ Database: │
        │ - CASCADE DELETE on user_id foreign keys │
        │ - Deletes: users, challenge_history, user_streaks, │
        │ user_achievements, reminders, push_tokens, │
        │ daily_tracking │
        │ │
        │ Redis: │
        │ - Delete all user-related keys │
        │ - Blacklist all active tokens │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 🏆 7. Achievements Page

        ### 7.1 Achievements Overview
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ ACHIEVEMENTS PAGE │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ ┌─────────────────────────────────────────────────────────┐ │
        │ │ PROGRESS CARD (Gradient) │ │
        │ │ - Large number: X unlocked │ │
        │ │ - "X of Y Achievements Unlocked" │ │
        │ │ - Progress bar │ │
        │ └─────────────────────────────────────────────────────────┘ │
        │ │
        │ ┌─────────────────────────────────────────────────────────┐ │
        │ │ CURRENT STATS │ │
        │ │ 🔥 42 Day Streak | 🎯 156 Challenges │ │
        │ └─────────────────────────────────────────────────────────┘ │
        │ │
        │ ALL BADGES (8 total): │
        │ │
        │ Streak Achievements: │
        │ 🌱 Getting Started - 3-day streak │
        │ 🔥 Week Warrior - 7-day streak │
        │ ⭐ Monthly Master - 30-day streak │
        │ 👑 Century Club - 100-day streak │
        │ │
        │ Challenge Achievements: │
        │ 🎯 First Steps - 5 challenges │
        │ 💪 Dedicated - 25 challenges │
        │ 🏆 Wellness Pro - 50 challenges │
        │ 🌟 Legend - 100 challenges │
        │ │
        │ Each Badge Card: │
        │ - Emoji (or 🔒 if locked) │
        │ - Title │
        │ - Description │
        │ - ✓ badge if unlocked, requirement number if locked │
        │ │
        │ Frontend: │
        │ - Achievement.allAchievements (static list) │
        │ - Check unlock status based on streak/challenges │
        │ │
        │ Backend API: │
        │ GET /api/achievements │
        │ Response: [ │
        │ { id, title, description, emoji, type, requirement, │
        │ is_unlocked, unlocked_at } │
        │ ] │
        │ │
        │ POST /api/achievements/check │
        │ - Called after challenge completion │
        │ - Returns newly unlocked achievements │
        │ Response: { newly_unlocked: [{ id, title, emoji }] } │
        │ │
        │ Database: │
        │ user_achievements table: │
        │ - user_id, achievement_id, unlocked_at │
        │ - Unique constraint on (user_id, achievement_id) │
        │ │
        │ Redis: │
        │ - Cache achievements (10 min TTL) │
        │ - Invalidate on new unlock │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 🔔 8. Reminders System

        ### 8.1 Reminders Page
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ REMINDERS PAGE │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ Header: "Reminders" with Test Notification button (🔔) │
        │ │
        │ Empty State: │
        │ - Bell icon │
        │ - "No Reminders Yet" │
        │ - "Set up reminders to stay on track" │
        │ - "+ Add Reminder" link │
        │ │
        │ Reminder List: │
        │ Each card (swipe to delete): │
        │ ┌─────────────────────────────────────────────────────┐ │
        │ │ [Emoji] Reminder Title [Toggle] │ │
        │ │ 🕐 9:00 AM 🔄 Every day │ │
        │ └─────────────────────────────────────────────────────┘ │
        │ │
        │ Floating Action Button: + Add new reminder │
        │ │
        │ Frontend: │
        │ - StorageService for persistence │
        │ - NotificationService for scheduling │
        │ - Dismissible widget for swipe-to-delete │
        │ │
        │ Backend API: │
        │ GET /api/reminders │
        │ POST /api/reminders │
        │ PATCH /api/reminders/:id │
        │ DELETE /api/reminders/:id │
        │ │
        │ Database: │
        │ reminders table: id, user_id, type, title, message, │
        │ time_hour, time_minute, frequency, │
        │ custom_days, is_enabled, created_at │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ### 8.2 Add Reminder Sheet
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ ADD REMINDER SHEET │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ "New Reminder" title │
        │ │
        │ REMINDER TYPE (4 options): │
        │ 💧 Hydration - "Time to drink some water!" │
        │ 🧘 Stretch Break - "Take a quick stretch break!" │
        │ 🧠 Meditation - "A moment of calm awaits you." │
        │ ✨ Take a Break - "Time for a wellness break!" │
        │ │
        │ TIME: │
        │ - Time picker (shows current selection) │
        │ - Tap to open native time picker │
        │ │
        │ REPEAT (3 options): │
        │ - Every Day (daily) │
        │ - Weekdays (Mon-Fri) │
        │ - Custom Days (select specific days) │
        │ │
        │ Custom Days Selector (if Custom selected): │
        │ M T W T F S S │
        │ ○ ○ ○ ○ ○ ○ ○ (tap to toggle) │
        │ │
        │ [Set Reminder] button │
        │ │
        │ On Save: │
        │ 1. Create Reminder object │
        │ 2. Save to StorageService │
        │ 3. Schedule with NotificationService │
        │ 4. Show confirmation snackbar │
        │ │
        │ Backend API: │
        │ POST /api/reminders │
        │ Request: { │
        │ type: "hydration", │
        │ title: "Hydration", │
        │ message: "Time to drink some water!", │
        │ time_hour: 9, │
        │ time_minute: 0, │
        │ frequency: "daily", │
        │ custom_days: [] │
        │ } │
        │ Response: { id, ...reminder_data } │
        └─────────────────────────────────────────────────────────────────┘
        ```


        ### 8.3 Push Notifications Flow
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ PUSH NOTIFICATIONS FLOW │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ LOCAL NOTIFICATIONS (Current Implementation): │
        │ │
        │ flutter_local_notifications package │
        │ - Scheduled locally on device │
        │ - Works offline │
        │ - Limited to device-specific scheduling │
        │ │
        │ Notification Types: │
        │ 1. Reminder notifications (scheduled) │
        │ 2. Test notification (immediate) │
        │ │
        │ ───────────────────────────────────────────────────────────── │
        │ │
        │ REMOTE PUSH NOTIFICATIONS (Backend Implementation): │
        │ │
        │ ┌─────────────────────────────────────────────────────────┐ │
        │ │ REGISTRATION FLOW │ │
        │ ├─────────────────────────────────────────────────────────┤ │
        │ │ 1. App requests notification permission │ │
        │ │ 2. Firebase generates FCM token │ │
        │ │ 3. App sends token to backend │ │
        │ │ 4. Backend stores token in push_tokens table │ │
        │ └─────────────────────────────────────────────────────────┘ │
        │ │
        │ Backend API: │
        │ POST /api/notifications/register │
        │ Request: { token: "fcm_token_here", platform: "android" } │
        │ Response: { success: true } │
        │ │
        │ DELETE /api/notifications/unregister │
        │ Request: { token: "fcm_token_here" } │
        │ Response: { success: true } │
        │ │
        │ ┌─────────────────────────────────────────────────────────┐ │
        │ │ NOTIFICATION TYPES │ │
        │ ├─────────────────────────────────────────────────────────┤ │
        │ │ │ │
        │ │ 1. SCHEDULED REMINDERS │ │
        │ │ - Cron job checks reminders table │ │
        │ │ - Sends push at scheduled time │ │
        │ │ - "💧 Time to drink some water!" │ │
        │ │ │ │
        │ │ 2. STREAK RISK ALERT (8 PM daily) │ │
        │ │ - Check if user completed challenge today │ │
        │ │ - If not, send reminder │ │
        │ │ - "🔥 Don't lose your 42-day streak!" │ │
        │ │ │ │
        │ │ 3. ACHIEVEMENT UNLOCKED │ │
        │ │ - Triggered on challenge completion │ │
        │ │ - "🏆 Achievement Unlocked: Week Warrior!" │ │
        │ │ │ │
        │ │ 4. WEEKLY SUMMARY (Sunday 6 PM) │ │
        │ │ - Aggregate weekly stats │ │
        │ │ - "📊 You completed 12 challenges this week!" │ │
        │ │ │ │
        │ │ 5. MOTIVATIONAL (Random daily) │ │
        │ │ - Random wellness quote │ │
        │ │ - "✨ Your calm mind is your ultimate weapon" │ │
        │ │ │ │
        │ └─────────────────────────────────────────────────────────┘ │
        │ │
        │ Database: │
        │ push_tokens table: │
        │ - id, user_id, token, platform, created_at │
        │ - Unique constraint on (user_id, token) │
        │ │
        │ Backend Service: │
        │ - Firebase Admin SDK (firebase-admin) │
        │ - Cron jobs for scheduled notifications │
        │ - Vercel Cron or external scheduler (e.g., Upstash) │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 📤 9. Share Feature

        ### 9.1 Share Progress
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ SHARE PROGRESS │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ Trigger: Profile page → "Share Progress" action │
        │ │
        │ Share Content: │
        │ "🔥 I'm on a [X]-day wellness streak with CorpFinity! │
        │ I've completed [Y] wellness challenges. │
        │ Join me on my wellness journey! 💪" │
        │ │
        │ Implementation: │
        │ - ShareService.shareStreak() │
        │ - Uses native share sheet │
        │ - share_plus package (or url_launcher) │
        │ │
        │ Frontend: │
        │ ShareService.shareStreak( │
        │ context: context, │
        │ streak: _currentStreak, │
        │ totalChallenges: _totalChallenges, │
        │ ) │
        │ │
        │ Backend: None (client-side only) │
        │ │
        │ Future Enhancement: │
        │ - Generate shareable image/card │
        │ - Deep link to app store │
        │ - Referral tracking │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 🔄 10. Data Sync Strategy

        ### 10.1 Offline-First Architecture
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ OFFLINE-FIRST STRATEGY │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ PRINCIPLE: App works fully offline, syncs when online │
        │ │
        │ ┌─────────────────────────────────────────────────────────┐ │
        │ │ DATA LAYERS │ │
        │ ├─────────────────────────────────────────────────────────┤ │
        │ │ │ │
        │ │ Layer 1: Local State (Riverpod) │ │
        │ │ - Immediate UI updates │ │
        │ │ - In-memory during session │ │
        │ │ │ │
        │ │ Layer 2: Local Storage (SharedPreferences) │ │
        │ │ - Persists across sessions │ │
        │ │ - Source of truth when offline │ │
        │ │ │ │
        │ │ Layer 3: Remote Database (Neon PostgreSQL) │ │
        │ │ - Server-validated data │ │
        │ │ - Cross-device sync │ │
        │ │ - Backup and recovery │ │
        │ │ │ │
        │ └─────────────────────────────────────────────────────────┘ │
        │ │
        │ SYNC FLOW: │
        │ │
        │ 1. User Action (e.g., complete challenge) │
        │ ↓ │
        │ 2. Update Local State (immediate) │
        │ ↓ │
        │ 3. Save to Local Storage (immediate) │
        │ ↓ │
        │ 4. Queue API Request │
        │ ↓ │
        │ 5. If Online: Send to Backend │
        │ If Offline: Store in sync queue │
        │ ↓ │
        │ 6. On Reconnect: Process sync queue │
        │ │
        │ CONFLICT RESOLUTION: │
        │ - Last-write-wins for simple fields │
        │ - Server timestamp for ordering │
        │ - Merge for additive data (history) │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ### 10.2 Sync Queue Implementation
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ SYNC QUEUE │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ Queue Structure (stored in SharedPreferences): │
        │ [ │
        │ { │
        │ "id": "sync_123", │
        │ "action": "complete_challenge", │
        │ "data": { challenge data }, │
        │ "timestamp": "2024-12-03T14:30:00Z", │
        │ "retries": 0 │
        │ }, │
        │ ... │
        │ ] │
        │ │
        │ Sync Service: │
        │ - Check connectivity on app start │
        │ - Process queue in order │
        │ - Retry failed requests (max 3 times) │
        │ - Remove successful items │
        │ - Handle conflicts │
        │ │
        │ Flutter Implementation: │
        │ - connectivity_plus package for network status │
        │ - Background fetch for periodic sync │
        │ - Workmanager for Android background tasks │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 📊 11. Analytics & Tracking

        ### 11.1 Events to Track
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ ANALYTICS EVENTS │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ USER EVENTS: │
        │ - user_registered │
        │ - user_logged_in │
        │ - user_logged_out │
        │ - profile_updated │
        │ - account_deleted │
        │ │
        │ CHALLENGE EVENTS: │
        │ - challenge_started (goal, energy_level) │
        │ - challenge_completed (goal, energy_level, duration) │
        │ - challenge_skipped │
        │ - quick_challenge_started (challenge_type) │
        │ │
        │ ENGAGEMENT EVENTS: │
        │ - mood_selected (mood_type) │
        │ - water_added │
        │ - daily_goal_completed (goal_type) │
        │ - reminder_created (reminder_type) │
        │ - reminder_toggled (enabled/disabled) │
        │ - achievement_unlocked (achievement_id) │
        │ - progress_shared │
        │ │
        │ NAVIGATION EVENTS: │
        │ - page_viewed (page_name) │
        │ - onboarding_completed │
        │ - onboarding_skipped │
        │ │
        │ Backend Storage: │
        │ - Redis HyperLogLog for DAU/MAU │
        │ - PostgreSQL for detailed event logs │
        │ - Aggregated daily/weekly/monthly stats │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 🔒 12. Security Considerations

        ### 12.1 Authentication Security
        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ SECURITY MEASURES │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ PASSWORD SECURITY: │
        │ - Bcrypt hashing (cost factor 12) │
        │ - Minimum 6 characters (enforce stronger in production) │
        │ - No password stored in plain text │
        │ │
        │ TOKEN SECURITY: │
        │ - JWT access tokens (15 min expiry) │
        │ - Refresh tokens (7 day expiry, stored in Redis) │
        │ - Token blacklisting on logout │
        │ - Secure storage in Flutter (flutter_secure_storage) │
        │ │
        │ API SECURITY: │
        │ - HTTPS only (Vercel default) │
        │ - Rate limiting (Redis-based) │
        │ - Input validation (Pydantic) │
        │ - SQL injection prevention (SQLAlchemy ORM) │
        │ - CORS configuration │
        │ │
        │ DATA PRIVACY: │
        │ - User data isolated by user_id │
        │ - No cross-user data access │
        │ - Account deletion removes all data │
        │ - No PII in logs │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 📱 13. App States Summary

        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ APP STATES (AppStep enum) │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ Home Page States: │
        │ │
        │ welcome → Dashboard view (default) │
        │ ↓ │
        │ goalSelection → Choose wellness goal │
        │ ↓ │
        │ energySelection → Choose energy level │
        │ ↓ │
        │ generating → Loading challenge │
        │ ↓ │
        │ challengeView → Timer and challenge display │
        │ ↓ │
        │ completed → Success screen │
        │ ↓ │
        │ welcome → Back to dashboard │
        │ │
        │ Navigation: │
        │ - AnimatedSwitcher for smooth transitions │
        │ - FadeTransition + SlideTransition │
        │ - 400ms duration with easeOutCubic curve │
        │ │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 🎨 14. UI/UX Patterns

        ```
        ┌─────────────────────────────────────────────────────────────────┐
        │ UI/UX PATTERNS │
        ├─────────────────────────────────────────────────────────────────┤
        │ │
        │ DESIGN SYSTEM: │
        │ - Plus Jakarta Sans font family │
        │ - Warm, earthy color palette │
        │ - 4px spacing increments (Tailwind-inspired) │
        │ - Rounded corners (12px, 16px, 20px, 24px) │
        │ - Subtle shadows and gradients │
        │ │
        │ ANIMATIONS: │
        │ - Tap scale feedback (0.98 scale) │
        │ - Page transitions (fade + slide) │
        │ - Floating hero card icons │
        │ - Progress bar animations │
        │ - Toggle switch animations │
        │ │
        │ LOADING STATES: │
        │ - Skeleton loaders for lists │
        │ - Circular progress for actions │
        │ - Shimmer effect for cards │
        │ │
        │ ERROR STATES: │
        │ - ErrorState widget with retry │
        │ - SnackBar for transient errors │
        │ - Dialog for critical errors │
        │ │
        │ EMPTY STATES: │
        │ - Illustrated empty states │
        │ - Call-to-action buttons │
        │ - Helpful tips │
        │ │
        │ RESPONSIVE: │
        │ - LayoutBuilder for adaptive layouts │
        │ - Flexible sizing for small screens │
        │ - Safe area handling │
        └─────────────────────────────────────────────────────────────────┘
        ```

        ---

        ## 📋 Quick Reference: API Endpoints

        | Feature | Method | Endpoint | Auth |
        |---------|--------|----------|------|
        | Register | POST | `/api/auth/register` | No |
        | Login | POST | `/api/auth/login` | No |
        | Refresh Token | POST | `/api/auth/refresh` | No |
        | Logout | POST | `/api/auth/logout` | Yes |
        | Forgot Password | POST | `/api/auth/forgot` | No |
        | Reset Password | POST | `/api/auth/reset` | No |
        | Delete Account | DELETE | `/api/auth/account` | Yes |
        | Get Profile | GET | `/api/users/me` | Yes |
        | Update Profile | PATCH | `/api/users/me` | Yes |
        | Get Stats | GET | `/api/users/me/stats` | Yes |
        | Complete Challenge | POST | `/api/challenges/complete` | Yes |
        | Get History | GET | `/api/challenges/history` | Yes |
        | Get Streak | GET | `/api/streaks` | Yes |
        | Get Achievements | GET | `/api/achievements` | Yes |
        | Check Achievements | POST | `/api/achievements/check` | Yes |
        | Get Reminders | GET | `/api/reminders` | Yes |
        | Create Reminder | POST | `/api/reminders` | Yes |
        | Update Reminder | PATCH | `/api/reminders/:id` | Yes |
        | Delete Reminder | DELETE | `/api/reminders/:id` | Yes |
        | Get Today's Tracking | GET | `/api/tracking/today` | Yes |
        | Update Tracking | PATCH | `/api/tracking/today` | Yes |
        | Register Push Token | POST | `/api/notifications/register` | Yes |
        | Unregister Push Token | DELETE | `/api/notifications/unregister` | Yes |

        ---

        *Document Version: 1.0*
        *Last Updated: December 3, 2024*
        *App Version: 1.3.0*
