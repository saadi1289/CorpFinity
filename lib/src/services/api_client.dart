import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/challenge.dart';
import '../models/reminder.dart';
import 'result.dart';

class ApiClient {
  // Use environment variable for API URL, fallback to localhost for development
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL', 
    defaultValue: 'http://localhost:8000/api'
  );
  
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  final http.Client _client = http.Client();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Get stored auth token
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Get stored refresh token
  Future<String?> _getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Store auth tokens
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Clear stored tokens
  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  /// Get headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  /// Handle HTTP response
  Result<Map<String, dynamic>> _handleResponse(http.Response response) {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Result.success(data);
      } else {
        final error = data['detail'] ?? 'Unknown error occurred';
        return Result.failure(error);
      }
    } catch (e) {
      return Result.failure('Failed to parse response: $e');
    }
  }

  /// Make authenticated request with token refresh
  Future<Result<Map<String, dynamic>>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    bool isRetry = false,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(url, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(url, headers: headers);
          break;
        default:
          return Result.failure('Unsupported HTTP method: $method');
      }

      // Handle token expiration
      if (response.statusCode == 401 && includeAuth && !isRetry) {
        final refreshResult = await _refreshToken();
        if (refreshResult.isSuccess) {
          // Retry the request with new token
          return await _makeRequest(method, endpoint, body: body, includeAuth: includeAuth, isRetry: true);
        } else {
          await _clearTokens();
          return Result.failure('Authentication failed. Please login again.');
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return Result.failure('No internet connection. Please check your network.');
    } on HttpException {
      return Result.failure('Network error occurred. Please try again.');
    } catch (e) {
      return Result.failure('Request failed: $e');
    }
  }

  /// Refresh access token
  Future<Result<void>> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        return Result.failure('No refresh token available');
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      final result = _handleResponse(response);
      if (result.isSuccess) {
        final data = result.data!;
        await _storeTokens(data['access_token'], data['refresh_token']);
        return Result.success(null);
      } else {
        return Result.failure(result.errorMessage!);
      }
    } catch (e) {
      return Result.failure('Token refresh failed: $e');
    }
  }

  // ==================== AUTH ENDPOINTS ====================

  /// Register new user
  Future<Result<User>> register(String email, String password, String name) async {
    final result = await _makeRequest(
      'POST',
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'name': name,
      },
      includeAuth: false,
    );

    if (result.isSuccess) {
      final data = result.data!;
      await _storeTokens(data['access_token'], data['refresh_token']);
      return Result.success(User.fromJson(data['user']));
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Login user
  Future<Result<User>> login(String email, String password) async {
    final result = await _makeRequest(
      'POST',
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      includeAuth: false,
    );

    if (result.isSuccess) {
      final data = result.data!;
      await _storeTokens(data['access_token'], data['refresh_token']);
      return Result.success(User.fromJson(data['user']));
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Logout user
  Future<Result<void>> logout() async {
    final refreshToken = await _getRefreshToken();
    
    if (refreshToken != null) {
      await _makeRequest(
        'POST',
        '/auth/logout',
        body: {'refresh_token': refreshToken},
      );
    }
    
    await _clearTokens();
    return Result.success(null);
  }

  /// Get current user
  Future<Result<User>> getCurrentUser() async {
    final result = await _makeRequest('GET', '/auth/me');
    
    if (result.isSuccess) {
      return Result.success(User.fromJson(result.data!));
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Forgot password
  Future<Result<void>> forgotPassword(String email) async {
    final result = await _makeRequest(
      'POST',
      '/auth/forgot',
      body: {'email': email},
      includeAuth: false,
    );

    if (result.isSuccess) {
      return Result.success(null);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  // ==================== USER ENDPOINTS ====================

  /// Update user profile
  Future<Result<User>> updateProfile({String? name, String? avatar}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatar != null) body['avatar'] = avatar;

    final result = await _makeRequest('PATCH', '/users/me', body: body);
    
    if (result.isSuccess) {
      return Result.success(User.fromJson(result.data!));
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Get user statistics
  Future<Result<Map<String, dynamic>>> getUserStats() async {
    final result = await _makeRequest('GET', '/users/me/stats');
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Delete user account
  Future<Result<void>> deleteAccount() async {
    final result = await _makeRequest('DELETE', '/users/me');
    
    if (result.isSuccess) {
      await _clearTokens();
      return Result.success(null);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  // ==================== CHALLENGE ENDPOINTS ====================

  /// Complete a challenge
  Future<Result<void>> completeChallenge(GeneratedChallenge challenge) async {
    final result = await _makeRequest(
      'POST',
      '/challenges/complete',
      body: {
        'title': challenge.title,
        'description': challenge.description,
        'duration': challenge.duration,
        'emoji': challenge.emoji,
        'fun_fact': challenge.funFact,
        'goal_category': challenge.goalCategory,
        'energy_level': challenge.energyLevel,
      },
    );

    if (result.isSuccess) {
      return Result.success(null);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Get challenge history
  Future<Result<List<Map<String, dynamic>>>> getChallengeHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _makeRequest(
      'GET',
      '/challenges/history?page=$page&page_size=$pageSize',
    );

    if (result.isSuccess) {
      final items = result.data!['items'] as List;
      return Result.success(items.cast<Map<String, dynamic>>());
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Get today's challenges
  Future<Result<List<Map<String, dynamic>>>> getTodayChallenges() async {
    final result = await _makeRequest('GET', '/challenges/today');
    
    if (result.isSuccess) {
      return Result.success((result.data! as List).cast<Map<String, dynamic>>());
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  // ==================== STREAK ENDPOINTS ====================

  /// Get current streak
  Future<Result<Map<String, dynamic>>> getStreak() async {
    final result = await _makeRequest('GET', '/streaks');
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Validate streak
  Future<Result<Map<String, dynamic>>> validateStreak() async {
    final result = await _makeRequest('POST', '/streaks/validate');
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  // ==================== ACHIEVEMENT ENDPOINTS ====================

  /// Get achievements
  Future<Result<Map<String, dynamic>>> getAchievements() async {
    final result = await _makeRequest('GET', '/achievements');
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Check for new achievements
  Future<Result<Map<String, dynamic>>> checkAchievements() async {
    final result = await _makeRequest('POST', '/achievements/check');
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  // ==================== REMINDER ENDPOINTS ====================

  /// Get reminders
  Future<Result<List<Map<String, dynamic>>>> getReminders() async {
    final result = await _makeRequest('GET', '/reminders');
    
    if (result.isSuccess) {
      final reminders = result.data!['reminders'] as List;
      return Result.success(reminders.cast<Map<String, dynamic>>());
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Create reminder
  Future<Result<Map<String, dynamic>>> createReminder(Reminder reminder) async {
    final result = await _makeRequest(
      'POST',
      '/reminders',
      body: reminder.toJson(),
    );

    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Update reminder
  Future<Result<Map<String, dynamic>>> updateReminder(Reminder reminder) async {
    final result = await _makeRequest(
      'PATCH',
      '/reminders/${reminder.id}',
      body: reminder.toJson(),
    );

    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Delete reminder
  Future<Result<void>> deleteReminder(String reminderId) async {
    final result = await _makeRequest('DELETE', '/reminders/$reminderId');
    
    if (result.isSuccess) {
      return Result.success(null);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Toggle reminder
  Future<Result<Map<String, dynamic>>> toggleReminder(String reminderId) async {
    final result = await _makeRequest('POST', '/reminders/$reminderId/toggle');
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  // ==================== TRACKING ENDPOINTS ====================

  /// Get today's tracking data
  Future<Result<Map<String, dynamic>>> getTodayTracking() async {
    final result = await _makeRequest('GET', '/tracking/today');
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Update today's tracking data
  Future<Result<Map<String, dynamic>>> updateTodayTracking(Map<String, dynamic> data) async {
    final result = await _makeRequest('PATCH', '/tracking/today', body: data);
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Increment water intake
  Future<Result<Map<String, dynamic>>> incrementWater({int amount = 250}) async {
    final result = await _makeRequest(
      'POST',
      '/tracking/water',
      body: {'amount': amount},
    );
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Set mood
  Future<Result<Map<String, dynamic>>> setMood(String mood) async {
    final result = await _makeRequest(
      'POST',
      '/tracking/mood',
      body: {'mood': mood},
    );
    
    if (result.isSuccess) {
      return Result.success(result.data!);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  // ==================== NOTIFICATION ENDPOINTS ====================

  /// Register push token
  Future<Result<void>> registerPushToken(String token, String platform) async {
    final result = await _makeRequest(
      'POST',
      '/notifications/register',
      body: {
        'token': token,
        'platform': platform,
      },
    );

    if (result.isSuccess) {
      return Result.success(null);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Unregister push token
  Future<Result<void>> unregisterPushToken(String token) async {
    final result = await _makeRequest(
      'DELETE',
      '/notifications/unregister?token=$token',
    );

    if (result.isSuccess) {
      return Result.success(null);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  /// Send test notification
  Future<Result<void>> sendTestNotification() async {
    final result = await _makeRequest('POST', '/notifications/test');
    
    if (result.isSuccess) {
      return Result.success(null);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null;
  }

  /// Get API base URL (for configuration)
  String get baseUrl => _baseUrl;

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
