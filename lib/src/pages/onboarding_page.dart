import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _contentController;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      icon: null, // Uses logo instead
      isLogo: true,
      title: 'Welcome to CorpFinity',
      description:
          'Your personal wellness companion for a healthier, more balanced work life.',
      gradient: [AppColors.primary, AppColors.primaryLight],
      bgGradient: [
        const Color(0xFFF0F4FF),
        const Color(0xFFE8F0FE),
      ],
    ),
    OnboardingItem(
      icon: LucideIcons.target,
      title: 'Personalized Challenges',
      description:
          'Get wellness challenges tailored to your goals and energy levels throughout the day.',
      gradient: [AppColors.secondary, AppColors.secondaryLight],
      bgGradient: [
        const Color(0xFFF0FDF4),
        const Color(0xFFDCFCE7),
      ],
    ),
    OnboardingItem(
      icon: LucideIcons.bellRing,
      title: 'Smart Reminders',
      description:
          'Set reminders for hydration, stretching, meditation, and more to stay on track.',
      gradient: [AppColors.accent, AppColors.accentLight],
      bgGradient: [
        const Color(0xFFFFF7ED),
        const Color(0xFFFFEDD5),
      ],
    ),
    OnboardingItem(
      icon: LucideIcons.trophy,
      title: 'Track Your Progress',
      description:
          'Build streaks, complete daily goals, and watch your wellness journey grow.',
      gradient: [AppColors.info, const Color(0xFF9BB8D0)],
      bgGradient: [
        const Color(0xFFF0F9FF),
        const Color(0xFFE0F2FE),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _contentController.reset();
    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.bgGradient,
              ),
            ),
          ),

          // Floating particles - wrapped in RepaintBoundary for performance
          ...List.generate(8, (index) => _buildParticle(index, item)),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_items[index], index);
                    },
                  ),
                ),

                // Page indicators
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (index) {
                      final isActive = _currentPage == index;
                      return GestureDetector(
                        onTap: () => _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 32 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? LinearGradient(colors: item.gradient)
                                : null,
                            color: isActive ? null : AppColors.gray300,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color:
                                          item.gradient[0].withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Next/Get Started button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: _buildAnimatedButton(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticle(int index, OnboardingItem item) {
    final random = math.Random(index);
    final size = 10.0 + random.nextDouble() * 16;
    final startX = random.nextDouble();
    final startY = random.nextDouble();
    final speed = 0.3 + random.nextDouble() * 0.4;

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value * speed) % 1.0;
        final x = (startX + progress * 0.3) % 1.0;
        final y = (startY +
                math.sin(progress * math.pi * 2) * 0.08 +
                progress * 0.15) %
            1.0;
        final screenSize = MediaQuery.sizeOf(context);

        return Positioned(
          left: x * screenSize.width,
          top: y * screenSize.height,
          child: IgnorePointer(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.gradient[0].withValues(alpha: 0.2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(OnboardingItem item, int index) {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 700;
        final horizontalPadding = isSmallScreen ? 24.0 : 32.0;
        
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _contentController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        ));

        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

        final titleSlide = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _contentController,
          curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
        ));

        final descSlide = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _contentController,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
        ));

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated floating icon container
              SlideTransition(
                position: slideAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: _buildAnimatedIcon(item),
                ),
              ),
              SizedBox(height: isSmallScreen ? 32 : 48),

              // Title with staggered animation
              SlideTransition(
                position: titleSlide,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppColors.gray900,
                        item.gradient[0].withValues(alpha: 0.8),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      item.title,
                      style: AppTextStyles.h1.copyWith(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 24 : 28,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 14 : 20),

              // Description with staggered animation
              SlideTransition(
                position: descSlide,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: Text(
                    item.description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gray600,
                      height: 1.6,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIcon(OnboardingItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive icon size based on available width
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 700;
        final iconContainerSize = isSmallScreen 
            ? (screenWidth * 0.32).clamp(100.0, 130.0)
            : (screenWidth * 0.38).clamp(120.0, 150.0);
        final borderRadius = iconContainerSize * 0.3;
        final iconSize = iconContainerSize * 0.47;
        final logoSize = iconContainerSize * 0.67;
        
        return AnimatedBuilder(
          animation: Listenable.merge([_floatController, _pulseController]),
          builder: (context, child) {
            final floatValue = math.sin(_floatController.value * math.pi) * (isSmallScreen ? 5 : 8);
            final pulseValue = 1.0 + (_pulseController.value * 0.08);
            final glowOpacity = 0.3 + (_pulseController.value * 0.2);

            return Transform.translate(
              offset: Offset(0, floatValue),
              child: Transform.scale(
                scale: pulseValue,
                child: Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item.gradient,
                    ),
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: item.gradient[0].withValues(alpha: glowOpacity),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: item.gradient[1].withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: item.gradient[0].withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(borderRadius),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(
                                      -1 + (_pulseController.value * 2),
                                      -1,
                                    ),
                                    end: Alignment(
                                      _pulseController.value * 2,
                                      1,
                                    ),
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.2),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (item.isLogo)
                        Padding(
                          padding: EdgeInsets.all(iconContainerSize * 0.17),
                          child: SvgPicture.asset(
                            'assets/logo/corpfinity_logo.svg',
                            width: logoSize,
                            height: logoSize,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        )
                      else
                        Icon(
                          item.icon,
                          size: iconSize,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedButton(OnboardingItem item) {
    final isLastPage = _currentPage == _items.length - 1;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isLastPage ? 1.0 + (_pulseController.value * 0.02) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.gradient[0].withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _nextPage,
                borderRadius: BorderRadius.circular(20),
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Get Started' : 'Continue',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.only(left: isLastPage ? 4 : 0),
                      child: Icon(
                        isLastPage
                            ? LucideIcons.arrowRight
                            : LucideIcons.chevronRight,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardingItem {
  final IconData? icon;
  final bool isLogo;
  final String title;
  final String description;
  final List<Color> gradient;
  final List<Color> bgGradient;

  OnboardingItem({
    this.icon,
    this.isLogo = false,
    required this.title,
    required this.description,
    required this.gradient,
    required this.bgGradient,
  });
}
