import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();
  
  /// Simulates login with delay (1.5s) matching React app
  Future<User> login(String email, [String? name]) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Create formatted name from email if not provided
    final defaultName = email.split('@')[0];
    final capitalizedName = defaultName[0].toUpperCase() + defaultName.substring(1);
    final userName = name ?? capitalizedName;
    
    // Create user with DiceBear avatar
    final user = User(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: userName,
      email: email,
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=$email',
    );
    
    // Save to storage
    await _storage.saveUser(user);
    
    return user;
  }
  
  /// Update user profile
  Future<User> updateUser(User user) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    await _storage.saveUser(user);
    return user;
  }
  
  /// Logout user
  Future<void> logout() async {
    await _storage.removeUser();
  }
  
  /// Get currently logged in user
  Future<User?> getUser() async {
    final result = await _storage.getUser();
    return result.dataOrNull;
  }
}
