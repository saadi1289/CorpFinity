import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/achievement.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _storage = StorageService();
  List<Achievement> _achievements = [];
  int _streak = 0;
  int _totalChallenges = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final historyResult = await _storage.getHistory();
    final stateResult = await _storage.getState();

    final history = historyResult.dataOrNull ?? [];
    final state = stateResult.dataOrNull;
    
    final streak = state?['streak'] ?? 0;
    final totalChallenges = history.length;

    // Check which achievements are unlocked
    final achievements = Achievement.allAchievements.map((a) {
      bool unlocked = false;
      if (a.type == AchievementType.streak) {
        unlocked = streak >= a.requirement;
      } else if (a.type == AchievementType.challenges) {
        unlocked = totalChallenges >= a.requirement;
      }
      return a.copyWith(
        isUnlocked: unlocked,
        unlockedAt: unlocked ? DateTime.now() : null,
      );
    }).toList();

    setState(() {
      _achievements = achievements;
      _streak = streak;
      _totalChallenges = totalChallenges;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.gray700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Achievements',
          style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spacing6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$unlockedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$unlockedCount of ${_achievements.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Achievements Unlocked',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: unlockedCount / _achievements.length,
                                  minHeight: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.flame,
                          value: '$_streak',
                          label: 'Day Streak',
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.target,
                          value: '$_totalChallenges',
                          label: 'Challenges',
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Achievements list
                  Text(
                    'ALL BADGES',
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.gray400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...Achievement.allAchievements.map((baseAchievement) {
                    final achievement = _achievements.firstWhere(
                      (a) => a.id == baseAchievement.id,
                      orElse: () => baseAchievement,
                    );
                    return _buildAchievementCard(achievement);
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.tiny.copyWith(color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked ? Colors.white : AppColors.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.color.withValues(alpha: 0.3)
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? achievement.color.withValues(alpha: 0.1)
                  : AppColors.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                achievement.isUnlocked ? achievement.emoji : '🔒',
                style: TextStyle(
                  fontSize: 28,
                  color: achievement.isUnlocked ? null : AppColors.gray400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: achievement.isUnlocked
                        ? AppColors.gray800
                        : AppColors.gray400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: AppTextStyles.caption.copyWith(
                    color: achievement.isUnlocked
                        ? AppColors.gray500
                        : AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          if (achievement.isUnlocked)
            Icon(
              LucideIcons.badgeCheck,
              color: achievement.color,
              size: 24,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${achievement.requirement}',
                style: AppTextStyles.tiny.copyWith(color: AppColors.gray500),
              ),
            ),
        ],
      ),
    );
  }
}
