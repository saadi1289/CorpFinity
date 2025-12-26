import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../../constants.dart';
import '../tutorial_overlay.dart';

/// Mood tracking widget with emoji selection
class MoodTracker extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String> onMoodSelected;

  const MoodTracker({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  IconData _getMoodIcon(String iconName) {
    const iconMap = {
      'Sun': LucideIcons.sun,
      'Smile': LucideIcons.smile,
      'Meh': LucideIcons.meh,
      'Cloud': LucideIcons.cloud,
      'Frown': LucideIcons.frown,
    };
    return iconMap[iconName] ?? LucideIcons.circle;
  }

  @override
  Widget build(BuildContext context) {
    final activeMood = AppConstants.moods.firstWhere(
      (m) => m.label == selectedMood,
      orElse: () => AppConstants.moods[0],
    );

    return Semantics(
      label: 'Mood tracker. Select how you are feeling today.',
      child: Container(
        key: TutorialTargets.moodTracker,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: AppConstants.moods.map((mood) {
                final isSelected = selectedMood == mood.label;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${mood.label} mood',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onMoodSelected(mood.label);
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected ? mood.color : mood.bg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: mood.color
                                  .withValues(alpha: isSelected ? 1.0 : 0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getMoodIcon(mood.icon),
                            color: isSelected ? Colors.white : mood.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AppTextStyles.tiny.copyWith(
                            color: mood.color,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          child: Text(mood.label),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedMood != null) ...[
              const SizedBox(height: 24),
              _MoodTip(mood: activeMood),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoodTip extends StatelessWidget {
  final ({
    String label,
    String icon,
    Color color,
    Color bg,
    Color border,
  }) mood;

  const _MoodTip({required this.mood});

  @override
  Widget build(BuildContext context) {
    final tip = AppConstants.moodTips[mood.label];
    if (tip == null) return const SizedBox.shrink();

    return Semantics(
      label: 'Mood tip: ${tip.title}. ${tip.desc}',
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mood.bg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: mood.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.lightbulb, size: 16, color: mood.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.gray900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip.desc,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
