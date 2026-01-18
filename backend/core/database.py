from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import sessionmaker, declarative_base
from core.config import settings, get_supabase_db_url, get_supabase_sync_url

# Synchronous engine for migrations and initial setup (Supabase)
sync_engine = create_engine(
    get_supabase_sync_url(),
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    echo=settings.DEBUG,  # Enable SQL logging in debug mode
)

SyncSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=sync_engine
)

# Async engine for FastAPI (Supabase with asyncpg)
async_engine = create_async_engine(
    get_supabase_db_url(),
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
    echo=settings.DEBUG,  # Enable SQL logging in debug mode
    pool_recycle=3600,  # Recycle connections every hour
)

AsyncSessionLocal = async_sessionmaker(
    bind=async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

Base = declarative_base()


async def get_db() -> AsyncSession:
    """Dependency to get async database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db() -> None:
    """Initialize database tables in Supabase."""
    try:
        async with async_engine.begin() as conn:
            # Create all tables
            await conn.run_sync(Base.metadata.create_all)
            print("✅ Database tables created successfully in Supabase")
    except Exception as e:
        print(f"❌ Error creating database tables: {e}")
        raise


async def close_db() -> None:
    """Close database connections."""
    await async_engine.dispose()
    print("✅ Database connections closed")


async def health_check_db() -> bool:
    """Check if database connection is healthy."""
    try:
        async with AsyncSessionLocal() as session:
            await session.execute("SELECT 1")
            return True
    except Exception as e:
        print(f"❌ Database health check failed: {e}")
        return False
