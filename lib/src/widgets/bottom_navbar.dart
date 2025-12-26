import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/app_view.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'tutorial_overlay.dart';

class BottomNavbar extends StatelessWidget {
  final AppView currentView;
  final Function(AppView) onChangeView;
  
  const BottomNavbar({
    super.key,
    required this.currentView,
    required this.onChangeView,
  });
  
  static const _items = [
    (view: AppView.home, icon: LucideIcons.sparkles, label: 'Flow'),
    (view: AppView.challenges, icon: LucideIcons.target, label: 'Goals'),
    (view: AppView.insights, icon: LucideIcons.trendingUp, label: 'Insights'),
    (view: AppView.profile, icon: LucideIcons.user, label: 'Profile'),
  ];
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: TutorialTargets.bottomNav,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.gray200.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.only(
          left: AppTheme.spacing4,
          right: AppTheme.spacing4,
          top: 8,
          bottom: 8,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.map((item) {
              return _NavItem(
                key: ValueKey(item.view),
                view: item.view,
                icon: item.icon,
                label: item.label,
                isActive: currentView == item.view,
                onTap: () => onChangeView(item.view),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final AppView view;
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  
  const _NavItem({
    super.key,
    required this.view,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    HapticFeedback.selectionClick();
    widget.onTap();
  }
  
  void _handleTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 10.0 : 16.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;
    final fontSize = isSmallScreen ? 10.0 : 11.0;
    
    return Semantics(
      button: true,
      selected: widget.isActive,
      label: '${widget.label} tab${widget.isActive ? ", selected" : ""}',
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isActive 
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with smooth color transition
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: widget.isActive ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Icon(
                    widget.icon,
                    size: iconSize,
                    color: Color.lerp(
                      AppColors.gray400,
                      AppColors.primary,
                      value,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              
              // Label
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: widget.isActive ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: value > 0.5 ? FontWeight.w600 : FontWeight.w500,
                      color: Color.lerp(AppColors.gray400, AppColors.primary, value),
                      letterSpacing: 0.2,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
