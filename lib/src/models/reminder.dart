import 'package:flutter/material.dart';

enum ReminderType {
  hydration,
  stretchBreak,
  meditation,
  custom;

  String get displayName {
    switch (this) {
      case ReminderType.hydration:
        return 'Hydration';
      case ReminderType.stretchBreak:
        return 'Stretch Break';
      case ReminderType.meditation:
        return 'Meditation';
      case ReminderType.custom:
        return 'Take a Break';
    }
  }

  String get emoji {
    switch (this) {
      case ReminderType.hydration:
        return '💧';
      case ReminderType.stretchBreak:
        return '🧘';
      case ReminderType.meditation:
        return '🧠';
      case ReminderType.custom:
        return '✨';
    }
  }

  String get defaultMessage {
    switch (this) {
      case ReminderType.hydration:
        return 'Time to drink some water!';
      case ReminderType.stretchBreak:
        return 'Take a quick stretch break!';
      case ReminderType.meditation:
        return 'A moment of calm awaits you.';
      case ReminderType.custom:
        return 'Time for a wellness break!';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderType.hydration:
        return Icons.water_drop_outlined;
      case ReminderType.stretchBreak:
        return Icons.self_improvement;
      case ReminderType.meditation:
        return Icons.spa_outlined;
      case ReminderType.custom:
        return Icons.auto_awesome;
    }
  }
}

enum ReminderFrequency {
  daily,
  weekdays,
  custom;

  String get displayName {
    switch (this) {
      case ReminderFrequency.daily:
        return 'Every Day';
      case ReminderFrequency.weekdays:
        return 'Weekdays';
      case ReminderFrequency.custom:
        return 'Custom Days';
    }
  }
}

class Reminder {
  final String id;
  final ReminderType type;
  final String title;
  final String message;
  final TimeOfDay time;
  final ReminderFrequency frequency;
  final List<int> customDays; // 1=Mon, 7=Sun
  final bool isEnabled;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.frequency,
    this.customDays = const [],
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Reminder copyWith({
    String? id,
    ReminderType? type,
    String? title,
    String? message,
    TimeOfDay? time,
    ReminderFrequency? frequency,
    List<int>? customDays,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name, // Use string name instead of index
      'title': title,
      'message': message,
      'time_hour': time.hour, // Match backend field names
      'time_minute': time.minute,
      'frequency': frequency.name, // Use string name instead of index
      'custom_days': customDays,
      'is_enabled': isEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReminderType.custom,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      time: TimeOfDay(
        hour: json['time_hour'] as int,
        minute: json['time_minute'] as int,
      ),
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => ReminderFrequency.daily,
      ),
      customDays: List<int>.from(json['custom_days'] ?? []),
      isEnabled: json['is_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get formattedTime {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String get frequencyDescription {
    switch (frequency) {
      case ReminderFrequency.daily:
        return 'Every day';
      case ReminderFrequency.weekdays:
        return 'Mon - Fri';
      case ReminderFrequency.custom:
        if (customDays.isEmpty) return 'No days selected';
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final selected = customDays.map((d) => dayNames[d - 1]).join(', ');
        return selected;
    }
  }
}
