import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shimmer animation for skeleton loading states
class SkeletonLoader extends StatefulWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                AppColors.gray200,
                AppColors.gray100,
                AppColors.gray200,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Basic skeleton box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, borderRadius: 4);
  }
}

/// Skeleton circle (for avatars)
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.gray200,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Home page skeleton
class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonLoader(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 100, height: 12),
                    SizedBox(height: 8),
                    SkeletonText(width: 140, height: 24),
                  ],
                ),
                SkeletonBox(width: 44, height: 44, borderRadius: 12),
              ],
            ),
            SizedBox(height: 24),

            // Hero card skeleton
            SkeletonBox(height: 192, borderRadius: 24),
            SizedBox(height: 24),

            // Mood tracker skeleton
            SkeletonBox(height: 140, borderRadius: 20),
            SizedBox(height: 24),

            // Hydration skeleton
            SkeletonBox(height: 95, borderRadius: 20),
            SizedBox(height: 24),

            // Quick challenges skeleton
            SkeletonText(width: 120, height: 18),
            SizedBox(height: 16),
            SizedBox(
              height: 144,
              child: Row(
                children: [
                  Expanded(child: SkeletonBox(height: 144, borderRadius: 20)),
                  SizedBox(width: 16),
                  Expanded(child: SkeletonBox(height: 144, borderRadius: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Insights page skeleton
class InsightsPageSkeleton extends StatelessWidget {
  const InsightsPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonLoader(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonText(width: 160, height: 24),
            SizedBox(height: 8),
            SkeletonText(width: 180, height: 14),
            SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 140, borderRadius: 20)),
                SizedBox(width: 16),
                Expanded(child: SkeletonBox(height: 140, borderRadius: 20)),
              ],
            ),
            SizedBox(height: 24),

            // Calendar skeleton
            SkeletonBox(height: 320, borderRadius: 24),
            SizedBox(height: 24),

            // Weekly chart skeleton
            SkeletonBox(height: 180, borderRadius: 24),
          ],
        ),
      ),
    );
  }
}

/// Profile page skeleton
class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonText(width: 80, height: 24),
            const SizedBox(height: 24),

            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  SkeletonCircle(size: 88),
                  SizedBox(height: 16),
                  SkeletonText(width: 140, height: 20),
                  SizedBox(height: 8),
                  SkeletonText(width: 180, height: 14),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats row
            const Row(
              children: [
                Expanded(child: SkeletonBox(height: 90, borderRadius: 16)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 90, borderRadius: 16)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 90, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 24),

            // Action tiles
            const SkeletonBox(height: 72, borderRadius: 16),
            const SizedBox(height: 10),
            const SkeletonBox(height: 72, borderRadius: 16),
            const SizedBox(height: 10),
            const SkeletonBox(height: 72, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

/// Challenges page skeleton
class ChallengesPageSkeleton extends StatelessWidget {
  const ChallengesPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonLoader(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonText(width: 140, height: 24),
            SizedBox(height: 8),
            SkeletonText(width: 180, height: 14),
            SizedBox(height: 24),

            // Tab switcher
            SkeletonBox(height: 48, borderRadius: 12),
            SizedBox(height: 24),

            // Progress summary
            SkeletonBox(height: 120, borderRadius: 20),
            SizedBox(height: 20),

            // Goal cards
            SkeletonBox(height: 100, borderRadius: 16),
            SizedBox(height: 12),
            SkeletonBox(height: 100, borderRadius: 16),
            SizedBox(height: 12),
            SkeletonBox(height: 100, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

/// List item skeleton
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 48, height: 48, borderRadius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 140, height: 16),
                SizedBox(height: 8),
                SkeletonText(width: 100, height: 12),
              ],
            ),
          ),
          SkeletonBox(width: 24, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}
