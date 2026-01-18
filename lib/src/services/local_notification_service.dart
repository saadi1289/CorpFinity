import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/reminder.dart';
import 'storage_service.dart';
import 'result.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final StorageService _storage = StorageService();
  bool _initialized = false;

  /// Initialize the notification service
  Future<Result<bool>> initialize() async {
    try {
      if (_initialized) return Result.success(true);

      // Initialize timezone data
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        _initialized = true;
        return Result.success(true);
      } else {
        return Result.failure('Failed to initialize notifications');
      }
    } catch (e) {
      return Result.failure('Notification initialization error: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screens
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  Future<Result<bool>> requestPermissions() async {
    try {
      // Android 13+ requires explicit permission request
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return Result.success(granted ?? false);
      }

      // iOS permissions are requested during initialization
      return Result.success(true);
    } catch (e) {
      return Result.failure('Permission request error: $e');
    }
  }

  /// Show an immediate notification
  Future<Result<void>> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'corpfinity_channel',
        'CorpFinity Notifications',
        channelDescription: 'Wellness reminders and achievements',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Show notification error: $e');
    }
  }

  /// Schedule a notification for a specific time
  Future<Result<void>> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'corpfinity_reminders',
        'CorpFinity Reminders',
        channelDescription: 'Scheduled wellness reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      return Result.success(null);
    } catch (e) {
      return Result.failure('Schedule notification error: $e');
    }
  }

  /// Schedule daily recurring notification
  Future<Result<void>> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'corpfinity_daily',
        'CorpFinity Daily Reminders',
        channelDescription: 'Daily wellness reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      return Result.success(null);
    } catch (e) {
      return Result.failure('Schedule daily notification error: $e');
    }
  }

  /// Get next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Schedule reminder notifications
  Future<Result<void>> scheduleReminder(Reminder reminder) async {
    try {
      final title = reminder.title;
      final body = reminder.message ?? _getDefaultMessage(reminder.type);
      
      if (reminder.frequency == ReminderFrequency.daily) {
        return await scheduleDailyNotification(
          id: reminder.id.hashCode,
          title: title,
          body: body,
          hour: reminder.time.hour,
          minute: reminder.time.minute,
          payload: 'reminder:${reminder.id}',
        );
      } else if (reminder.frequency == ReminderFrequency.weekdays) {
        // Schedule for Monday-Friday
        for (int weekday = 1; weekday <= 5; weekday++) {
          final nextWeekday = _nextInstanceOfWeekday(weekday, reminder.time.hour, reminder.time.minute);
          await scheduleNotification(
            id: '${reminder.id}_$weekday'.hashCode,
            title: title,
            body: body,
            scheduledTime: nextWeekday.toLocal(),
            payload: 'reminder:${reminder.id}',
          );
        }
        return Result.success(null);
      } else if (reminder.frequency == ReminderFrequency.custom && reminder.customDays.isNotEmpty) {
        // Schedule for custom days
        for (int day in reminder.customDays) {
          final nextCustomDay = _nextInstanceOfWeekday(day == 0 ? 7 : day, reminder.time.hour, reminder.time.minute);
          await scheduleNotification(
            id: '${reminder.id}_$day'.hashCode,
            title: title,
            body: body,
            scheduledTime: nextCustomDay.toLocal(),
            payload: 'reminder:${reminder.id}',
          );
        }
        return Result.success(null);
      }

      return Result.failure('Invalid reminder frequency');
    } catch (e) {
      return Result.failure('Schedule reminder error: $e');
    }
  }

  /// Get next instance of a specific weekday
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Get default message for reminder type
  String _getDefaultMessage(ReminderType type) {
    switch (type) {
      case ReminderType.hydration:
        return 'Time to drink some water! 💧';
      case ReminderType.stretchBreak:
        return 'Take a moment to stretch and move! 🧘‍♀️';
      case ReminderType.meditation:
        return 'Time for a mindful moment 🧘‍♂️';
      case ReminderType.custom:
        return 'Wellness reminder from CorpFinity! 🌟';
    }
  }

  /// Cancel a specific notification
  Future<Result<void>> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure('Cancel notification error: $e');
    }
  }

  /// Cancel all notifications
  Future<Result<void>> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      return Result.success(null);
    } catch (e) {
      return Result.failure('Cancel all notifications error: $e');
    }
  }

  /// Cancel reminder notifications
  Future<Result<void>> cancelReminder(Reminder reminder) async {
    try {
      // Cancel main notification
      await cancelNotification(reminder.id.hashCode);
      
      // Cancel frequency-specific notifications
      if (reminder.frequency == ReminderFrequency.weekdays) {
        for (int weekday = 1; weekday <= 5; weekday++) {
          await cancelNotification('${reminder.id}_$weekday'.hashCode);
        }
      } else if (reminder.frequency == ReminderFrequency.custom && reminder.customDays.isNotEmpty) {
        for (int day in reminder.customDays) {
          await cancelNotification('${reminder.id}_$day'.hashCode);
        }
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure('Cancel reminder error: $e');
    }
  }

  /// Show achievement notification
  Future<Result<void>> showAchievementNotification({
    required String title,
    required String emoji,
  }) async {
    return await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '$emoji Achievement Unlocked!',
      body: 'Congratulations! You\'ve earned "$title"',
      payload: 'achievement:$title',
    );
  }

  /// Show streak notification
  Future<Result<void>> showStreakNotification(int streakCount) async {
    return await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '🔥 $streakCount-Day Streak!',
      body: 'Amazing! You\'re on a $streakCount-day wellness streak. Keep it up!',
      payload: 'streak:$streakCount',
    );
  }

  /// Show challenge completion notification
  Future<Result<void>> showChallengeCompletionNotification(String challengeTitle) async {
    return await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '✅ Challenge Complete!',
      body: 'Great job completing "$challengeTitle"!',
      payload: 'challenge:$challengeTitle',
    );
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Reschedule all reminders (call when reminders are updated)
  Future<Result<void>> rescheduleAllReminders() async {
    try {
      // Get all reminders from storage
      final remindersResult = await _storage.getReminders();
      if (remindersResult.isFailure) {
        return Result.failure('Failed to get reminders: ${remindersResult.errorMessage}');
      }

      final reminders = remindersResult.data!;
      
      // Cancel all existing notifications
      await cancelAllNotifications();
      
      // Schedule enabled reminders
      for (final reminder in reminders) {
        if (reminder.isEnabled) {
          await scheduleReminder(reminder);
        }
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure('Reschedule reminders error: $e');
    }
  }
}