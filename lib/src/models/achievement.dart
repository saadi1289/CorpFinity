import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AchievementType {
  streak,
  challenges,
  hydration,
  earlyBird,
  nightOwl,
  consistency,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementType type;
  final int requirement;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.requirement,
    required this.color,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      type: type,
      requirement: requirement,
      color: color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  static List<Achievement> get allAchievements => [
    // Streak achievements
    const Achievement(
      id: 'streak_3',
      title: 'Getting Started',
      description: 'Maintain a 3-day streak',
      emoji: '🌱',
      type: AchievementType.streak,
      requirement: 3,
      color: AppColors.secondary,
    ),
    const Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      emoji: '🔥',
      type: AchievementType.streak,
      requirement: 7,
      color: AppColors.warning,
    ),
    const Achievement(
      id: 'streak_30',
      title: 'Monthly Master',
      description: 'Maintain a 30-day streak',
      emoji: '⭐',
      type: AchievementType.streak,
      requirement: 30,
      color: AppColors.accent,
    ),
    const Achievement(
      id: 'streak_100',
      title: 'Century Club',
      description: 'Maintain a 100-day streak',
      emoji: '👑',
      type: AchievementType.streak,
      requirement: 100,
      color: AppColors.primary,
    ),
    // Challenge achievements
    const Achievement(
      id: 'challenges_5',
      title: 'First Steps',
      description: 'Complete 5 challenges',
      emoji: '🎯',
      type: AchievementType.challenges,
      requirement: 5,
      color: AppColors.info,
    ),
    const Achievement(
      id: 'challenges_25',
      title: 'Dedicated',
      description: 'Complete 25 challenges',
      emoji: '💪',
      type: AchievementType.challenges,
      requirement: 25,
      color: AppColors.secondary,
    ),
    const Achievement(
      id: 'challenges_50',
      title: 'Wellness Pro',
      description: 'Complete 50 challenges',
      emoji: '🏆',
      type: AchievementType.challenges,
      requirement: 50,
      color: AppColors.warning,
    ),
    const Achievement(
      id: 'challenges_100',
      title: 'Legend',
      description: 'Complete 100 challenges',
      emoji: '🌟',
      type: AchievementType.challenges,
      requirement: 100,
      color: AppColors.primary,
    ),
  ];
}
