import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/challenge.dart';
import '../models/reminder.dart';
import 'result.dart';

/// Storage service with error handling for all operations
/// Integrates with backend API for cloud sync
class StorageService {
  static const String _userKey = 'zenflow_user';
  static const String _stateKey = 'zenflow_state';
  static const String _historyKey = 'zenflow_history';
  static const String _waterKey = 'zenflow_water';
  static const String _waterDateKey = 'zenflow_water_date';
  static const String _remindersKey = 'zenflow_reminders';
  static const String _lastSyncKey = 'zenflow_last_sync';
  static const String _offlineQueueKey = 'zenflow_offline_queue';

  /// Gets SharedPreferences instance with error handling
  Future<SharedPreferences> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('StorageService: Failed to get SharedPreferences: $e');
      rethrow;
    }
  }

  // ==================== User Operations ====================

  Future<Result<void>> saveUser(User user) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_userKey, user.toJsonString());
      return Result.success(null);
    } catch (e) {
      debugPrint('StorageService: Failed to save user: $e');
      return Result.failure('Failed to save user data', e);
    }
  }

  Future<Result<User?>> getUser() async {
    try {
      final prefs = await _getPrefs();
      final userString = prefs.getString(_userKey);
      if (userString == null) return Result.success(null);
      return Result.success(User.fromJsonString(userString));
    } catch (e) {
      debugPrint('StorageService: Failed to get user: $e');
      return Result.failure('Failed to load user data', e);
    }
  }

  Future<Result<void>> removeUser() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_userKey);
      return Result.success(null);
    } catch (e) {
      debugPrint('StorageService: Failed to remove user: $e');
      return Result.failure('Failed to remove user data', e);
    }
  }

  // ==================== State Operations ====================

  Future<Result<void>> saveState(Map<String, dynamic> state) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_stateKey, jsonEncode(state));
      return Result.success(null);
    } catch (e) {
      debugPrint('StorageService: Failed to save state: $e');
      return Result.failure('Failed to save app state', e);
    }
  }

  Future<Result<Map<String, dynamic>?>> getState() async {
    try {
      final prefs = await _getPrefs();
      final stateString = prefs.getString(_stateKey);
      if (stateString == null) return Result.success(null);
      return Result.success(jsonDecode(stateString) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('StorageService: Failed to get state: $e');
      return Result.failure('Failed to load app state', e);
    }
  }

  // ==================== Challenge History Operations ====================

  Future<Result<void>> saveHistory(List<ChallengeHistoryItem> history) async {
    try {
      final prefs = await _getPrefs();
      final historyJson = history.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyJson));
      return Result.success(null);
    } catch (e) {
      debugPrint('StorageService: Failed to save history: $e');
      return Result.failure('Failed to save challenge history', e);
    }
  }

  Future<Result<List<ChallengeHistoryItem>>> getHistory() async {
    try {
      final prefs = await _getPrefs();
      final historyString = prefs.getString(_historyKey);
      if (historyString == null) return Result.success([]);

      final List<dynamic> historyJson = jsonDecode(historyString) as List;
      final history = historyJson
          .map((json) => ChallengeHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList();
      return Result.success(history);
    } catch (e) {
      debugPrint('StorageService: Failed to get history: $e');
      return Result.failure('Failed to load challenge history', e);
    }
  }

  // ==================== Water Intake Operations ====================

  Future<Result<void>> saveWaterIntake(int count, String date) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setInt(_waterKey, count);
      await prefs.setString(_waterDateKey, date);
      return Result.success(null);
    } catch (e) {
      debugPrint('StorageService: Failed to save water intake: $e');
      return Result.failure('Failed to save water intake', e);
    }
  }

  Future<Result<({int count, String date})>> getWaterIntake() async {
    try {
      final prefs = await _getPrefs();
      final count = prefs.getInt(_waterKey) ?? 0;
      final date = prefs.getString(_waterDateKey) ?? '';
      return Result.success((count: count, date: date));
    } catch (e) {
      debugPrint('StorageService: Failed to get water intake: $e');
      return Result.failure('Failed to load water intake', e);
    }
  }

  // ==================== Reminder Operations ====================

  Future<Result<void>> saveReminders(List<Reminder> reminders) async {
    try {
      final prefs = await _getPrefs();
      final remindersJson = reminders.map((r) => r.toJson()).toList();
      await prefs.setString(_remindersKey, jsonEncode(remindersJson));
      return Result.success(null);
    } catch (e) {
      debugPrint('StorageService: Failed to save reminders: $e');
      return Result.failure('Failed to save reminders', e);
    }
  }

  Future<Result<List<Reminder>>> getReminders() async {
    try {
      final prefs = await _getPrefs();
      final remindersString = prefs.getString(_remindersKey);
      if (remindersString == null) return Result.success([]);

      final List<dynamic> remindersJson = jsonDecode(remindersString) as List;
      final reminders = remindersJson
          .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
          .toList();
      return Result.success(reminders);
    } catch (e) {
      debugPrint('StorageService: Failed to get reminders: $e');
      return Result.failure('Failed to load reminders', e);
    }
  }

  Future<Result<void>> addReminder(Reminder reminder) async {
    try {
      final result = await getReminders();
      if (result.isFailure) return Result.failure(result.errorMessage!);

      final reminders = result.data;
      reminders.add(reminder);
      return saveReminders(reminders);
    } catch (e) {
      debugPrint('StorageService: Failed to add reminder: $e');
      return Result.failure('Failed to add reminder', e);
    }
  }

  Future<Result<void>> updateReminder(Reminder reminder) async {
    try {
      final result = await getReminders();
      if (result.isFailure) return Result.failure(result.errorMessage!);

      final reminders = result.data;
      final index = reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        reminders[index] = reminder;
        return saveReminders(reminders);
      }
      return Result.success(null);
    } catch (e) {
      debugPrint('StorageService: Failed to update reminder: $e');
      return Result.failure('Failed to update reminder', e);
    }
  }

  Future<Result<void>> deleteReminder(String reminderId) async {
    try {
      final result = await getReminders();
      if (result.isFailure) return Result.failure(result.errorMessage!);

      final reminders = result.data;
      reminders.removeWhere((r) => r.id == reminderId);
      return saveReminders(reminders);
    } catch (e) {
      debugPrint('StorageService: Failed to delete reminder: $e');
      return Result.failure('Failed to delete reminder', e);
    }
  }

  // ==================== Sync Operations ====================

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await _getPrefs();
      final timestamp = prefs.getInt(_lastSyncKey);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  /// Set last sync timestamp
  Future<void> setLastSyncTime() async {
    final prefs = await _getPrefs();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Add operation to offline queue
  Future<void> addToOfflineQueue(String operation, Map<String, dynamic> data) async {
    try {
      final prefs = await _getPrefs();
      final queueString = prefs.getString(_offlineQueueKey);
      final queue = queueString != null
          ? List<Map<String, dynamic>>.from(jsonDecode(queueString) as List)
          : <Map<String, dynamic>>[];
      
      queue.add({
        'operation': operation,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString(_offlineQueueKey, jsonEncode(queue));
    } catch (e) {
      debugPrint('StorageService: Failed to add to offline queue: $e');
    }
  }

  /// Get and clear offline queue
  Future<List<Map<String, dynamic>>> getAndClearOfflineQueue() async {
    try {
      final prefs = await _getPrefs();
      final queueString = prefs.getString(_offlineQueueKey);
      if (queueString == null) return [];
      
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueString) as List);
      await prefs.remove(_offlineQueueKey);
      return queue;
    } catch (e) {
      debugPrint('StorageService: Failed to get offline queue: $e');
      return [];
    }
  }

  // ==================== Clear All Data ====================

  Future<Result<void>> clearAllData() async {
    try {
      final prefs = await _getPrefs();
      await Future.wait([
        prefs.remove(_userKey),
        prefs.remove(_stateKey),
        prefs.remove(_historyKey),
        prefs.remove(_waterKey),
        prefs.remove(_waterDateKey),
        prefs.remove(_remindersKey),
        prefs.remove(_lastSyncKey),
        prefs.remove(_offlineQueueKey),
      ]);
      return Result.success(null);
    } catch (e) {
      debugPrint('StorageService: Failed to clear all data: $e');
      return Result.failure('Failed to clear app data', e);
    }
  }
}
