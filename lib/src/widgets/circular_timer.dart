import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CircularTimer extends StatefulWidget {
  final int timeLeft;
  final int totalTime;
  final bool isActive;
  final double size;
  
  const CircularTimer({
    super.key,
    required this.timeLeft,
    required this.totalTime,
    required this.isActive,
    this.size = 280,
  });
  
  @override
  State<CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<CircularTimer> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(CircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final progress = widget.totalTime > 0 
        ? (widget.totalTime - widget.timeLeft) / widget.totalTime 
        : 0.0;
    
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isActive ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isActive)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15 * value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              CustomPaint(
                size: Size(widget.size - 20, widget.size - 20),
                painter: _CircularTimerPainter(
                  progress: progress,
                  isActive: widget.isActive,
                ),
              ),
              _buildTimeDisplay(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimeDisplay() {
    final mins = widget.timeLeft ~/ 60;
    final secs = widget.timeLeft % 60;
    final isReady = widget.timeLeft == widget.totalTime;
    final scaleFactor = widget.size / 280;
    final fontSize = 56 * scaleFactor;
    final statusFontSize = 13 * scaleFactor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _AnimatedDigit(value: mins ~/ 10, fontSize: fontSize),
            _AnimatedDigit(value: mins % 10, fontSize: fontSize),
            Text(
              ':',
              style: GoogleFonts.spaceGrotesk(
                fontSize: fontSize,
                fontWeight: FontWeight.w300,
                color: AppColors.gray800,
                height: 1,
              ),
            ),
            _AnimatedDigit(value: secs ~/ 10, fontSize: fontSize),
            _AnimatedDigit(value: secs % 10, fontSize: fontSize),
          ],
        ),
        SizedBox(height: 12 * scaleFactor),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(isReady ? 'ready' : (widget.isActive ? 'active' : 'paused')),
            padding: EdgeInsets.symmetric(horizontal: 14 * scaleFactor, vertical: 6 * scaleFactor),
            decoration: BoxDecoration(
              color: widget.isActive 
                  ? AppColors.secondary.withValues(alpha: 0.12)
                  : AppColors.gray100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isActive) ...[
                  const _PulsingDot(),
                  SizedBox(width: 6 * scaleFactor),
                ],
                Text(
                  isReady ? 'Ready' : (widget.isActive ? 'In progress' : 'Paused'),
                  style: GoogleFonts.dmSans(
                    fontSize: statusFontSize.clamp(11.0, 14.0),
                    fontWeight: FontWeight.w500,
                    color: widget.isActive ? AppColors.secondary : AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedDigit extends StatelessWidget {
  final int value;
  final double fontSize;
  const _AnimatedDigit({required this.value, this.fontSize = 56});
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: Text(
        '$value',
        key: ValueKey(value),
        style: GoogleFonts.spaceGrotesk(
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: AppColors.gray800,
          height: 1,
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.4 + (_controller.value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  
  _CircularTimerPainter({required this.progress, required this.isActive});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    final bgPaint = Paint()
      ..color = AppColors.gray200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = const SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [AppColors.primary, AppColors.accent, AppColors.secondary, AppColors.primary],
          stops: [0.0, 0.33, 0.66, 1.0],
          transform: GradientRotation(-pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
      
      if (isActive && progress > 0.01) {
        final endAngle = -pi / 2 + 2 * pi * progress;
        final endPoint = Offset(center.dx + radius * cos(endAngle), center.dy + radius * sin(endAngle));
        canvas.drawCircle(endPoint, 10, Paint()..color = AppColors.primary.withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(endPoint, 6, Paint()..color = const Color(0xFFFFFFFF));
      }
    }
    
    canvas.drawCircle(center, radius - 24, Paint()..color = AppColors.gray100..style = PaintingStyle.stroke..strokeWidth = 1);
  }
  
  @override
  bool shouldRepaint(_CircularTimerPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.isActive != isActive;
}
