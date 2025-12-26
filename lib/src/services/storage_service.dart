import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/challenge.dart';
import '../models/reminder.dart';
import 'result.dart';

/// Storage service with error handling for all operations
class StorageService {
  static const String _userKey = 'zenflow_user';
  static const String _stateKey = 'zenflow_state';
  static const String _historyKey = 'zenflow_history';
  static const String _waterKey = 'zenflow_water';
  static const String _waterDateKey = 'zenflow_water_date';
  static const String _remindersKey = 'zenflow_reminders';

  /// Gets SharedPreferences instance with error handling
  Future<SharedPreferences> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('StorageService: Failed to get SharedPreferences: $e');
      rethrow;
    }
  }

  // User operations
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

  /// Legacy method for backward compatibility
  Future<User?> getUserLegacy() async {
    final result = await getUser();
    return result.dataOrNull;
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

  // State operations (for home page flow state)
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

  /// Legacy method for backward compatibility
  Future<Map<String, dynamic>?> getStateLegacy() async {
    final result = await getState();
    return result.dataOrNull;
  }

  // Challenge history operations
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
          .map((json) =>
              ChallengeHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList();
      return Result.success(history);
    } catch (e) {
      debugPrint('StorageService: Failed to get history: $e');
      return Result.failure('Failed to load challenge history', e);
    }
  }

  /// Legacy method for backward compatibility
  Future<List<ChallengeHistoryItem>> getHistoryLegacy() async {
    final result = await getHistory();
    return result.dataOrNull ?? [];
  }

  // Water intake operations
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

  /// Legacy method for backward compatibility
  Future<({int count, String date})> getWaterIntakeLegacy() async {
    final result = await getWaterIntake();
    return result.dataOrNull ?? (count: 0, date: '');
  }

  // Reminder operations
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

  /// Legacy method for backward compatibility
  Future<List<Reminder>> getRemindersLegacy() async {
    final result = await getReminders();
    return result.dataOrNull ?? [];
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

  // Clear all data (for account deletion)
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
      ]);
      return Result.success(null);
    } catch (e) {
      debugPrint('StorageService: Failed to clear all data: $e');
      return Result.failure('Failed to clear app data', e);
    }
  }
}
