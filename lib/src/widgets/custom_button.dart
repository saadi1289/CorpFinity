import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
}

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool fullWidth;
  final Widget? icon;
  final bool isLoading;
  
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.fullWidth = false,
    this.icon,
    this.isLoading = false,
  });
  
  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Color get _textColor {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return AppColors.gray800;
      case ButtonVariant.outline:
        return AppColors.primary;
      case ButtonVariant.ghost:
        return AppColors.gray600;
    }
  }
  
  BoxDecoration get _decoration {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPressed 
                ? [AppColors.primaryDark, AppColors.primary]
                : [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: _isPressed ? [] : [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        );
      case ButtonVariant.secondary:
        return BoxDecoration(
          color: _isPressed ? AppColors.gray100 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.gray200, width: 1.5),
          boxShadow: _isPressed ? [] : AppTheme.shadowSm,
        );
      case ButtonVariant.outline:
        return BoxDecoration(
          color: _isPressed 
              ? AppColors.primary.withValues(alpha: 0.08)
              : (_isHovered ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent),
          border: Border.all(
            color: _isHovered || _isPressed ? AppColors.primary : AppColors.gray300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        );
      case ButtonVariant.ghost:
        return BoxDecoration(
          color: _isPressed 
              ? AppColors.gray100 
              : (_isHovered ? AppColors.gray50 : Colors.transparent),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    
    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.isLoading ? '${widget.text}, loading' : widget.text,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: isDisabled ? null : (_) {
            setState(() => _isPressed = true);
            _controller.forward();
          },
          onTapUp: isDisabled ? null : (_) {
            setState(() => _isPressed = false);
            _controller.reverse();
            widget.onPressed!();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _controller.reverse();
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isDisabled ? 1.0 : _scaleAnimation.value,
                child: child,
              );
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isDisabled ? 0.5 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: widget.fullWidth ? double.infinity : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 15,
                ),
                decoration: _decoration,
                child: widget.isLoading
                    ? Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.variant == ButtonVariant.primary 
                                  ? Colors.white 
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            ExcludeSemantics(child: widget.icon!),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.text,
                            style: AppTextStyles.button.copyWith(
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
