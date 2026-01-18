#!/usr/bin/env python3
"""
Load challenges from challenges.csv into the database.
This script reads the CSV file and populates a challenges table.
"""

import asyncio
import csv
import os
from sqlalchemy import Column, String, Text, Integer
from sqlalchemy.dialects.postgresql import UUID
from core.database import async_engine, Base
import uuid


class ChallengeDefinition(Base):
    """Challenge definitions table for storing CSV data."""
    
    __tablename__ = "challenge_definitions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pillar = Column(String(50), nullable=False)  # Goal category
    energy_level = Column(String(20), nullable=False)  # LOW, MEDIUM, HIGH
    challenge_number = Column(Integer, nullable=False)
    title = Column(String(200), nullable=False)
    duration = Column(String(50), nullable=False)
    description = Column(Text, nullable=False)
    steps = Column(Text, nullable=True)
    emoji = Column(String(10), nullable=True, default="🧘")
    
    def __repr__(self):
        return f"<ChallengeDefinition(title={self.title}, pillar={self.pillar})>"


async def create_challenges_table():
    """Create the challenge definitions table."""
    async with async_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("✅ Challenge definitions table created")


async def load_challenges_from_csv():
    """Load challenges from CSV file into database."""
    csv_path = os.path.join(os.path.dirname(__file__), "..", "challenges.csv")
    
    if not os.path.exists(csv_path):
        print(f"❌ CSV file not found: {csv_path}")
        return
    
    challenges = []
    
    with open(csv_path, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        
        for row in reader:
            # Map CSV columns to database fields
            challenge = ChallengeDefinition(
                pillar=row['Pillar'].strip(),
                energy_level=row['Energy Level'].strip(),
                challenge_number=int(row['Challenge #']),
                title=row['Challenge Name'].strip(),
                duration=row['Duration'].strip(),
                description=row['Description'].strip(),
                steps=row.get('Steps', '').strip() if row.get('Steps') else None,
            )
            
            # Add emoji based on pillar
            emoji_map = {
                'Stress Reduction': '🌬️',
                'Increased Energy': '⚡',
                'Better Sleep': '😴',
                'Physical Fitness': '💪',
                'Healthy Eating': '🍏',
                'Social Connection': '🤝',
            }
            challenge.emoji = emoji_map.get(challenge.pillar, '🧘')
            
            challenges.append(challenge)
    
    # Insert into database
    from sqlalchemy.ext.asyncio import AsyncSession
    from core.database import get_db
    
    async with async_engine.begin() as conn:
        # Clear existing challenges
        await conn.execute("DELETE FROM challenge_definitions")
        
        # Insert new challenges
        for challenge in challenges:
            await conn.execute(
                challenge_definitions.insert().values(
                    id=challenge.id,
                    pillar=challenge.pillar,
                    energy_level=challenge.energy_level,
                    challenge_number=challenge.challenge_number,
                    title=challenge.title,
                    duration=challenge.duration,
                    description=challenge.description,
                    steps=challenge.steps,
                    emoji=challenge.emoji,
                )
            )
    
    print(f"✅ Loaded {len(challenges)} challenges from CSV")


async def main():
    """Main function to load challenges."""
    print("🚀 Loading challenges from CSV...")
    
    # Create table
    await create_challenges_table()
    
    # Load data
    await load_challenges_from_csv()
    
    print("✅ Challenge loading complete!")


if __name__ == "__main__":
    asyncio.run(main())