import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/error_state.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _syncService = SyncService();
  
  List<Map<String, dynamic>> _achievements = [];
  int _unlockedCount = 0;
  int _totalCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _syncService.getAchievements();
      
      if (result.isSuccess) {
        final data = result.data!;
        setState(() {
          _achievements = (data['achievements'] as List).cast<Map<String, dynamic>>();
          _unlockedCount = data['unlocked_count'] ?? 0;
          _totalCount = data['total_count'] ?? _achievements.length;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result.errorMessage;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading ? _buildLoading() : _error != null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Loading achievements...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return ErrorState(
      title: 'Failed to Load Achievements',
      message: _error ?? 'Something went wrong',
      onRetry: _loadAchievements,
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAchievements,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(AppTheme.spacing6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          LucideIcons.trophy,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Progress',
                              style: AppTextStyles.h3.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_unlockedCount of $_totalCount unlocked',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _totalCount > 0 ? _unlockedCount / _totalCount : 0,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Achievements grid
            Text(
              'All Achievements',
              style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
            ),
            const SizedBox(height: 16),
            
            if (_achievements.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.trophy,
                        size: 64,
                        color: AppColors.gray300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No achievements yet',
                        style: AppTextStyles.h4.copyWith(color: AppColors.gray500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete challenges to unlock achievements!',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray400),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _achievements.length,
                itemBuilder: (context, index) {
                  final achievement = _achievements[index];
                  return _AchievementCard(achievement: achievement);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Map<String, dynamic> achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement['is_unlocked'] ?? false;
    final title = achievement['title'] ?? 'Achievement';
    final description = achievement['description'] ?? '';
    final emoji = achievement['emoji'] ?? '🏆';
    final category = achievement['category'] ?? 'general';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : AppColors.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isUnlocked ? AppColors.primary.withValues(alpha: 0.2) : AppColors.gray200,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ] : [
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
          // Icon and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUnlocked 
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.gray200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 24,
                      color: isUnlocked ? null : AppColors.gray400,
                    ),
                  ),
                ),
              ),
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Title
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isUnlocked ? AppColors.gray900 : AppColors.gray500,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Description
          Expanded(
            child: Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: isUnlocked ? AppColors.gray600 : AppColors.gray400,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked 
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.gray200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              category.toUpperCase(),
              style: AppTextStyles.tiny.copyWith(
                color: isUnlocked ? AppColors.primary : AppColors.gray500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}