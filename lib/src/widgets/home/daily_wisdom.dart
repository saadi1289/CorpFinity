import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_text_styles.dart';

/// Daily wisdom quote card
class DailyWisdom extends StatelessWidget {
  final String quote;
  final String author;

  const DailyWisdom({
    super.key,
    required this.quote,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Daily wisdom quote: "$quote" by $author',
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.dark, AppColors.darkMuted],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Column(
          children: [
            Text(
              'DAILY WISDOM',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.accent,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"$quote"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '— $author',
              style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}
