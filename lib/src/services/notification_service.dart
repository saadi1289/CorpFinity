import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isEnabled) return;

    // Cancel existing notifications for this reminder
    await cancelReminder(reminder.id);

    final notificationId = reminder.id.hashCode;

    switch (reminder.frequency) {
      case ReminderFrequency.daily:
        await _scheduleDailyNotification(reminder, notificationId);
        break;
      case ReminderFrequency.weekdays:
        // Schedule for Mon-Fri (1-5)
        for (int day = 1; day <= 5; day++) {
          await _scheduleWeeklyNotification(
            reminder,
            notificationId + day,
            day,
          );
        }
        break;
      case ReminderFrequency.custom:
        for (int i = 0; i < reminder.customDays.length; i++) {
          await _scheduleWeeklyNotification(
            reminder,
            notificationId + reminder.customDays[i],
            reminder.customDays[i],
          );
        }
        break;
    }
  }

  Future<void> _scheduleDailyNotification(
    Reminder reminder,
    int notificationId,
  ) async {
    final scheduledTime = _nextInstanceOfTime(reminder.time);

    await _notifications.zonedSchedule(
      notificationId,
      reminder.title,
      reminder.message,
      scheduledTime,
      _notificationDetails(reminder),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: reminder.id,
    );
  }

  Future<void> _scheduleWeeklyNotification(
    Reminder reminder,
    int notificationId,
    int dayOfWeek,
  ) async {
    final scheduledTime = _nextInstanceOfWeekday(reminder.time, dayOfWeek);

    await _notifications.zonedSchedule(
      notificationId,
      reminder.title,
      reminder.message,
      scheduledTime,
      _notificationDetails(reminder),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: reminder.id,
    );
  }

  NotificationDetails _notificationDetails(Reminder reminder) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'wellness_reminders',
        'Wellness Reminders',
        channelDescription: 'Reminders for wellness activities',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(TimeOfDay time, int dayOfWeek) {
    var scheduled = _nextInstanceOfTime(time);

    while (scheduled.weekday != dayOfWeek) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  Future<void> cancelReminder(String reminderId) async {
    final notificationId = reminderId.hashCode;
    
    // Cancel main notification
    await _notifications.cancel(notificationId);
    
    // Cancel all possible weekly notifications (days 1-7)
    for (int day = 1; day <= 7; day++) {
      await _notifications.cancel(notificationId + day);
    }
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  // Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    await _notifications.show(
      0,
      'CorpFinity',
      'Notifications are working! 🎉',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Show achievement notification
  Future<void> showAchievementNotification({
    required String title,
    required String emoji,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '$emoji Achievement Unlocked!',
      'Congratulations! You\'ve earned "$title"',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Achievements',
          channelDescription: 'Achievement unlock notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'achievement:$title',
    );
  }

  /// Show streak notification
  Future<void> showStreakNotification(int streakCount) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🔥 $streakCount-Day Streak!',
      'Amazing! You\'re on a $streakCount-day wellness streak. Keep it up!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streaks',
          'Streaks',
          channelDescription: 'Streak milestone notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'streak:$streakCount',
    );
  }

  /// Show challenge completion notification
  Future<void> showChallengeCompletionNotification(String challengeTitle) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✅ Challenge Complete!',
      'Great job completing "$challengeTitle"!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'challenges',
          'Challenges',
          channelDescription: 'Challenge completion notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'challenge:$challengeTitle',
    );
  }

  /// Show general notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Show wellness tip notification
  Future<void> showWellnessTip(String tip) async {
    await showNotification(
      title: '💡 Wellness Tip',
      body: tip,
      payload: 'wellness_tip',
    );
  }

  /// Show hydration reminder
  Future<void> showHydrationReminder() async {
    await showNotification(
      title: '💧 Hydration Reminder',
      body: 'Time to drink some water! Stay hydrated for better wellness.',
      payload: 'hydration',
    );
  }

  /// Show stretch reminder
  Future<void> showStretchReminder() async {
    await showNotification(
      title: '🧘‍♀️ Stretch Break',
      body: 'Take a moment to stretch and move your body!',
      payload: 'stretch',
    );
  }

  /// Show breathing reminder
  Future<void> showBreathingReminder() async {
    await showNotification(
      title: '🌬️ Breathing Exercise',
      body: 'Take a few deep breaths to center yourself.',
      payload: 'breathing',
    );
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }
}
