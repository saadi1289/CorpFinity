from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional, List
from core.database import get_db
from load_challenges import ChallengeDefinition
from schemas.schemas import ErrorResponse
from api.auth import get_optional_user
import random


router = APIRouter(prefix="/challenge-db", tags=["Challenge Database"])


@router.get(
    "/categories",
    response_model=List[str],
)
async def get_challenge_categories(
    db: AsyncSession = Depends(get_db),
):
    """Get all available challenge categories (pillars)."""
    result = await db.execute(
        select(ChallengeDefinition.pillar).distinct()
    )
    categories = [row[0] for row in result.fetchall()]
    return categories


@router.get(
    "/challenges",
)
async def get_challenges(
    pillar: Optional[str] = Query(None, description="Filter by pillar/category"),
    energy_level: Optional[str] = Query(None, description="Filter by energy level (LOW, MEDIUM, HIGH)"),
    limit: int = Query(10, ge=1, le=100, description="Number of challenges to return"),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_optional_user),
):
    """Get challenges from the database with optional filtering."""
    
    query = select(ChallengeDefinition)
    
    if pillar:
        query = query.where(ChallengeDefinition.pillar == pillar)
    
    if energy_level:
        query = query.where(ChallengeDefinition.energy_level == energy_level.upper())
    
    query = query.limit(limit)
    
    result = await db.execute(query)
    challenges = result.scalars().all()
    
    return [
        {
            "id": str(challenge.id),
            "title": challenge.title,
            "description": challenge.description,
            "duration": challenge.duration,
            "steps": challenge.steps,
            "emoji": challenge.emoji,
            "pillar": challenge.pillar,
            "energy_level": challenge.energy_level,
            "challenge_number": challenge.challenge_number,
        }
        for challenge in challenges
    ]


@router.get(
    "/random",
)
async def get_random_challenge(
    pillar: Optional[str] = Query(None, description="Filter by pillar/category"),
    energy_level: Optional[str] = Query(None, description="Filter by energy level"),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_optional_user),
):
    """Get a random challenge with optional filtering."""
    
    query = select(ChallengeDefinition)
    
    if pillar:
        query = query.where(ChallengeDefinition.pillar == pillar)
    
    if energy_level:
        query = query.where(ChallengeDefinition.energy_level == energy_level.upper())
    
    result = await db.execute(query)
    challenges = result.scalars().all()
    
    if not challenges:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No challenges found matching criteria",
        )
    
    challenge = random.choice(challenges)
    
    return {
        "id": str(challenge.id),
        "title": challenge.title,
        "description": challenge.description,
        "duration": challenge.duration,
        "steps": challenge.steps,
        "emoji": challenge.emoji,
        "pillar": challenge.pillar,
        "energy_level": challenge.energy_level,
        "challenge_number": challenge.challenge_number,
    }


@router.get(
    "/stats",
)
async def get_challenge_stats(
    db: AsyncSession = Depends(get_db),
):
    """Get statistics about the challenge database."""
    
    # Total challenges
    total_result = await db.execute(
        select(ChallengeDefinition.id).count()
    )
    total = total_result.scalar()
    
    # By pillar
    pillar_result = await db.execute(
        select(ChallengeDefinition.pillar, ChallengeDefinition.id.count())
        .group_by(ChallengeDefinition.pillar)
    )
    by_pillar = {row[0]: row[1] for row in pillar_result.fetchall()}
    
    # By energy level
    energy_result = await db.execute(
        select(ChallengeDefinition.energy_level, ChallengeDefinition.id.count())
        .group_by(ChallengeDefinition.energy_level)
    )
    by_energy = {row[0]: row[1] for row in energy_result.fetchall()}
    
    return {
        "total_challenges": total,
        "by_pillar": by_pillar,
        "by_energy_level": by_energy,
    }