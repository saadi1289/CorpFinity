import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../tutorial_overlay.dart';

/// Hero card for starting wellness flow
class HeroCard extends StatefulWidget {
  final VoidCallback onTap;

  const HeroCard({super.key, required this.onTap});

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Start your wellness flow. Tap to begin personalized challenges.',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            key: TutorialTargets.heroCard,
            height: 192,
            padding: const EdgeInsets.all(AppTheme.spacing6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                  AppColors.secondary
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radius2Xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.sparkles,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Start Your Flow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalized CorpFinity challenges',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        _HeroCardIcon(
                          outlineIcon: HeroiconsOutline.bolt,
                          solidIcon: HeroiconsSolid.bolt,
                        ),
                        _HeroCardIcon(
                          outlineIcon: HeroiconsOutline.lightBulb,
                          solidIcon: HeroiconsSolid.lightBulb,
                        ),
                        _HeroCardIcon(
                          outlineIcon: HeroiconsOutline.heart,
                          solidIcon: HeroiconsSolid.heart,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Go',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(LucideIcons.chevronRight,
                              size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCardIcon extends StatefulWidget {
  final IconData outlineIcon;
  final IconData solidIcon;

  const _HeroCardIcon({
    required this.outlineIcon,
    required this.solidIcon,
  });

  @override
  State<_HeroCardIcon> createState() => _HeroCardIconState();
}

class _HeroCardIconState extends State<_HeroCardIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isHovered ? widget.solidIcon : widget.outlineIcon,
            key: ValueKey(_isHovered),
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
