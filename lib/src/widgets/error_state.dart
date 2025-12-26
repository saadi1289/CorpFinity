import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We couldn\'t load the data. Please try again.',
    this.onRetry,
    this.icon = LucideIcons.circleAlert,
  });

  factory ErrorState.network({VoidCallback? onRetry}) {
    return ErrorState(
      title: 'No Connection',
      message: 'Please check your internet connection and try again.',
      icon: LucideIcons.wifiOff,
      onRetry: onRetry,
    );
  }

  factory ErrorState.empty({
    required String title,
    required String message,
    IconData icon = LucideIcons.inbox,
  }) {
    return ErrorState(
      title: title,
      message: message,
      icon: icon,
      onRetry: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $message${onRetry != null ? ". Tap try again to retry." : ""}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(color: AppColors.gray800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.gray500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                Semantics(
                  button: true,
                  label: 'Try again',
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
