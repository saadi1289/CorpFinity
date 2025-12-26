import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_button.dart';
import 'reminders_page.dart';
import 'terms_privacy_page.dart';
import 'achievements_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;
  final Function(User) onUpdateUser;
  final VoidCallback? onNavigateToHistory;

  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onUpdateUser,
    this.onNavigateToHistory,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _storage = StorageService();
  final _notificationService = NotificationService();
  
  bool _isEditing = false;
  bool _loading = false;
  bool _notifications = true;
  bool _notificationSound = true;
  bool _notificationVibration = true;

  // Stats
  int _totalChallenges = 0;
  int _currentStreak = 0;
  int _totalMinutes = 0;

  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  String _editAvatarSeed = '';
  late AnimationController _transitionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _passwordController = TextEditingController();
    _editAvatarSeed = widget.user.email;

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _loadStats();
  }

  Future<void> _loadStats() async {
    final historyResult = await _storage.getHistory();
    final stateResult = await _storage.getState();
    
    final history = historyResult.dataOrNull ?? [];
    final state = stateResult.dataOrNull;

    int totalMins = 0;
    for (final item in history) {
      final duration = item.duration;
      final num = int.tryParse(duration.split(' ')[0]) ?? 0;
      if (duration.toLowerCase().contains('min')) {
        totalMins += num;
      } else if (duration.toLowerCase().contains('sec')) {
        totalMins += (num / 60).ceil();
      }
    }

    setState(() {
      _totalChallenges = history.length;
      _currentStreak = state?['streak'] ?? 0;
      _totalMinutes = totalMins;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _loading = true);

    try {
      final updatedUser = widget.user.copyWith(
        name: _nameController.text,
        avatar:
            'https://api.dicebear.com/7.x/avataaars/svg?seed=$_editAvatarSeed',
      );

      await _authService.updateUser(updatedUser);
      widget.onUpdateUser(updatedUser);

      _transitionController.reverse().then((_) {
        if (mounted) {
          setState(() => _isEditing = false);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _transitionController.forward(from: 0);
  }

  void _handleCancel() {
    _transitionController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isEditing = false;
          _nameController.text = widget.user.name;
          _editAvatarSeed = widget.user.email;
          _passwordController.clear();
        });
      }
    });
  }

  void _shuffleAvatar() {
    setState(() {
      _editAvatarSeed = Random().nextInt(1000000).toString();
    });
  }

  String get _currentAvatarUrl {
    if (_isEditing) {
      return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$_editAvatarSeed';
    }
    final seed = widget.user.avatar?.split('seed=').last ?? widget.user.email;
    return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$seed';
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Notification Settings',
                style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
              ),
              const SizedBox(height: 8),
              Text(
                'Customize how you receive notifications',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
              ),
              const SizedBox(height: 24),
              _buildModalToggle(
                icon: LucideIcons.volume2,
                title: 'Sound',
                subtitle: 'Play sound for notifications',
                value: _notificationSound,
                setModalState: setModalState,
                onChanged: (value) => setState(() => _notificationSound = value),
              ),
              const SizedBox(height: 12),
              _buildModalToggle(
                icon: LucideIcons.vibrate,
                title: 'Vibration',
                subtitle: 'Vibrate for notifications',
                value: _notificationVibration,
                setModalState: setModalState,
                onChanged: (value) => setState(() => _notificationVibration = value),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 20, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These settings will apply to all reminder notifications.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required StateSetter setModalState,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        setModalState(() {});
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.gray600),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.gray200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.triangleAlert, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Delete Account'),
            ],
          ),
          titleTextStyle: AppTextStyles.h4.copyWith(color: AppColors.gray900),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action is permanent and cannot be undone. All your data will be deleted including:',
                style: AppTextStyles.body.copyWith(color: AppColors.gray600),
              ),
              const SizedBox(height: 16),
              _buildDeleteItem('Your profile information'),
              _buildDeleteItem('Challenge history'),
              _buildDeleteItem('Streak progress'),
              _buildDeleteItem('All reminders'),
              const SizedBox(height: 16),
              Text(
                'Type "DELETE" to confirm:',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  filled: true,
                  fillColor: AppColors.gray50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
              ),
            ),
            ElevatedButton(
              onPressed: confirmController.text == 'DELETE'
                  ? () async {
                      Navigator.pop(context);
                      await _deleteAccount();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.gray200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(LucideIcons.x, size: 14, color: AppColors.error),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray600),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _loading = true);
    
    try {
      // Clear all local data
      await _storage.clearAllData();
      await _authService.logout();
      
      if (mounted) {
        widget.onLogout();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacing6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Profile' : 'Profile',
                    style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
                  ),
                  if (!_isEditing)
                    GestureDetector(
                      onTap: _startEditing,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.pencil,
                            size: 18, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing6),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.03, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: _isEditing ? _buildEditMode() : _buildViewMode(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewMode() {
    return Column(
      key: const ValueKey('view'),
      children: [
        // Profile card with avatar
        _buildProfileCard(),
        const SizedBox(height: 20),

        // Stats row
        _buildStatsRow(),
        const SizedBox(height: 24),

        // Quick Actions
        Text(
          'QUICK ACTIONS',
          style: AppTextStyles.tiny
              .copyWith(color: AppColors.gray400, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),

        _buildActionTile(
          icon: LucideIcons.trophy,
          iconColor: AppColors.warning,
          title: 'Achievements',
          subtitle: 'View your badges and progress',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AchievementsPage()),
          ),
        ),
        const SizedBox(height: 10),

        _buildActionTile(
          icon: LucideIcons.share2,
          iconColor: AppColors.primary,
          title: 'Share Progress',
          subtitle: 'Share your wellness journey',
          onTap: () => ShareService.shareStreak(
            context: context,
            streak: _currentStreak,
            totalChallenges: _totalChallenges,
          ),
        ),
        const SizedBox(height: 10),

        _buildActionTile(
          icon: LucideIcons.bell,
          iconColor: AppColors.accent,
          title: 'Reminders',
          subtitle: 'Manage wellness reminders',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RemindersPage()),
          ),
        ),
        const SizedBox(height: 10),

        _buildActionTile(
          icon: LucideIcons.history,
          iconColor: AppColors.info,
          title: 'Activity History',
          subtitle: 'View past challenges',
          onTap: widget.onNavigateToHistory ?? () {},
        ),
        const SizedBox(height: 24),

        // Settings
        Text(
          'SETTINGS',
          style: AppTextStyles.tiny
              .copyWith(color: AppColors.gray400, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),

        _buildSettingToggle(
          icon: LucideIcons.bellRing,
          iconColor: AppColors.secondary,
          title: 'Push Notifications',
          subtitle: 'Receive reminder alerts',
          value: _notifications,
          onChanged: (value) async {
            if (value) {
              await _notificationService.requestPermissions();
            }
            setState(() => _notifications = value);
          },
        ),
        const SizedBox(height: 10),

        _buildActionTile(
          icon: LucideIcons.settings2,
          iconColor: AppColors.accent,
          title: 'Notification Settings',
          subtitle: 'Sound, vibration & more',
          onTap: _showNotificationSettings,
        ),
        const SizedBox(height: 10),

        _buildActionTile(
          icon: LucideIcons.circleHelp,
          iconColor: AppColors.gray500,
          title: 'Help & Support',
          subtitle: 'FAQs and contact us',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Help & Support coming soon!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        _buildActionTile(
          icon: LucideIcons.fileText,
          iconColor: AppColors.gray500,
          title: 'Terms & Privacy',
          subtitle: 'Legal information',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsPrivacyPage()),
          ),
        ),
        const SizedBox(height: 24),

        // Danger Zone
        Text(
          'DANGER ZONE',
          style: AppTextStyles.tiny
              .copyWith(color: AppColors.error, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),

        _buildActionTile(
          icon: LucideIcons.trash2,
          iconColor: AppColors.error,
          title: 'Delete Account',
          subtitle: 'Permanently delete your data',
          onTap: _showDeleteAccountDialog,
        ),
        const SizedBox(height: 24),

        // Logout button
        CustomButton(
          text: 'Log Out',
          onPressed: widget.onLogout,
          variant: ButtonVariant.outline,
          fullWidth: true,
          icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.error),
        ),
        const SizedBox(height: 16),

        Center(
          child: Text(
            'CorpFinity v1.3.0',
            style: AppTextStyles.tiny.copyWith(color: AppColors.gray300),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius2Xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                _currentAvatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.gray100,
                  child: const Icon(LucideIcons.user, color: AppColors.gray400),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            widget.user.name,
            style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            widget.user.email,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: 12),

          // Member badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Wellness Member',
                  style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 320;
        final gap = isSmall ? 8.0 : 12.0;
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.flame,
                value: '$_currentStreak',
                label: 'Day Streak',
                color: AppColors.warning,
                isSmall: isSmall,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.target,
                value: '$_totalChallenges',
                label: 'Challenges',
                color: AppColors.secondary,
                isSmall: isSmall,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.clock,
                value: '$_totalMinutes',
                label: 'Minutes',
                color: AppColors.info,
                isSmall: isSmall,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmall ? 12 : 16,
        horizontal: isSmall ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Icon(icon, size: isSmall ? 16 : 20, color: color),
          SizedBox(height: isSmall ? 6 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.gray900,
                fontSize: isSmall ? 18 : 20,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.gray400,
                fontSize: isSmall ? 9 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.gray800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.gray400),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 18, color: AppColors.gray300),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.gray800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.gray400),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.gray200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEditMode() {
    return Column(
      key: const ValueKey('edit'),
      children: [
        // Avatar editor
        _buildAnimatedItem(
          delay: 0,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        _currentAvatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.gray100),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _shuffleAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(LucideIcons.shuffle,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to randomize avatar',
                style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Name field
        _buildAnimatedItem(
          delay: 50,
          child: _buildTextField(
            label: 'FULL NAME',
            controller: _nameController,
            icon: LucideIcons.user,
            enabled: true,
          ),
        ),
        const SizedBox(height: 16),

        // Email field (disabled)
        _buildAnimatedItem(
          delay: 100,
          child: _buildTextField(
            label: 'EMAIL ADDRESS',
            controller: TextEditingController(text: widget.user.email),
            icon: LucideIcons.mail,
            enabled: false,
          ),
        ),
        const SizedBox(height: 16),

        // Password field
        _buildAnimatedItem(
          delay: 150,
          child: _buildTextField(
            label: 'NEW PASSWORD',
            controller: _passwordController,
            icon: LucideIcons.lock,
            enabled: true,
            obscure: true,
            hint: 'Leave blank to keep current',
          ),
        ),
        const SizedBox(height: 32),

        // Action buttons
        _buildAnimatedItem(
          delay: 200,
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: _handleCancel,
                  variant: ButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: _loading ? 'Saving...' : 'Save',
                  onPressed: _loading ? null : _handleSave,
                  isLoading: _loading,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    bool obscure = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.tiny
              .copyWith(color: AppColors.gray400, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: hint,
            filled: true,
            fillColor: enabled ? Colors.white : AppColors.gray50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: const BorderSide(color: AppColors.gray100),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedItem({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }
}
