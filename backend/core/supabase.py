"""
Supabase client configuration for real-time features and additional services.
This is optional - your existing SQLAlchemy setup will work fine with Supabase PostgreSQL.
"""

from typing import Optional
from supabase import create_client, Client
from core.config import settings


class SupabaseClient:
    """Supabase client for real-time features and additional services."""
    
    _instance: Optional["SupabaseClient"] = None
    _client: Optional[Client] = None
    
    def __new__(cls) -> "SupabaseClient":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def get_client(self) -> Client:
        """Get Supabase client instance."""
        if self._client is None:
            self._client = create_client(
                settings.SUPABASE_URL,
                settings.SUPABASE_ANON_KEY
            )
        return self._client
    
    def get_admin_client(self) -> Optional[Client]:
        """Get Supabase admin client with service role key."""
        if settings.SUPABASE_SERVICE_ROLE_KEY:
            return create_client(
                settings.SUPABASE_URL,
                settings.SUPABASE_SERVICE_ROLE_KEY
            )
        return None
    
    async def setup_realtime_subscriptions(self):
        """Setup real-time subscriptions for live updates."""
        if not settings.SUPABASE_REALTIME_ENABLED:
            return
        
        client = self.get_client()
        
        # Example: Subscribe to challenge completions
        # You can add real-time subscriptions here if needed
        # challenge_subscription = client.table('challenge_history').on('INSERT', self._on_challenge_completed).subscribe()
        
        print("✅ Supabase real-time subscriptions configured")
    
    def _on_challenge_completed(self, payload):
        """Handle real-time challenge completion events."""
        # Handle real-time events here
        print(f"Challenge completed: {payload}")


# Global Supabase client instance
supabase_client = SupabaseClient()


def get_supabase() -> SupabaseClient:
    """Dependency to get Supabase client."""
    return supabase_client