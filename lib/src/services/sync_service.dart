import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/challenge.dart';
import '../models/reminder.dart';
import 'api_client.dart';
import 'storage_service.dart';
import 'result.dart';

/// Service that handles synchronization between local storage and backend API
/// Provides offline-first functionality with automatic sync when online
class SyncService {
  final ApiClient _api = ApiClient();
  final StorageService _storage = StorageService();
  
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isOnline = true;
  final List<Map<String, dynamic>> _pendingOperations = [];

  /// Check if we're currently online (has successful API connection)
  bool get isOnline => _isOnline;

  /// Get user data with API sync
  Future<Result<User?>> getUser() async {
    try {
      // Try to get fresh data from API
      final apiResult = await _api.getCurrentUser();
      if (apiResult.isSuccess) {
        _isOnline = true;
        // Save to local storage for offline access
        await _storage.saveUser(apiResult.data!);
        return Result.success(apiResult.data!);
      }
    } catch (e) {
      debugPrint('API call failed, using local data: $e');
    }

    // Fallback to local storage
    _isOnline = false;
    final localResult = await _storage.getUser();
    return localResult;
  }

  /// Update user profile with sync
  Future<Result<User>> updateUser(User user) async {
    // Always save locally first
    await _storage.saveUser(user);

    try {
      // Try to sync with API
      final apiResult = await _api.updateProfile(
        name: user.name,
        avatar: user.avatar,
      );
      
      if (apiResult.isSuccess) {
        _isOnline = true;
        // Update local storage with server response
        await _storage.saveUser(apiResult.data!);
        return Result.success(apiResult.data!);
      }
    } catch (e) {
      debugPrint('Failed to sync user update: $e');
      // Queue for later sync
      await _queueOperation('update_user', user.toJson());
    }

    _isOnline = false;
    return Result.success(user);
  }

  /// Complete challenge with sync
  Future<Result<void>> completeChallenge(GeneratedChallenge challenge) async {
    // Always save locally first
    final challengeHistory = ChallengeHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      completedAt: DateTime.now(),
      title: challenge.title,
      duration: challenge.duration,
      emoji: challenge.emoji,
      description: challenge.description,
      funFact: challenge.funFact,
      goalCategory: challenge.goalCategory,
      energyLevel: challenge.energyLevel,
    );
    
    await _storage.saveChallenge(challengeHistory);

    try {
      // Try to sync with API
      final apiResult = await _api.completeChallenge(challenge);
      
      if (apiResult.isSuccess) {
        _isOnline = true;
        // Check for new achievements
        _checkAchievementsAsync();
        return Result.success(null);
      }
    } catch (e) {
      debugPrint('Failed to sync challenge completion: $e');
      // Queue for later sync
      await _queueOperation('complete_challenge', {
        'title': challenge.title,
        'description': challenge.description,
        'duration': challenge.duration,
        'emoji': challenge.emoji,
        'fun_fact': challenge.funFact,
        'goal_category': challenge.goalCategory,
        'energy_level': challenge.energyLevel,
      });
    }

    _isOnline = false;
    return Result.success(null);
  }

  /// Get challenge history with sync
  Future<Result<List<ChallengeHistoryItem>>> getChallengeHistory() async {
    try {
      // Try to get fresh data from API
      final apiResult = await _api.getChallengeHistory();
      if (apiResult.isSuccess) {
        _isOnline = true;
        // Convert API data to local models and cache
        final challenges = apiResult.data!.map((item) => 
          ChallengeHistoryItem(
            id: item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            completedAt: DateTime.parse(item['completed_at'] ?? DateTime.now().toIso8601String()),
            title: item['title'] ?? '',
            duration: item['duration'] ?? '',
            emoji: item['emoji'] ?? '✨',
            description: item['description'] ?? '',
            funFact: item['fun_fact'],
            goalCategory: item['goal_category'],
            energyLevel: item['energy_level'],
          )
        ).toList();
        
        // Cache locally
        for (final challenge in challenges) {
          await _storage.saveChallenge(challenge);
        }
        
        return Result.success(challenges);
      }
    } catch (e) {
      debugPrint('API call failed, using local data: $e');
    }

    // Fallback to local storage
    _isOnline = false;
    return await _storage.getChallengeHistory();
  }

  /// Get streak data with sync
  Future<Result<Map<String, dynamic>>> getStreakData() async {
    try {
      // Try to get fresh data from API
      final apiResult = await _api.getStreak();
      if (apiResult.isSuccess) {
        _isOnline = true;
        // Cache streak data locally
        await _storage.saveStreakData(apiResult.data!);
        return Result.success(apiResult.data!);
      }
    } catch (e) {
      debugPrint('API call failed, using local data: $e');
    }

    // Fallback to local storage
    _isOnline = false;
    final localResult = await _storage.getStreakData();
    return localResult;
  }

  /// Get water intake with sync
  Future<Result<({int count, String date})?>> getWaterIntake() async {
    try {
      // Try to get fresh data from API
      final apiResult = await _api.getTodayTracking();
      if (apiResult.isSuccess) {
        _isOnline = true;
        final data = apiResult.data!;
        final waterData = (
          count: (data['water_intake'] as int? ?? 0) ~/ 250, // Convert ml to glasses
          date: DateTime.now().toIso8601String().substring(0, 10),
        );
        // Cache locally
        await _storage.saveWaterIntakeToday(waterData.count);
        return Result.success(waterData);
      }
    } catch (e) {
      debugPrint('API call failed, using local data: $e');
    }

    // Fallback to local storage
    _isOnline = false;
    final localResult = await _storage.getWaterIntake();
    return localResult;
  }

  /// Get mood with sync
  Future<Result<String?>> getMood() async {
    try {
      // Try to get fresh data from API
      final apiResult = await _api.getTodayTracking();
      if (apiResult.isSuccess) {
        _isOnline = true;
        final data = apiResult.data!;
        final mood = data['mood'] as String?;
        // Cache locally
        if (mood != null) {
          await _storage.saveMood(mood);
        }
        return Result.success(mood);
      }
    } catch (e) {
      debugPrint('API call failed, using local data: $e');
    }

    // Fallback to local storage
    _isOnline = false;
    final localResult = await _storage.getMood();
    return localResult;
  }

  /// Update water intake with sync
  Future<Result<int>> updateWaterIntake(int glasses) async {
    // Always save locally first
    await _storage.saveWaterIntakeToday(glasses);

    try {
      // Try to sync with API
      final apiResult = await _api.incrementWater(amount: glasses * 250); // 250ml per glass
      
      if (apiResult.isSuccess) {
        _isOnline = true;
        return Result.success(glasses);
      }
    } catch (e) {
      debugPrint('Failed to sync water intake: $e');
      // Queue for later sync
      await _queueOperation('update_water', {'glasses': glasses});
    }

    _isOnline = false;
    return Result.success(glasses);
  }

  /// Update mood with sync
  Future<Result<void>> updateMood(String mood) async {
    // Always save locally first
    await _storage.saveMood(mood);

    try {
      // Try to sync with API
      final apiResult = await _api.setMood(mood);
      
      if (apiResult.isSuccess) {
        _isOnline = true;
        return Result.success(null);
      }
    } catch (e) {
      debugPrint('Failed to sync mood: $e');
      // Queue for later sync
      await _queueOperation('update_mood', {'mood': mood});
    }

    _isOnline = false;
    return Result.success(null);
  }

  /// Get reminders with sync
  Future<Result<List<Reminder>>> getReminders() async {
    try {
      // Try to get fresh data from API
      final apiResult = await _api.getReminders();
      if (apiResult.isSuccess) {
        _isOnline = true;
        // Convert API data to local models and cache
        final reminders = apiResult.data!.map((item) => Reminder.fromJson(item)).toList();
        
        // Cache locally
        await _storage.saveReminders(reminders);
        
        return Result.success(reminders);
      }
    } catch (e) {
      debugPrint('API call failed, using local data: $e');
    }

    // Fallback to local storage
    _isOnline = false;
    return await _storage.getReminders();
  }

  /// Save reminder with sync
  Future<Result<Reminder>> saveReminder(Reminder reminder) async {
    // Always save locally first
    await _storage.saveReminder(reminder);

    try {
      // Try to sync with API
      final apiResult = reminder.id.isEmpty 
        ? await _api.createReminder(reminder)
        : await _api.updateReminder(reminder);
      
      if (apiResult.isSuccess) {
        _isOnline = true;
        final updatedReminder = Reminder.fromJson(apiResult.data!);
        // Update local storage with server response
        await _storage.saveReminder(updatedReminder);
        return Result.success(updatedReminder);
      }
    } catch (e) {
      debugPrint('Failed to sync reminder: $e');
      // Queue for later sync
      await _queueOperation(
        reminder.id.isEmpty ? 'create_reminder' : 'update_reminder',
        reminder.toJson(),
      );
    }

    _isOnline = false;
    return Result.success(reminder);
  }

  /// Delete reminder with sync
  Future<Result<void>> deleteReminder(String reminderId) async {
    // Always delete locally first
    await _storage.deleteReminder(reminderId);

    try {
      // Try to sync with API
      final apiResult = await _api.deleteReminder(reminderId);
      
      if (apiResult.isSuccess) {
        _isOnline = true;
        return Result.success(null);
      }
    } catch (e) {
      debugPrint('Failed to sync reminder deletion: $e');
      // Queue for later sync
      await _queueOperation('delete_reminder', {'id': reminderId});
    }

    _isOnline = false;
    return Result.success(null);
  }

  /// Get user statistics with sync
  Future<Result<Map<String, dynamic>>> getUserStats() async {
    try {
      // Try to get fresh data from API
      final apiResult = await _api.getUserStats();
      if (apiResult.isSuccess) {
        _isOnline = true;
        // Cache stats locally
        await _storage.saveUserStats(apiResult.data!);
        return Result.success(apiResult.data!);
      }
    } catch (e) {
      debugPrint('API call failed, using local data: $e');
    }

    // Fallback to local storage or calculate from local data
    _isOnline = false;
    final localResult = await _storage.getUserStats();
    if (localResult.isSuccess) {
      return localResult;
    }

    // Calculate basic stats from local data if no cached stats
    final challengeHistoryResult = await _storage.getChallengeHistory();
    final streakResult = await _storage.getStreakData();
    
    final stats = {
      'total_challenges': challengeHistoryResult.dataOrNull?.length ?? 0,
      'total_streak': streakResult.dataOrNull?['current_streak'] ?? 0,
      'longest_streak': streakResult.dataOrNull?['longest_streak'] ?? 0,
      'achievements_unlocked': 0,
      'total_achievements': 8,
      'current_water_intake': 0,
      'join_date': DateTime.now().toIso8601String(),
    };

    return Result.success(stats);
  }

  /// Get achievements with sync
  Future<Result<Map<String, dynamic>>> getAchievements() async {
    try {
      // Try to get fresh data from API
      final apiResult = await _api.getAchievements();
      if (apiResult.isSuccess) {
        _isOnline = true;
        // Cache achievements locally
        await _storage.saveAchievements(apiResult.data!);
        return Result.success(apiResult.data!);
      }
    } catch (e) {
      debugPrint('API call failed, using local data: $e');
    }

    // Fallback to local storage or default achievements
    _isOnline = false;
    final localResult = await _storage.getAchievements();
    if (localResult.isSuccess) {
      return localResult;
    }

    // Return default achievements if no cached data
    final defaultAchievements = {
      'achievements': [
        {
          'id': 'streak_3',
          'title': 'Getting Started',
          'description': 'Maintain a 3-day streak',
          'emoji': '🌱',
          'category': 'streak',
          'requirement': 3,
          'is_unlocked': false,
          'unlocked_at': null,
        },
        // Add other default achievements...
      ],
      'unlocked_count': 0,
      'total_count': 8,
    };

    return Result.success(defaultAchievements);
  }

  /// Sync all pending operations when connection is restored
  Future<void> syncPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    debugPrint('Syncing ${_pendingOperations.length} pending operations...');

    final operationsToSync = List<Map<String, dynamic>>.from(_pendingOperations);
    _pendingOperations.clear();

    for (final operation in operationsToSync) {
      try {
        await _syncOperation(operation);
      } catch (e) {
        debugPrint('Failed to sync operation ${operation['type']}: $e');
        // Re-queue failed operations
        _pendingOperations.add(operation);
      }
    }

    // Save updated pending operations
    await _storage.savePendingOperations(_pendingOperations);
  }

  /// Initialize sync service and load pending operations
  Future<void> initialize() async {
    // Load pending operations from storage
    final pendingResult = await _storage.getPendingOperations();
    if (pendingResult.isSuccess) {
      _pendingOperations.addAll(pendingResult.data!);
    }

    // Try to sync pending operations
    if (_pendingOperations.isNotEmpty) {
      syncPendingOperations();
    }
  }

  /// Queue an operation for later sync
  Future<void> _queueOperation(String type, Map<String, dynamic> data) async {
    final operation = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _pendingOperations.add(operation);
    await _storage.savePendingOperations(_pendingOperations);
  }

  /// Sync a specific operation
  Future<void> _syncOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final data = operation['data'] as Map<String, dynamic>;

    switch (type) {
      case 'update_user':
        await _api.updateProfile(
          name: data['name'],
          avatar: data['avatar'],
        );
        break;
      case 'complete_challenge':
        // Reconstruct challenge object
        final challenge = GeneratedChallenge(
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          duration: data['duration'] ?? '',
          emoji: data['emoji'] ?? '✨',
          funFact: data['fun_fact'] ?? '',
          goalCategory: data['goal_category'],
          energyLevel: data['energy_level'],
        );
        await _api.completeChallenge(challenge);
        break;
      case 'update_water':
        await _api.incrementWater(amount: (data['glasses'] as int) * 250);
        break;
      case 'update_mood':
        await _api.setMood(data['mood']);
        break;
      case 'create_reminder':
        final reminder = Reminder.fromJson(data);
        await _api.createReminder(reminder);
        break;
      case 'update_reminder':
        final reminder = Reminder.fromJson(data);
        await _api.updateReminder(reminder);
        break;
      case 'delete_reminder':
        await _api.deleteReminder(data['id']);
        break;
    }
  }

  /// Check for achievements asynchronously
  void _checkAchievementsAsync() {
    Future.microtask(() async {
      try {
        await _api.checkAchievements();
      } catch (e) {
        debugPrint('Failed to check achievements: $e');
      }
    });
  }

  /// Force sync all data from API
  Future<Result<void>> forceSyncFromAPI() async {
    try {
      // Sync user data
      await getUser();
      
      // Sync challenge history
      await getChallengeHistory();
      
      // Sync streak data
      await getStreakData();
      
      // Sync reminders
      await getReminders();
      
      // Sync achievements
      await getAchievements();
      
      // Sync user stats
      await getUserStats();
      
      // Sync pending operations
      await syncPendingOperations();
      
      return Result.success(null);
    } catch (e) {
      return Result.failure('Sync failed: $e');
    }
  }

  /// Get connection status message for UI
  String get connectionStatus {
    return _isOnline ? 'Connected' : 'Offline Mode';
  }

  /// Get pending operations count for UI
  int get pendingOperationsCount => _pendingOperations.length;
}