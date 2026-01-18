#!/usr/bin/env python3
"""
Migration script to set up Supabase database with all tables and initial data.
Run this after updating your environment variables with Supabase credentials.
"""

import asyncio
import sys
from pathlib import Path

# Add backend to Python path
sys.path.append(str(Path(__file__).parent))

from core.database import init_db, health_check_db
from core.config import settings
from models.models import *  # Import all models to register them with SQLAlchemy


async def migrate_to_supabase():
    """Migrate database schema to Supabase."""
    
    print("🚀 Starting Supabase migration...")
    print(f"📍 Supabase URL: {settings.SUPABASE_URL}")
    print(f"🔧 Environment: {settings.ENVIRONMENT}")
    
    # Check database connection
    print("\n1️⃣ Checking database connection...")
    if not await health_check_db():
        print("❌ Cannot connect to Supabase database!")
        print("Please check your DATABASE_URL in .env file")
        return False
    
    print("✅ Database connection successful!")
    
    # Create all tables
    print("\n2️⃣ Creating database tables...")
    try:
        await init_db()
        print("✅ All tables created successfully!")
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        return False
    
    # Verify tables were created
    print("\n3️⃣ Verifying table creation...")
    try:
        from core.database import AsyncSessionLocal
        async with AsyncSessionLocal() as session:
            # Test each table
            tables_to_test = [
                ("users", User),
                ("refresh_tokens", RefreshToken),
                ("challenge_history", ChallengeHistory),
                ("user_streaks", UserStreak),
                ("achievement_definitions", AchievementDefinition),
                ("user_achievements", UserAchievement),
                ("reminders", Reminder),
                ("push_tokens", PushToken),
                ("daily_tracking", DailyTracking),
            ]
            
            for table_name, model in tables_to_test:
                result = await session.execute(f"SELECT COUNT(*) FROM {table_name}")
                count = result.scalar()
                print(f"  ✅ {table_name}: {count} records")
                
    except Exception as e:
        print(f"❌ Error verifying tables: {e}")
        return False
    
    print("\n🎉 Migration completed successfully!")
    print("\n📋 Next steps:")
    print("1. Update your Flutter app's API URL to point to your Render deployment")
    print("2. Deploy to Render using the render.yaml configuration")
    print("3. Set environment variables in Render dashboard")
    print("4. Test all API endpoints")
    
    return True


if __name__ == "__main__":
    success = asyncio.run(migrate_to_supabase())
    sys.exit(0 if success else 1)