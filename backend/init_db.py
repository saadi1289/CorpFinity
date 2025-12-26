#!/usr/bin/env python3
"""
Database initialization script for CorpFinity backend.
Run this script to create all tables in the database.
"""

import asyncio
from sqlalchemy import text
from core.database import async_engine, Base
from models.models import User, RefreshToken, ChallengeHistory, UserStreak, UserAchievement, Reminder, PushToken, DailyTracking


async def init_database():
    """Initialize database tables."""
    print("Creating database tables...")
    
    async with async_engine.begin() as conn:
        # Create all tables
        await conn.run_sync(Base.metadata.create_all)
    
    print("Database tables created successfully!")


async def drop_all_tables():
    """Drop all tables (use with caution!)."""
    print("Dropping all database tables...")
    
    async with async_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    print("All tables dropped!")


async def check_connection():
    """Check database connection."""
    print("Checking database connection...")
    
    async with async_engine.begin() as conn:
        result = await conn.execute(text("SELECT 1"))
        row = result.fetchone()
        if row and row[0] == 1:
            print("Database connection successful!")
            return True
        else:
            print("Database connection failed!")
            return False


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "drop":
            asyncio.run(drop_all_tables())
        elif sys.argv[1] == "check":
            success = asyncio.run(check_connection())
            sys.exit(0 if success else 1)
        else:
            print("Unknown command. Use 'init', 'drop', or 'check'")
            sys.exit(1)
    else:
        asyncio.run(init_database())
