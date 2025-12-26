import redis.asyncio as redis
from typing import Optional
from core.config import settings


class RedisClient:
    """Async Redis client for caching and session management."""
    
    _instance: Optional["RedisClient"] = None
    _client: Optional[redis.Redis] = None
    
    def __new__(cls) -> "RedisClient":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    async def connect(self) -> None:
        """Connect to Redis server."""
        if self._client is None:
            self._client = redis.from_url(
                settings.REDIS_URL,
                password=settings.REDIS_PASSWORD,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
            )
    
    async def disconnect(self) -> None:
        """Disconnect from Redis server."""
        if self._client:
            await self._client.close()
            self._client = None
    
    async def get(self, key: str) -> Optional[str]:
        """Get a value from Redis."""
        if self._client:
            return await self._client.get(key)
        return None
    
    async def set(
        self,
        key: str,
        value: str,
        ex: Optional[int] = None,
        px: Optional[int] = None,
    ) -> bool:
        """Set a value in Redis with optional expiry."""
        if self._client:
            return await self._client.set(key, value, ex=ex, px=px)
        return False
    
    async def delete(self, *keys: str) -> int:
        """Delete one or more keys from Redis."""
        if self._client:
            return await self._client.delete(*keys)
        return 0
    
    async def exists(self, *keys: str) -> int:
        """Check if keys exist in Redis."""
        if self._client:
            return await self._client.exists(*keys)
        return 0
    
    async def incr(self, key: str) -> int:
        """Increment a value in Redis."""
        if self._client:
            return await self._client.incr(key)
        return 0
    
    async def expire(self, key: str, seconds: int) -> bool:
        """Set expiry on a key."""
        if self._client:
            return await self._client.expire(key, seconds)
        return False
    
    # Token blacklist operations
    async def add_to_blacklist(self, token: str, ttl: int = 3600) -> None:
        """Add a token to the blacklist."""
        await self.set(f"blacklist:{token}", "1", ex=ttl)
    
    async def is_blacklisted(self, token: str) -> bool:
        """Check if a token is blacklisted."""
        result = await self.get(f"blacklist:{token}")
        return result is not None
    
    # Rate limiting
    async def check_rate_limit(
        self,
        user_id: str,
        limit: int = 100,
        window: int = 3600
    ) -> tuple[bool, int]:
        """Check rate limit for a user. Returns (allowed, remaining)."""
        key = f"ratelimit:{user_id}"
        
        # Increment counter
        current = await self.incr(key)
        
        # Set expiry on first request
        if current == 1:
            await self.expire(key, window)
        
        remaining = max(0, limit - current)
        allowed = current <= limit
        
        return allowed, remaining
    
    # Cache operations with prefix
    async def cache_get(self, prefix: str, key: str) -> Optional[str]:
        """Get a cached value with prefix."""
        return await self.get(f"{prefix}:{key}")
    
    async def cache_set(
        self,
        prefix: str,
        key: str,
        value: str,
        ttl: int = 300
    ) -> bool:
        """Set a cached value with prefix."""
        return await self.set(f"{prefix}:{key}", value, ex=ttl)
    
    async def cache_delete(self, prefix: str, key: str) -> int:
        """Delete a cached value with prefix."""
        return await self.delete(f"{prefix}:{key}")
    
    async def clear_cache(self, prefix: str) -> None:
        """Clear all cache entries with a prefix."""
        if self._client:
            pattern = f"{prefix}:*"
            async for key in self._client.scan_iter(match=pattern):
                await self.delete(key)


# Global Redis client instance
redis_client = RedisClient()


async def get_redis() -> RedisClient:
    """Dependency to get Redis client."""
    await redis_client.connect()
    return redis_client
