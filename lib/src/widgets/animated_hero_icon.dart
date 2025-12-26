import 'package:flutter/material.dart';

/// A reusable widget that displays HeroIcons with animated outline → solid transitions.
/// 
/// By default shows the outline variant, and on hover/tap/selection shows the solid variant.
/// Includes smooth animation between states.
class AnimatedHeroIcon extends StatefulWidget {
  final IconData outlineIcon;
  final IconData solidIcon;
  final double size;
  final Color color;
  final bool isActive;
  final Duration animationDuration;
  final VoidCallback? onTap;

  const AnimatedHeroIcon({
    super.key,
    required this.outlineIcon,
    required this.solidIcon,
    this.size = 24,
    required this.color,
    this.isActive = false,
    this.animationDuration = const Duration(milliseconds: 200),
    this.onTap,
  });

  @override
  State<AnimatedHeroIcon> createState() => _AnimatedHeroIconState();
}

class _AnimatedHeroIconState extends State<AnimatedHeroIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    
    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedHeroIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverChange(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (!widget.isActive) {
      if (isHovered) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _handleTapDown() {
    _controller.forward();
  }

  void _handleTapUp() {
    if (!widget.isActive && !_isHovered) {
      _controller.reverse();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (!widget.isActive && !_isHovered) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outline icon (fades out)
            Opacity(
              opacity: 1.0 - _animation.value,
              child: Icon(
                widget.outlineIcon,
                size: widget.size,
                color: widget.color,
              ),
            ),
            // Solid icon (fades in)
            Opacity(
              opacity: _animation.value,
              child: Transform.scale(
                scale: 0.9 + (0.1 * _animation.value),
                child: Icon(
                  widget.solidIcon,
                  size: widget.size,
                  color: widget.color,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.onTap != null) {
      return MouseRegion(
        onEnter: (_) => _handleHoverChange(true),
        onExit: (_) => _handleHoverChange(false),
        child: GestureDetector(
          onTapDown: (_) => _handleTapDown(),
          onTapUp: (_) => _handleTapUp(),
          onTapCancel: _handleTapCancel,
          child: child,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => _handleHoverChange(true),
      onExit: (_) => _handleHoverChange(false),
      child: child,
    );
  }
}

/// Static icon display widget for non-interactive contexts
class HeroIconDisplay extends StatelessWidget {
  final IconData outlineIcon;
  final IconData solidIcon;
  final double size;
  final Color color;
  final bool isSolid;

  const HeroIconDisplay({
    super.key,
    required this.outlineIcon,
    required this.solidIcon,
    this.size = 24,
    required this.color,
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      isSolid ? solidIcon : outlineIcon,
      size: size,
      color: color,
    );
  }
}
