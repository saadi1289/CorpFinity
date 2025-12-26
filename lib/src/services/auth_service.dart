import '../models/user.dart';
import 'api_client.dart';
import 'storage_service.dart';
import 'result.dart';

class AuthService {
  final StorageService _storage = StorageService();
  final ApiClient _api = ApiClient();
  
  /// Register a new user
  Future<Result<User>> register(String email, String password, String name) async {
    try {
      final user = await _api.register(email, password, name);
      await _storage.saveUser(user);
      return Result.success(user);
    } catch (e) {
      return Result.failure('Registration failed: ${e.toString()}', e);
    }
  }
  
  /// Login with email and password
  Future<Result<User>> login(String email, String password) async {
    try {
      final user = await _api.login(email, password);
      await _storage.saveUser(user);
      return Result.success(user);
    } catch (e) {
      return Result.failure('Login failed: ${e.toString()}', e);
    }
  }
  
  /// Login with stored credentials (for offline support)
  Future<Result<User>> loginWithStoredCredentials() async {
    final userResult = await _storage.getUser();
    if (userResult.isFailure || userResult.dataOrNull == null) {
      return Result.failure('No stored credentials', null);
    }
    return userResult;
  }
  
  /// Update user profile
  Future<Result<User>> updateUser(User user) async {
    try {
      final updatedUser = await _api.updateProfile(
        name: user.name,
        avatar: user.avatar,
      );
      await _storage.saveUser(updatedUser);
      return Result.success(updatedUser);
    } catch (e) {
      return Result.failure('Update failed: ${e.toString()}', e);
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (e) {
      // Even if API call fails, clear local data
      debugPrint('Logout API call failed: $e');
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
    final user = await getUser();
    return user != null;
  }
  
  /// Refresh authentication token
  Future<Result<bool>> refreshAuth() async {
    try {
      await _api.refreshToken();
      return Result.success(true);
    } catch (e) {
      await logout();
      return Result.failure('Token refresh failed', e);
    }
  }
}
