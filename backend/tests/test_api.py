"""
Tests for CorpFinity Backend API
Run with: pytest tests/ -v
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch
from api.index import app
from core.security import hash_password, create_access_token
from datetime import timedelta


@pytest.fixture
def test_client():
    """Create test client."""
    return TestClient(app)


@pytest.fixture
def test_user_id():
    """Create a test user ID."""
    return "test-user-id"


@pytest.fixture
def test_access_token(test_user_id):
    """Create a test access token."""
    return create_access_token(data={"sub": test_user_id})


@pytest.fixture
def auth_headers(test_access_token):
    """Create authorization headers."""
    return {"Authorization": f"Bearer {test_access_token}"}


class TestHealthEndpoints:
    """Tests for health check endpoints."""
    
    def test_root_endpoint(self, test_client):
        """Test root endpoint returns API info."""
        response = test_client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "CorpFinity API"
        assert data["version"] == "1.0.0"
    
    def test_health_endpoint(self, test_client):
        """Test health check endpoint."""
        response = test_client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
    
    def test_api_info_endpoint(self, test_client):
        """Test API info endpoint."""
        response = test_client.get("/api")
        assert response.status_code == 200
        data = response.json()
        assert "endpoints" in data
        assert "documentation" in data


class TestAuthEndpoints:
    """Tests for authentication endpoints."""
    
    def test_register_missing_fields(self, test_client):
        """Test registration with missing fields."""
        response = test_client.post(
            "/api/auth/register",
            json={"email": "test@example.com"}
        )
        assert response.status_code == 422
    
    def test_login_missing_fields(self, test_client):
        """Test login with missing fields."""
        response = test_client.post(
            "/api/auth/login",
            json={"email": "test@example.com"}
        )
        assert response.status_code == 422
    
    def test_me_without_token(self, test_client):
        """Test /auth/me endpoint without token."""
        response = test_client.get("/api/auth/me")
        assert response.status_code == 401
    
    def test_me_with_invalid_token(self, test_client):
        """Test /auth/me endpoint with invalid token."""
        response = test_client.get(
            "/api/auth/me",
            headers={"Authorization": "Bearer invalid-token"}
        )
        assert response.status_code == 401


class TestUserEndpoints:
    """Tests for user endpoints."""
    
    def test_get_user_without_auth(self, test_client):
        """Test getting user without authentication."""
        response = test_client.get("/api/users/me")
        assert response.status_code == 401
    
    def test_get_user_stats_without_auth(self, test_client):
        """Test getting user stats without authentication."""
        response = test_client.get("/api/users/me/stats")
        assert response.status_code == 401
    
    def test_update_user_without_auth(self, test_client):
        """Test updating user without authentication."""
        response = test_client.patch(
            "/api/users/me",
            json={"name": "New Name"}
        )
        assert response.status_code == 401


class TestChallengeEndpoints:
    """Tests for challenge endpoints."""
    
    def test_get_challenges_without_auth(self, test_client):
        """Test getting challenges without authentication."""
        response = test_client.get("/api/challenges/history")
        assert response.status_code == 401
    
    def test_complete_challenge_without_auth(self, test_client):
        """Test completing challenge without authentication."""
        response = test_client.post(
            "/api/challenges/complete",
            json={"title": "Test Challenge"}
        )
        assert response.status_code == 401


class TestStreakEndpoints:
    """Tests for streak endpoints."""
    
    def test_get_streak_without_auth(self, test_client):
        """Test getting streak without authentication."""
        response = test_client.get("/api/streaks")
        assert response.status_code == 401


class TestReminderEndpoints:
    """Tests for reminder endpoints."""
    
    def test_get_reminders_without_auth(self, test_client):
        """Test getting reminders without authentication."""
        response = test_client.get("/api/reminders")
        assert response.status_code == 401
    
    def test_create_reminder_without_auth(self, test_client):
        """Test creating reminder without authentication."""
        response = test_client.post(
            "/api/reminders",
            json={
                "type": "hydration",
                "title": "Water Reminder",
                "time_hour": 9,
                "time_minute": 0,
                "frequency": "daily"
            }
        )
        assert response.status_code == 401


class TestTrackingEndpoints:
    """Tests for tracking endpoints."""
    
    def test_get_today_tracking_without_auth(self, test_client):
        """Test getting today tracking without authentication."""
        response = test_client.get("/api/tracking/today")
        assert response.status_code == 401
    
    def test_increment_water_without_auth(self, test_client):
        """Test incrementing water without authentication."""
        response = test_client.post("/api/tracking/water?amount=250")
        assert response.status_code == 401


class TestAchievementEndpoints:
    """Tests for achievement endpoints."""
    
    def test_get_achievements_without_auth(self, test_client):
        """Test getting achievements without authentication."""
        response = test_client.get("/api/achievements")
        assert response.status_code == 401


class TestNotificationEndpoints:
    """Tests for notification endpoints."""
    
    def test_register_push_token_without_auth(self, test_client):
        """Test registering push token without authentication."""
        response = test_client.post(
            "/api/notifications/register",
            json={
                "token": "test-token",
                "platform": "android"
            }
        )
        assert response.status_code == 401


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
