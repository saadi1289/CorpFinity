import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'storage_service.dart';
import 'result.dart';

class AuthService {
  final StorageService _storage = StorageService();
  final ApiClient _api = ApiClient();
  
  /// Register a new user
  Future<Result<User>> register(String email, String password, String name) async {
    final result = await _api.register(email, password, name);
    
    if (result.isSuccess) {
      await _storage.saveUser(result.data);
      return Result.success(result.data);
    } else {
      return Result.failure(result.errorMessage ?? 'Registration failed');
    }
  }
  
  /// Login with email and password
  Future<Result<User>> login(String email, String password) async {
    final result = await _api.login(email, password);
    
    if (result.isSuccess) {
      await _storage.saveUser(result.data);
      return Result.success(result.data);
    } else {
      return Result.failure(result.errorMessage ?? 'Login failed');
    }
  }
  
  /// Login with stored credentials (for offline support)
  Future<Result<User>> loginWithStoredCredentials() async {
    final userResult = await _storage.getUser();
    if (userResult.isFailure || userResult.dataOrNull == null) {
      return Result.failure('No stored credentials');
    }
    
    // Try to validate with backend
    final currentUserResult = await _api.getCurrentUser();
    if (currentUserResult.isSuccess) {
      await _storage.saveUser(currentUserResult.data);
      return Result.success(currentUserResult.data);
    }
    
    // Fallback to stored user if backend is unavailable
    return Result.success(userResult.dataOrNull!);
  }
  
  /// Update user profile
  Future<Result<User>> updateUser(User user) async {
    final result = await _api.updateProfile(
      name: user.name,
      avatar: user.avatar,
    );
    
    if (result.isSuccess) {
      await _storage.saveUser(result.data);
      return Result.success(result.data);
    } else {
      return Result.failure(result.errorMessage ?? 'Update failed');
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    final result = await _api.logout();
    if (result.isFailure) {
      // Even if API call fails, clear local data
      debugPrint('Logout API call failed: ${result.errorMessage}');
    }
    await _storage.removeUser();
  }
  
  /// Get currently logged in user
  Future<User?> getUser() async {
    final result = await _storage.getUser();
    return result.dataOrNull;
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    // Check both local storage and API token
    final user = await getUser();
    if (user == null) return false;
    
    return await _api.isAuthenticated();
  }
  
  /// Refresh authentication token
  Future<Result<bool>> refreshAuth() async {
    // The API client handles token refresh automatically
    final currentUserResult = await _api.getCurrentUser();
    
    if (currentUserResult.isSuccess) {
      await _storage.saveUser(currentUserResult.data);
      return Result.success(true);
    } else {
      await logout();
      return Result.failure('Authentication failed');
    }
  }
  
  /// Forgot password
  Future<Result<void>> forgotPassword(String email) async {
    return await _api.forgotPassword(email);
  }
  
  /// Delete account
  Future<Result<void>> deleteAccount() async {
    final result = await _api.deleteAccount();
    
    if (result.isSuccess) {
      await _storage.removeUser();
      return Result.success(null);
    } else {
      return Result.failure(result.errorMessage!);
    }
  }
}
