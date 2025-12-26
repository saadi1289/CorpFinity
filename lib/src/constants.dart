import 'package:flutter/material.dart';
import 'models/goal_option.dart';
import 'models/energy_level.dart';
import 'theme/app_colors.dart';

/// App constants with warm wellness aesthetic
class AppConstants {
  static const List<GoalOption> goalOptions = [
    GoalOption(
      id: 'stress_reduction',
      label: 'Stress Relief',
      icon: 'Brain',
      color: AppColors.blue500,
      description: 'Calm your mind, find your center.',
    ),
    GoalOption(
      id: 'increased_energy',
      label: 'Energy Boost',
      icon: 'Zap',
      color: AppColors.yellow500,
      description: 'Recharge and feel alive.',
    ),
    GoalOption(
      id: 'better_sleep',
      label: 'Better Sleep',
      icon: 'Moon',
      color: AppColors.indigo500,
      description: 'Wind down peacefully.',
    ),
    GoalOption(
      id: 'physical_fitness',
      label: 'Movement',
      icon: 'Activity',
      color: AppColors.red500,
      description: 'Get your body moving.',
    ),
    GoalOption(
      id: 'healthy_eating',
      label: 'Nourishment',
      icon: 'Utensils',
      color: AppColors.green500,
      description: 'Fuel your wellness.',
    ),
    GoalOption(
      id: 'social_connection',
      label: 'Connection',
      icon: 'Heart',
      color: AppColors.pink500,
      description: 'Nurture relationships.',
    ),
  ];
  
  static const List<({
    EnergyLevel value,
    String icon,
    Color color,
    Color bg,
  })> energyOptions = [
    (
      value: EnergyLevel.low,
      icon: 'Leaf',
      color: Color(0xFFCB6B5E), // Dusty coral
      bg: Color(0xFFFDF6F5), // Soft coral bg
    ),
    (
      value: EnergyLevel.medium,
      icon: 'Flame',
      color: Color(0xFFD4A84B), // Amber gold
      bg: Color(0xFFFDF9F0), // Warm cream
    ),
    (
      value: EnergyLevel.high,
      icon: 'Zap',
      color: AppColors.secondary, // Sage green
      bg: Color(0xFFF4F8F3), // Soft sage bg
    ),
  ];
  
  // Daily quotes - curated for wellness
  static const List<({String text, String author})> quotes = [
    (
      text: 'Almost everything will work again if you unplug it for a few minutes, including you.',
      author: 'Anne Lamott',
    ),
    (
      text: 'Tension is who you think you should be. Relaxation is who you are.',
      author: 'Chinese Proverb',
    ),
    (
      text: 'Your calm mind is the ultimate weapon against your challenges.',
      author: 'Bryant McGill',
    ),
    (
      text: 'Rest is not idleness, and to lie sometimes on the grass under trees is not a waste of time.',
      author: 'John Lubbock',
    ),
    (
      text: 'The greatest weapon against stress is our ability to choose one thought over another.',
      author: 'William James',
    ),
    (
      text: 'In the midst of movement and chaos, keep stillness inside of you.',
      author: 'Deepak Chopra',
    ),
  ];
  
  // Mood definitions - warm, earthy tones
  static const List<({
    String label,
    String icon,
    Color color,
    Color bg,
    Color border,
  })> moods = [
    (
      label: 'Great',
      icon: 'Sun',
      color: AppColors.moodGreat,
      bg: Color(0xFFFDF9F0), // Warm cream
      border: Color(0xFFF2D4A0), // Soft gold
    ),
    (
      label: 'Good',
      icon: 'Smile',
      color: AppColors.moodGood,
      bg: Color(0xFFF0F4F8), // Soft blue
      border: Color(0xFFD4E0EC), // Light slate
    ),
    (
      label: 'Okay',
      icon: 'Meh',
      color: AppColors.moodOkay,
      bg: Color(0xFFF5F3EF), // Warm gray
      border: Color(0xFFE8E4DD), // Stone
    ),
    (
      label: 'Tired',
      icon: 'Cloud',
      color: AppColors.moodTired,
      bg: Color(0xFFF3F2F8), // Soft lavender
      border: Color(0xFFE0DEE8), // Light purple
    ),
    (
      label: 'Stressed',
      icon: 'Frown',
      color: AppColors.moodStressed,
      bg: Color(0xFFFDF6F5), // Soft coral
      border: Color(0xFFF0DCD9), // Dusty rose
    ),
  ];
  
  // Mood tips (emojis removed - icons handled by UI)
  static const Map<String, ({String title, String desc, String iconKey})> moodTips = {
    'Great': (
      title: 'Radiate Joy',
      desc: 'Your energy is magnetic today. Share a kind word with someone.',
      iconKey: 'sparkles',
    ),
    'Good': (
      title: 'Ride the Wave',
      desc: 'You\'re in a great flow. Perfect time to tackle something meaningful.',
      iconKey: 'wave',
    ),
    'Okay': (
      title: 'Small Steps',
      desc: 'One small win can shift everything. What\'s one thing you can complete?',
      iconKey: 'seedling',
    ),
    'Tired': (
      title: 'Gentle Recharge',
      desc: 'Step outside for fresh air. A glass of water and deep breaths help.',
      iconKey: 'leaf',
    ),
    'Stressed': (
      title: 'Ground Yourself',
      desc: 'Notice 5 things you see, 4 you feel, 3 you hear. Breathe slowly.',
      iconKey: 'heart',
    ),
  };
}
