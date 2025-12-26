import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;
import '../models/challenge.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/challenge_icon.dart';
import '../widgets/error_state.dart';
import '../widgets/skeleton_loader.dart';

class ChallengesPage extends StatefulWidget {
  final String initialTab;
  
  const ChallengesPage({super.key, this.initialTab = 'goals'});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final _storage = StorageService();
  late String _activeTab;
  List<ChallengeHistoryItem> _history = [];
  bool _loading = true;
  String? _error;

  // Daily goals state
  int _breathingSessions = 0;
  int _postureChecks = 0;
  int _screenBreaks = 0;
  bool _morningStretch = false;
  bool _eveningReflection = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final historyResult = await _storage.getHistory();
      if (!mounted) return;
      
      final history = historyResult.dataOrNull ?? [];
      setState(() {
        _history = history;
        _breathingSessions = history.where((h) {
          final date = DateTime.parse(h.completedAt);
          final today = DateTime.now();
          return date.day == today.day &&
              date.month == today.month &&
              date.year == today.year &&
              h.title.toLowerCase().contains('breath');
        }).length.clamp(0, 3);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ChallengesPageSkeleton();
    }

    if (_error != null) {
      return ErrorState(
        title: 'Failed to Load',
        message: 'We couldn\'t load your challenges. Please try again.',
        onRetry: _loadData,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Wellness Goals',
              style: AppTextStyles.h2.copyWith(color: AppColors.gray900)),
          const SizedBox(height: 4),
          Text('Build healthy habits daily',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppTheme.spacing6),
          _buildTabSwitcher(),
          const SizedBox(height: AppTheme.spacing6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child:
                  _activeTab == 'goals' ? _buildGoalsTab() : _buildHistoryTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          _buildTab('goals', 'Daily Goals'),
          _buildTab('history', 'History'),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label) {
    final isActive = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isActive ? Colors.white : AppColors.gray400,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        key: const ValueKey('goals'),
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
        _buildProgressSummary(),
        const SizedBox(height: 20),
        Text('TODAY\'S GOALS',
            style: AppTextStyles.tiny
                .copyWith(color: AppColors.gray400, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildGoalCard(
          icon: LucideIcons.wind,
          title: 'Breathing Sessions',
          subtitle: '$_breathingSessions of 3 completed',
          progress: _breathingSessions / 3,
          color: AppColors.secondary,
          onTap: () => _incrementGoal('breathing'),
        ),
        _buildGoalCard(
          icon: LucideIcons.armchair,
          title: 'Posture Checks',
          subtitle: '$_postureChecks of 5 completed',
          progress: _postureChecks / 5,
          color: AppColors.info,
          onTap: () => _incrementGoal('posture'),
        ),
        _buildGoalCard(
          icon: LucideIcons.eye,
          title: 'Screen Breaks',
          subtitle: '$_screenBreaks of 4 completed',
          progress: _screenBreaks / 4,
          color: AppColors.accent,
          onTap: () => _incrementGoal('screen'),
        ),
        const SizedBox(height: 20),
        Text('DAILY RITUALS',
            style: AppTextStyles.tiny
                .copyWith(color: AppColors.gray400, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRitualCard(
                icon: LucideIcons.sunrise,
                title: 'Morning Stretch',
                isComplete: _morningStretch,
                color: AppColors.warning,
                onTap: () => setState(() => _morningStretch = !_morningStretch),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRitualCard(
                icon: LucideIcons.moon,
                title: 'Evening Reflection',
                isComplete: _eveningReflection,
                color: AppColors.info,
                onTap: () =>
                    setState(() => _eveningReflection = !_eveningReflection),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildWeeklyChallenge(),
        const SizedBox(height: 20),
      ],
    ),
    );
  }

  Widget _buildProgressSummary() {
    const totalGoals = 5;
    final completed = (_breathingSessions >= 3 ? 1 : 0) +
        (_postureChecks >= 5 ? 1 : 0) +
        (_screenBreaks >= 4 ? 1 : 0) +
        (_morningStretch ? 1 : 0) +
        (_eveningReflection ? 1 : 0);
    final progress = completed / totalGoals;
    final percentage = (progress * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 320;
        final circleSize = isSmall ? 64.0 : 80.0;
        final padding = isSmall ? 14.0 : 20.0;
        
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              // Custom circular progress
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: progress,
                    backgroundColor: AppColors.gray200,
                    progressColor: AppColors.primary,
                    strokeWidth: isSmall ? 6 : 8,
                  ),
                  child: Center(
                    child: Text(
                      '$percentage%',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontSize: isSmall ? 14 : 17,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Progress',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.gray800,
                        fontSize: isSmall ? 15 : 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed of $totalGoals goals completed',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gray500,
                        fontSize: isSmall ? 11 : 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getMotivationalIcon(percentage),
                          size: isSmall ? 14 : 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _getMotivationalMessage(percentage),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmall ? 12 : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getMotivationalIcon(int percentage) {
    if (percentage == 100) return LucideIcons.partyPopper;
    if (percentage >= 80) return LucideIcons.flame;
    if (percentage >= 60) return LucideIcons.zap;
    if (percentage >= 40) return LucideIcons.thumbsUp;
    if (percentage >= 20) return LucideIcons.sprout;
    return LucideIcons.sparkles;
  }

  String _getMotivationalMessage(int percentage) {
    if (percentage == 100) return 'Perfect day!';
    if (percentage >= 80) return 'Almost there!';
    if (percentage >= 60) return 'Great progress!';
    if (percentage >= 40) return 'Keep going!';
    if (percentage >= 20) return 'Good start!';
    return 'Let\'s begin!';
  }

  Widget _buildGoalCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double progress,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isComplete = progress >= 1.0;

    return GestureDetector(
      onTap: isComplete ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color:
                isComplete ? color.withValues(alpha: 0.3) : AppColors.gray100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gray800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.gray400),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.gray100,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!isComplete)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.plus, size: 18, color: color),
              )
            else
              Icon(LucideIcons.circleCheck, size: 24, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildRitualCard({
    required IconData icon,
    required String title,
    required bool isComplete,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isComplete
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.gray100,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppColors.success.withValues(alpha: 0.15)
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isComplete ? AppColors.success : color,
                  ),
                ),
                Icon(
                  isComplete ? LucideIcons.circleCheck : LucideIcons.circle,
                  size: 20,
                  color: isComplete ? AppColors.success : AppColors.gray300,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isComplete ? AppColors.success : AppColors.gray700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _incrementGoal(String type) {
    setState(() {
      switch (type) {
        case 'breathing':
          if (_breathingSessions < 3) _breathingSessions++;
          break;
        case 'posture':
          if (_postureChecks < 5) _postureChecks++;
          break;
        case 'screen':
          if (_screenBreaks < 4) _screenBreaks++;
          break;
      }
    });
  }

  Widget _buildWeeklyChallenge() {
    final completedThisWeek = _history.where((h) {
      final date = DateTime.parse(h.completedAt);
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return date.isAfter(weekStart);
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dark, AppColors.darkMuted],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.trophy,
                    size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Text(
                'WEEKLY CHALLENGE',
                style: AppTextStyles.tiny.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Wellness Warrior',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete 7 wellness challenges this week to earn the badge.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (completedThisWeek / 7).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completedThisWeek/7',
                style:
                    AppTextStyles.captionBold.copyWith(color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return Center(
        key: const ValueKey('history-empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.history,
                  size: 40, color: AppColors.gray300),
            ),
            const SizedBox(height: 16),
            Text(
              'No challenges completed yet',
              style: AppTextStyles.body.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete wellness challenges to see them here',
              style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    final groupedHistory = <String, List<ChallengeHistoryItem>>{};
    for (final item in _history) {
      final date = DateTime.parse(item.completedAt);
      final key = _formatDateKey(date);
      groupedHistory.putIfAbsent(key, () => []).add(item);
    }

    return ListView.builder(
      key: const ValueKey('history'),
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: groupedHistory.length,
      itemBuilder: (context, index) {
        final dateKey = groupedHistory.keys.elementAt(index);
        final items = groupedHistory[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                dateKey,
                style:
                    AppTextStyles.captionBold.copyWith(color: AppColors.gray400),
              ),
            ),
            ...items.map((item) => _buildHistoryItem(item)),
          ],
        );
      },
    );
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'Today';
    if (itemDate == yesterday) return 'Yesterday';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildHistoryItem(ChallengeHistoryItem item) {
    final completedDate = DateTime.parse(item.completedAt);
    final timeStr =
        '${completedDate.hour.toString().padLeft(2, '0')}:${completedDate.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: ChallengeIcon(emoji: item.emoji, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(LucideIcons.clock,
                        size: 12, color: AppColors.gray400),
                    const SizedBox(width: 4),
                    Text(
                      '$timeStr • ${item.duration}',
                      style:
                          AppTextStyles.tiny.copyWith(color: AppColors.gray400),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.circleCheck, size: 18, color: AppColors.success),
        ],
      ),
    );
  }
}

// Custom circular progress painter
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
