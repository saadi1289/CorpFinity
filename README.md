# CorpFinity Flutter

A pixel-perfect Flutter conversion of the CorpFinity wellness application.

## Overview

CorpFinity is a corporate wellness platform featuring:
- Personalized wellness challenges
- Mood tracking
- Hydration monitoring
- Streak system
- Calendar-based insights
- Profile management

## Features Implemented

✅ **Authentication**: Login/Signup with email
✅ **Home Dashboard**: 
  - Mood tracker with contextual tips
  - Daily hydration tracking (8 glasses)
  - Quick relief challenges
  - Daily wisdom quotes
  - Floating hero card with animations

✅ **Wellness Flow**:
  - Goal selection (6 categories: stress, energy, sleep, fitness, eating, social)
  - Energy level selection (Low/Medium/High)
  - AI-powered challenge generation (with offline database fallback)
  - Timer with circular progress indicator
  - Challenge completion tracking

✅ **Challenges Page**:
  - Active goals with progress bars
  - Challenge history
  - Weekly challenge rewards

✅ **Insights Page**:
  - Streak tracking
  - Total sessions count
  - Calendar heatmap showing activity
  - Weekly activity graph

✅ **Profile Page**:
  - Edit profile (name, avatar)
  - Avatar randomization (DiceBear integration)
  - Settings (notifications, dark mode)
  - Logout functionality

## Technical Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod
- **Local Storage**: SharedPreferences
- **Fonts**: Plus Jakarta Sans (via Google Fonts)
- **Icons**: Lucide Icons Flutter
- **Animations**: Flutter implicit/explicit animations

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart 3.0 or higher

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. (Optional) Add your Gemini API key to `.env`:
   ```
   GEMINI_API_KEY=your_api_key_here
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart
└── src/
    ├── theme/           # Colors, typography, theme configuration
    ├── models/          # Data models (User, Challenge, etc.)
    ├── services/        # Auth, storage, challenge services
    ├── widgets/         # Reusable widgets (Button, Layout, Navbar)
    ├── pages/           # All app screens
    └── constants.dart   # App constants (goals, moods, quotes)
```

## Design Fidelity

This Flutter app is a pixel-perfect conversion of the React version:

- ✅ **Colors**: Exact hex values from Tailwind config
- ✅ **Typography**: Plus Jakarta Sans with matching weights
- ✅ **Spacing**: Matches Tailwind spacing scale (4px increments)
- ✅ **Border Radius**: Matches rounded-xl, rounded-2xl, etc.
- ✅ **Shadows**: Box shadows match original design
- ✅ **Animations**: Tap scale, page transitions, floating effects
- ✅ **Responsive**: Adapts to mobile/tablet/desktop

## Key Differences from React Version

1. **Hover Effects**: Mobile-focused, tap feedback instead of hover (desktop gets both)
2. **State Management**: Riverpod instead of React hooks/context
3. **Storage**: SharedPreferences instead of localStorage
4. **Routing**: Internal state switching instead of React Router (simpler for this app)

## Challenge Database

The app includes 18 pre-defined wellness challenges across 6 categories and 3 energy levels.
Challenges are stored locally and don't require an internet connection.

## Future Enhancements

- Dark mode implementation
- Push notifications
- Social sharing
- Achievement badges
- AI-powered challenge generation (Gemini API integration)

## License

This is a demonstration project.

## Acknowledgments

- Original React design
- DiceBear for avatar generation
- Lucide for icons
- Google Fonts for typography
