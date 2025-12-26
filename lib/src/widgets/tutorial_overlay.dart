import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Tutorial target keys - use these in your widgets to make them highlightable
class TutorialTargets {
  static final heroCard = GlobalKey(debugLabel: 'tutorial_hero_card');
  static final moodTracker = GlobalKey(debugLabel: 'tutorial_mood_tracker');
  static final hydration = GlobalKey(debugLabel: 'tutorial_hydration');
  static final bottomNav = GlobalKey(debugLabel: 'tutorial_bottom_nav');
}

/// Premium tutorial overlay that finds widgets by GlobalKey
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final Widget child;

  const TutorialOverlay({
    super.key,
    required this.onComplete,
    required this.child,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  Rect? _highlightRect;
  
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<_TutorialStep> get _steps => [
    const _TutorialStep(
      id: 'welcome',
      icon: LucideIcons.sparkles,
      title: 'Welcome to CorpFinity!',
      subtitle: 'Your wellness journey starts here',
      description: 'Take a quick tour of your personalized wellness dashboard.',
      targetKey: null,
    ),
    _TutorialStep(
      id: 'heroCard',
      icon: LucideIcons.play,
      title: 'Start Your Flow',
      subtitle: 'Personalized challenges',
      description: 'Tap here to begin a guided wellness session tailored to your goals and energy level.',
      targetKey: TutorialTargets.heroCard,
    ),
    _TutorialStep(
      id: 'mood',
      icon: LucideIcons.smile,
      title: 'Track Your Mood',
      subtitle: 'Understand patterns',
      description: 'Log how you\'re feeling and get personalized tips based on your emotional state.',
      targetKey: TutorialTargets.moodTracker,
    ),
    _TutorialStep(
      id: 'hydration',
      icon: LucideIcons.droplets,
      title: 'Stay Hydrated',
      subtitle: 'Daily water intake',
      description: 'Track your water consumption. Tap + each time you drink to reach your daily goal.',
      targetKey: TutorialTargets.hydration,
    ),
    _TutorialStep(
      id: 'navigation',
      icon: LucideIcons.layoutGrid,
      title: 'Explore the App',
      subtitle: 'Navigate with ease',
      description: 'Use the bottom tabs to access Flow, Goals, Insights, and Profile.',
      targetKey: TutorialTargets.bottomNav,
    ),
    const _TutorialStep(
      id: 'ready',
      icon: LucideIcons.rocket,
      title: 'You\'re All Set!',
      subtitle: 'Begin your journey',
      description: 'Start with your first wellness challenge. Small steps lead to big changes!',
      targetKey: null,
      isLast: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    // Delay to let widgets build, then find target
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHighlightRect();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _updateHighlightRect() {
    final step = _steps[_currentStep];
    if (step.targetKey == null) {
      setState(() => _highlightRect = null);
      return;
    }

    final renderBox = step.targetKey!.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      setState(() {
        _highlightRect = Rect.fromLTWH(
          position.dx - 6,
          position.dy - 6,
          size.width + 12,
          size.height + 12,
        );
      });
    } else {
      setState(() => _highlightRect = null);
    }
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep < _steps.length - 1) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep++);
        _updateHighlightRect();
        _fadeController.forward();
      });
    } else {
      _complete();
    }
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep--);
        _updateHighlightRect();
        _fadeController.forward();
      });
    }
  }

  void _complete() {
    HapticFeedback.mediumImpact();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final safeArea = mediaQuery.padding;
    final step = _steps[_currentStep];

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // App content
          widget.child,

          // Overlay with cutout
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, _) => IgnorePointer(
              child: CustomPaint(
                size: screenSize,
                painter: _OverlayPainter(
                  opacity: 0.9 * _fadeAnimation.value,
                  highlightRect: _highlightRect,
                ),
              ),
            ),
          ),

          // Pulsing highlight border
          if (_highlightRect != null)
            _buildHighlightBorder(),

          // Tutorial card - positioned based on highlight
          _buildTutorialCard(step, screenSize, safeArea),

          // Progress bar at top
          _buildProgressBar(safeArea),
        ],
      ),
    );
  }

  Widget _buildProgressBar(EdgeInsets safeArea) {
    return Positioned(
      top: safeArea.top + 16,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) => Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        ),
        child: Row(
          children: [
            // Progress dots
            Expanded(
              child: Row(
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _currentStep;
                  final isPast = index < _currentStep;
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : isPast
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 16),
            // Skip
            GestureDetector(
              onTap: _complete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Skip',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightBorder() {
    return Positioned(
      left: _highlightRect!.left,
      top: _highlightRect!.top,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final pulse = Curves.easeInOut.transform(_pulseController.value);
            return Container(
              width: _highlightRect!.width,
              height: _highlightRect!.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7 + pulse * 0.3),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3 + pulse * 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildTutorialCard(_TutorialStep step, Size screenSize, EdgeInsets safeArea) {
    // Calculate card position based on highlight
    double cardTop;
    const cardHeight = 280.0; // Increased to account for content
    const minGap = 20.0; // Minimum gap between card and highlight
    
    if (_highlightRect == null) {
      // Center for welcome/final screens
      cardTop = (screenSize.height - cardHeight) / 2;
    } else {
      // Calculate available space above and below the highlight
      final spaceAbove = _highlightRect!.top - safeArea.top - 60; // 60 for progress bar
      final spaceBelow = screenSize.height - _highlightRect!.bottom - safeArea.bottom - 20;
      
      // Choose position with more space, ensuring no overlap
      if (spaceBelow >= cardHeight + minGap) {
        // Enough space below - place card below highlight
        cardTop = _highlightRect!.bottom + minGap;
      } else if (spaceAbove >= cardHeight + minGap) {
        // Enough space above - place card above highlight
        cardTop = _highlightRect!.top - cardHeight - minGap;
      } else if (spaceBelow > spaceAbove) {
        // More space below but not enough - place at bottom of screen
        cardTop = screenSize.height - safeArea.bottom - cardHeight - 20;
        // Ensure we don't overlap the highlight
        if (cardTop < _highlightRect!.bottom + minGap) {
          cardTop = _highlightRect!.bottom + minGap;
        }
      } else {
        // More space above but not enough - place at top
        cardTop = safeArea.top + 60;
        // Ensure we don't overlap the highlight
        if (cardTop + cardHeight > _highlightRect!.top - minGap) {
          cardTop = _highlightRect!.top - cardHeight - minGap;
        }
      }
      
      // Final bounds check
      cardTop = cardTop.clamp(safeArea.top + 60, screenSize.height - safeArea.bottom - cardHeight - 20);
    }

    return Positioned(
      top: cardTop,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) => Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - _fadeAnimation.value)),
            child: child,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              _buildIcon(step),
              const SizedBox(height: 16),
              
              // Title & subtitle
              Text(
                step.title,
                style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                step.subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                step.description,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.gray600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Buttons
              _buildButtons(step),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(_TutorialStep step) {
    // Always use primary terracotta colors for consistent warm theme
    const colors = [AppColors.primary, AppColors.primaryLight];

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final scale = 1.0 + Curves.easeInOut.transform(_pulseController.value) * 0.05;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(step.icon, size: 26, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildButtons(_TutorialStep step) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: GestureDetector(
              onTap: _previousStep,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.gray600),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: AppTextStyles.button.copyWith(color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: _currentStep > 0 ? 1 : 1,
          child: _buildNextButton(step),
        ),
      ],
    );
  }

  Widget _buildNextButton(_TutorialStep step) {
    final isLast = step.isLast;
    // Always use primary terracotta colors for consistent warm theme
    const colors = [AppColors.primary, AppColors.primaryLight];

    return GestureDetector(
      onTap: _nextStep,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLast ? 'Get Started' : 'Next',
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
            const SizedBox(width: 6),
            Icon(
              isLast ? LucideIcons.arrowRight : LucideIcons.chevronRight,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStep {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final GlobalKey? targetKey;
  final bool isLast;

  const _TutorialStep({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.targetKey,
    this.isLast = false,
  });
}

class _OverlayPainter extends CustomPainter {
  final double opacity;
  final Rect? highlightRect;

  _OverlayPainter({
    required this.opacity,
    required this.highlightRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final paint = Paint()..color = const Color(0xFF1A1A2E).withValues(alpha: opacity);

    if (highlightRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    // Draw overlay with rounded cutout
    final cutoutPaint = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    final rrect = RRect.fromRectAndRadius(highlightRect!, const Radius.circular(20));
    canvas.drawRRect(rrect, cutoutPaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.highlightRect != highlightRect;
}
