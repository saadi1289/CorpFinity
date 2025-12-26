import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';
import '../tutorial_overlay.dart';

/// Hydration tracking widget
class HydrationTracker extends StatelessWidget {
  final int waterIntake;
  final int goal;
  final VoidCallback onAddWater;

  const HydrationTracker({
    super.key,
    required this.waterIntake,
    this.goal = 8,
    required this.onAddWater,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = waterIntake >= goal;
    final progress = (waterIntake / goal).clamp(0.0, 1.0);

    return Semantics(
      label:
          'Hydration tracker. $waterIntake of $goal glasses today. ${isComplete ? "Goal complete!" : "Tap plus to add water."}',
      child: Container(
        key: TutorialTargets.hydration,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.droplets,
                          size: 18, color: AppColors.info),
                      const SizedBox(width: 8),
                      Text(
                        'Hydration',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isComplete) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '✓ Complete',
                            style: AppTextStyles.tiny.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$waterIntake / $goal glasses today',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.info.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: AppColors.info.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.info),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Semantics(
              button: true,
              enabled: !isComplete,
              label: isComplete ? 'Goal complete' : 'Add water',
              child: GestureDetector(
                onTap: isComplete
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onAddWater();
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    isComplete ? LucideIcons.check : LucideIcons.plus,
                    size: 24,
                    color: isComplete ? AppColors.success : AppColors.info,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
