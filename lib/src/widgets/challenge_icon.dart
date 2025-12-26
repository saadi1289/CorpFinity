import 'package:flutter/material.dart';
import '../utils/challenge_icons.dart';

/// A widget that displays a challenge icon based on an emoji string.
/// Uses HeroIcons with animated outline → solid transitions on hover/tap/selection.
class ChallengeIcon extends StatefulWidget {
  final String emoji;
  final double size;
  final Color? color;
  final bool isActive;
  final VoidCallback? onTap;

  const ChallengeIcon({
    super.key,
    required this.emoji,
    this.size = 24,
    this.color,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<ChallengeIcon> createState() => _ChallengeIconState();
}

class _ChallengeIconState extends State<ChallengeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
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
  void didUpdateWidget(ChallengeIcon oldWidget) {
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
    final iconData = ChallengeIcons.getIconForEmoji(widget.emoji);
    final color = widget.color ?? iconData.defaultColor;

    final iconWidget = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outline icon (fades out)
            Opacity(
              opacity: 1.0 - _animation.value,
              child: Icon(
                iconData.outline,
                size: widget.size,
                color: color,
              ),
            ),
            // Solid icon (fades in with scale)
            Opacity(
              opacity: _animation.value,
              child: Transform.scale(
                scale: 0.9 + (0.1 * _animation.value),
                child: Icon(
                  iconData.solid,
                  size: widget.size,
                  color: color,
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
          child: iconWidget,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => _handleHoverChange(true),
      onExit: (_) => _handleHoverChange(false),
      child: iconWidget,
    );
  }
}

/// A simple static challenge icon without animation (for containers/backgrounds)
class ChallengeIconStatic extends StatelessWidget {
  final String emoji;
  final double size;
  final Color? color;
  final bool isSolid;

  const ChallengeIconStatic({
    super.key,
    required this.emoji,
    this.size = 24,
    this.color,
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = ChallengeIcons.getIconForEmoji(emoji);
    final iconColor = color ?? iconData.defaultColor;

    return Icon(
      isSolid ? iconData.solid : iconData.outline,
      size: size,
      color: iconColor,
    );
  }
}
