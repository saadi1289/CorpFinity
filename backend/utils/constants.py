from typing import Dict, List
from datetime import datetime, date

# Static challenges data
WELLNESS_CHALLENGES = [
    {
        "title": "Deep Breathing",
        "description": "Take 5 deep breaths, focusing on your inhalation and exhalation.",
        "duration": "2 min",
        "emoji": "🌬️",
        "fun_fact": "Deep breathing can reduce stress hormones in just a few minutes.",
        "goal_category": "breathing",
        "energy_level": "low"
    },
    {
        "title": "Desk Stretch",
        "description": "Reach your arms overhead and stretch your back.",
        "duration": "1 min",
        "emoji": "💪",
        "fun_fact": "Regular stretching can improve your posture and reduce back pain.",
        "goal_category": "stretch",
        "energy_level": "medium"
    },
    {
        "title": "Mindful Minute",
        "description": "Close your eyes and focus on the present moment.",
        "duration": "1 min",
        "emoji": "🧘",
        "fun_fact": "Just 60 seconds of mindfulness can lower blood pressure.",
        "goal_category": "meditation",
        "energy_level": "low"
    },
    {
        "title": "Eye Rest",
        "description": "Look away from your screen and focus on something 20 feet away.",
        "duration": "20 sec",
        "emoji": "👀",
        "fun_fact": "The 20-20-20 rule helps prevent digital eye strain.",
        "goal_category": "break",
        "energy_level": "low"
    },
    {
        "title": "Water Break",
        "description": "Stand up and drink a glass of water.",
        "duration": "1 min",
        "emoji": "💧",
        "fun_fact": "Staying hydrated improves brain function and energy levels.",
        "goal_category": "hydration",
        "energy_level": "low"
    },
    {
        "title": "Gratitude Moment",
        "description": "Think of three things you're grateful for today.",
        "duration": "2 min",
        "emoji": "🙏",
        "fun_fact": "Practicing gratitude can increase long-term happiness by 25%.",
        "goal_category": "mindfulness",
        "energy_level": "low"
    },
    {
        "title": "Posture Check",
        "description": "Sit up straight, shoulders back, chin parallel to the ground.",
        "duration": "30 sec",
        "emoji": "🪑",
        "fun_fact": "Good posture can boost your confidence and mood.",
        "goal_category": "posture",
        "energy_level": "low"
    },
    {
        "title": "Shoulder Roll",
        "description": "Roll your shoulders in circular motions to release tension.",
        "duration": "1 min",
        "emoji": "🔄",
        "fun_fact": "Shoulder rolls can help relieve tension from sitting at a desk.",
        "goal_category": "stretch",
        "energy_level": "low"
    },
    {
        "title": "Neck Stretch",
        "description": "Gently tilt your head from side to side.",
        "duration": "1 min",
        "emoji": "😌",
        "fun_fact": "Neck stretches can help alleviate headaches caused by tension.",
        "goal_category": "stretch",
        "energy_level": "low"
    },
    {
        "title": "Wrist Exercise",
        "description": "Rotate your wrists and stretch your fingers.",
        "duration": "1 min",
        "emoji": "✋",
        "fun_fact": "Wrist exercises can prevent carpal tunnel syndrome.",
        "goal_category": "break",
        "energy_level": "low"
    },
]


def get_challenges_by_category(category: str) -> List[Dict]:
    """Get challenges filtered by category."""
    return [c for c in WELLNESS_CHALLENGES if c["goal_category"] == category]


def get_random_challenge(category: str = None) -> Dict:
    """Get a random challenge, optionally filtered by category."""
    import random
    challenges = WELLNESS_CHALLENGES
    if category:
        challenges = get_challenges_by_category(category)
    return random.choice(challenges)


# Daily quotes
DAILY_QUOTES = [
    {"text": "Wellness is not a destination, it's a way of life.", "author": "Unknown"},
    {"text": "Take care of your body. It's the only place you have to live.", "author": "Jim Rohn"},
    {"text": "A healthy outside starts from the inside.", "author": "Unknown"},
    {"text": "The greatest wealth is health.", "author": "Virgil"},
    {"text": "Wellness is the natural state of my body.", "author": "Unknown"},
    {"text": "Success is the sum of small efforts, repeated day in and day out.", "author": "Robert Collier"},
    {"text": "Your health is an investment, not an expense.", "author": "Unknown"},
    {"text": "The only way to do great work is to love what you do.", "author": "Steve Jobs"},
]

# Mood options
MOODS = ["😄", "🙂", "😐", "😔", "😡", "😴", "🤔", "😊"]

# Hydration goals (ml)
HYDRATION_GOALS = [500, 1000, 1500, 2000, 2500, 3000]
