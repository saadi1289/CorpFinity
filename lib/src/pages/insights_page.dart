import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/challenge.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/skeleton_loader.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});
  
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final _storage = StorageService();
  List<ChallengeHistoryItem> _history = [];
  int _streak = 0;
  DateTime _currentDate = DateTime.now();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final historyResult = await _storage.getHistory();
      final stateResult = await _storage.getState();

      if (!mounted) return;

      setState(() {
        _history = historyResult.dataOrNull ?? [];
        _streak = stateResult.dataOrNull?['streak'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load insights';
        _loading = false;
      });
    }
  }
  
  void _changeMonth(int delta) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + delta, 1);
    });
  }
  
  List<DateTime?> _getCalendarDays() {
    final firstDay = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDay = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final startDayOfWeek = firstDay.weekday % 7; // Convert to 0=Sunday
    
    final days = <DateTime?>[];
    for (int i = 0; i < startDayOfWeek; i++) {
      days.add(null);
    }
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentDate.year, _currentDate.month, i));
    }
    return days;
  }
  
  bool _hasActivity(DateTime date) {
    return _history.any((h) {
      final hDate = DateTime.parse(h.completedAt);
      return hDate.year == date.year &&
          hDate.month == date.month &&
          hDate.day == date.day;
    });
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.circleAlert,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTextStyles.h3.copyWith(color: AppColors.gray800),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Failed to load data',
              style: AppTextStyles.body.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.chartBar,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Insights Yet',
              style: AppTextStyles.h2.copyWith(color: AppColors.gray800),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your first wellness challenge\nto start tracking your progress',
              style: AppTextStyles.body.copyWith(
                color: AppColors.gray500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.lightbulb, size: 20, color: AppColors.info),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Tip: Start with a quick 1-minute challenge!',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const InsightsPageSkeleton();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_history.isEmpty && _streak == 0) {
      return _buildEmptyState();
    }

    final calendarDays = _getCalendarDays();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(AppTheme.spacing6),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Wellness Insights', style: AppTextStyles.h2.copyWith(color: AppColors.gray900)),
          const SizedBox(height: 4),
          Text('Your progress at a glance', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500)),
          const SizedBox(height: AppTheme.spacing6),
          
          // Stats Grid - responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 340;
              final padding = isSmall ? 14.0 : 20.0;
              final streakFontSize = isSmall ? 32.0 : 40.0;
              
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.flame, size: isSmall ? 14 : 18, color: Colors.white),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'STREAK',
                                  style: AppTextStyles.tiny.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: isSmall ? 9 : 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_streak',
                            style: TextStyle(color: Colors.white, fontSize: streakFontSize, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Days in a row',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: isSmall ? 11 : 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isSmall ? 10 : 16),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(color: AppColors.gray100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.award, size: isSmall ? 14 : 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'TOTAL',
                                  style: AppTextStyles.tiny.copyWith(
                                    color: AppColors.gray400,
                                    fontSize: isSmall ? 9 : 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_history.length}',
                            style: AppTextStyles.display.copyWith(
                              color: AppColors.gray900,
                              fontSize: streakFontSize,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sessions completed',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gray400,
                              fontSize: isSmall ? 11 : 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.spacing6),
          
          // Calendar Card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radius2Xl),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                // Month header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${months[_currentDate.month - 1]} ${_currentDate.year}',
                      style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, size: 20),
                          onPressed: () => _changeMonth(-1),
                          color: AppColors.gray400,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.chevronRight, size: 20),
                          onPressed: () => _changeMonth(1),
                          color: AppColors.gray400,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing6),
                
                // Week days header - responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = (constraints.maxWidth - 48) / 7;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                        return SizedBox(
                          width: cellSize,
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.captionBold.copyWith(color: AppColors.gray300),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Calendar grid - responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = (constraints.maxWidth - 48) / 7; // 7 days, 6 gaps of 8px
                    return Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: calendarDays.map((date) {
                        if (date == null) {
                          return SizedBox(width: cellSize, height: cellSize);
                        }
                        
                        final hasActivity = _hasActivity(date);
                        final isToday = _isToday(date);
                        
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: hasActivity ? AppColors.primary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isToday && !hasActivity
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                            boxShadow: hasActivity
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: cellSize * 0.38,
                                fontWeight: FontWeight.w500,
                                color: hasActivity
                                    ? Colors.white
                                    : (isToday ? AppColors.primary : AppColors.gray600),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spacing6),
                
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Completed', style: AppTextStyles.tiny.copyWith(color: AppColors.gray400)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Today', style: AppTextStyles.tiny.copyWith(color: AppColors.gray400)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing6),
          
          // Weekly Activity Graph
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing6),
            decoration: BoxDecoration(
              color: AppColors.gray900,
              borderRadius: BorderRadius.circular(AppTheme.radius2Xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WEEKLY RHYTHM',
                          style: AppTextStyles.tiny.copyWith(color: AppColors.gray400),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Activity Level',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.activity, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing6),
                
                // Bar chart - responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = (constraints.maxWidth - 72) / 7; // 7 bars with gaps
                    final clampedBarWidth = barWidth.clamp(20.0, 40.0);
                    
                    return SizedBox(
                      height: 96,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [65, 40, 100, 30, 80, 20, 50].asMap().entries.map((entry) {
                          final index = entry.key;
                          final height = entry.value;
                          final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: clampedBarWidth,
                                height: 72 * (height / 100),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [AppColors.primary, AppColors.secondary],
                                  ),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                days[index],
                                style: AppTextStyles.tiny.copyWith(color: AppColors.gray500),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
