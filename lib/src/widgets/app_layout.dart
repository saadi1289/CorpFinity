import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final Widget? bottomBar;
  
  const AppLayout({
    super.key,
    required this.child,
    this.bottomBar,
  });
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLargeScreen = size.width > 600;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 420 : double.infinity,
            maxHeight: isLargeScreen ? size.height * 0.88 : double.infinity,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: isLargeScreen ? BorderRadius.circular(AppTheme.radius3Xl) : null,
            boxShadow: isLargeScreen
                ? [
                    BoxShadow(
                      color: AppColors.dark.withValues(alpha: 0.08),
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Organic background shapes
              const Positioned(
                top: -80,
                right: -60,
                child: RepaintBoundary(
                  child: _OrganicBlob(
                    color: AppColors.primary,
                    size: 280,
                    rotation: 0.2,
                  ),
                ),
              ),
              Positioned(
                bottom: size.height * 0.15,
                left: -100,
                child: const RepaintBoundary(
                  child: _OrganicBlob(
                    color: AppColors.secondary,
                    size: 240,
                    rotation: 0.8,
                  ),
                ),
              ),
              const Positioned(
                top: 200,
                left: -40,
                child: RepaintBoundary(
                  child: _OrganicBlob(
                    color: AppColors.accent,
                    size: 120,
                    rotation: 1.5,
                  ),
                ),
              ),
              
              // Subtle grain texture overlay
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _GrainPainter(),
                  ),
                ),
              ),
              
              // Main content
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: isLargeScreen
                            ? const BorderRadius.vertical(top: Radius.circular(AppTheme.radius3Xl))
                            : BorderRadius.zero,
                        child: child,
                      ),
                    ),
                    if (bottomBar != null) bottomBar!,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Organic blob shape with soft gradient
class _OrganicBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double rotation;
  
  const _OrganicBlob({
    required this.color,
    required this.size,
    this.rotation = 0,
  });
  
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size(size, size),
        painter: _BlobPainter(color: color),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;
  
  _BlobPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.06),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final path = Path();
    final w = size.width;
    final h = size.height;
    
    // Organic blob shape using bezier curves
    path.moveTo(w * 0.5, h * 0.0);
    path.cubicTo(w * 0.8, h * 0.0, w * 1.0, h * 0.2, w * 1.0, h * 0.45);
    path.cubicTo(w * 1.0, h * 0.7, w * 0.85, h * 0.95, w * 0.55, h * 1.0);
    path.cubicTo(w * 0.25, h * 1.05, w * 0.0, h * 0.8, w * 0.0, h * 0.5);
    path.cubicTo(w * 0.0, h * 0.2, w * 0.2, h * 0.0, w * 0.5, h * 0.0);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle grain texture for organic feel
class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent pattern
    final paint = Paint()
      ..color = AppColors.dark.withValues(alpha: 0.015)
      ..strokeWidth = 1;
    
    // Sparse grain dots
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
