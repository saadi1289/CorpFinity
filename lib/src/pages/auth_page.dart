import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_button.dart';
import 'forgot_password_page.dart';

class AuthPage extends StatefulWidget {
  final Function(User) onLogin;
  
  const AuthPage({super.key, required this.onLogin});
  
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _rotationController;
  
  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final user = await _authService.login(
        _emailController.text,
        _isSignUp ? _nameController.text : null,
      );
      widget.onLogin(user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  
  void _toggleSignUp() {
    setState(() => _isSignUp = !_isSignUp);
    _rotationController.forward(from: 0);
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.clock, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Text('$feature coming soon!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.gray800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative background elements - optimized without BackdropFilter
          Positioned(
            top: -40,
            left: -40,
            child: RepaintBoundary(
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.08),
                      AppColors.secondary.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: RepaintBoundary(
              child: Container(
                width: 288,
                height: 288,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxHeight < 700;
                  final isNarrow = constraints.maxWidth < 360;
                  final horizontalPadding = isNarrow ? 20.0 : 32.0;
                  final logoSize = isSmallScreen ? 80.0 : 100.0;
                  
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isSmallScreen ? 16 : 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          RotationTransition(
                            turns: Tween<double>(begin: 0, end: 0.05).animate(_rotationController),
                            child: Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(logoSize * 0.32),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(logoSize * 0.16),
                              child: SvgPicture.asset(
                                'assets/logo/corpfinity_logo.svg',
                                width: logoSize * 0.68,
                                height: logoSize * 0.68,
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 32),
                    
                    // Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(_isSignUp),
                        children: [
                          Text(
                            _isSignUp ? 'Create Account' : 'Welcome to CorpFinity',
                            style: AppTextStyles.h1.copyWith(color: AppColors.gray900),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignUp 
                                ? 'Start your wellness journey today.' 
                                : 'Let\'s get back to your flow.',
                            style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name field (only for signup)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: _isSignUp
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: const Icon(LucideIcons.user, color: AppColors.gray400),
                                        filled: true,
                                        fillColor: AppColors.gray50,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                          borderSide: const BorderSide(color: AppColors.gray200),
                                        ),
                                      ),
                                      validator: _isSignUp ? (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      } : null,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(LucideIcons.mail, color: AppColors.gray400),
                              filled: true,
                              fillColor: AppColors.gray50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                borderSide: const BorderSide(color: AppColors.gray200),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(LucideIcons.lock, color: AppColors.gray400),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                  color: AppColors.gray400,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                borderSide: const BorderSide(color: AppColors.gray200),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          
                          // Forgot password (only for login)
                          if (!_isSignUp) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Submit button
                          CustomButton(
                            text: _loading 
                                ? 'Processing...' 
                                : (_isSignUp ? 'Get Started' : 'Sign In'),
                            onPressed: _loading ? null : _handleSubmit,
                            fullWidth: true,
                            isLoading: _loading,
                            icon: _loading ? null : const Icon(LucideIcons.arrowRight, size: 18),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Social login divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.gray200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: AppTextStyles.tiny.copyWith(color: AppColors.gray400),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.gray200)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Social login buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showComingSoon('Google Sign-In'),
                            icon: const _GoogleIcon(),
                            label: Text('Google', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray700)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.gray200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showComingSoon('Facebook Sign-In'),
                            icon: const _FacebookIcon(),
                            label: Text('Facebook', style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray700)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.gray200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                          // Toggle signup/login
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _isSignUp ? 'Already have an account?' : 'Don\'t have an account?',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
                              ),
                              TextButton(
                                onPressed: _toggleSignUp,
                                child: Text(
                                  _isSignUp ? 'Sign In' : 'Sign Up',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Google Icon using official colors
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Google "G" icon paths
    final Path bluePath = Path()
      ..moveTo(w * 0.95, h * 0.5)
      ..cubicTo(w * 0.95, h * 0.44, w * 0.94, h * 0.39, w * 0.93, h * 0.34)
      ..lineTo(w * 0.5, h * 0.34)
      ..lineTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.75, h * 0.52)
      ..cubicTo(w * 0.74, h * 0.58, w * 0.70, h * 0.64, w * 0.64, h * 0.68)
      ..lineTo(w * 0.64, h * 0.68)
      ..lineTo(w * 0.78, h * 0.79)
      ..cubicTo(w * 0.88, h * 0.70, w * 0.95, h * 0.61, w * 0.95, h * 0.5);
    
    final Path greenPath = Path()
      ..moveTo(w * 0.5, h * 0.95)
      ..cubicTo(w * 0.62, h * 0.95, w * 0.72, h * 0.91, w * 0.78, h * 0.79)
      ..lineTo(w * 0.64, h * 0.68)
      ..cubicTo(w * 0.60, h * 0.71, w * 0.55, h * 0.73, w * 0.5, h * 0.73)
      ..cubicTo(w * 0.38, h * 0.73, w * 0.28, h * 0.65, w * 0.24, h * 0.54)
      ..lineTo(w * 0.09, h * 0.65)
      ..cubicTo(w * 0.17, h * 0.82, w * 0.32, h * 0.95, w * 0.5, h * 0.95);
    
    final Path yellowPath = Path()
      ..moveTo(w * 0.24, h * 0.54)
      ..cubicTo(w * 0.23, h * 0.51, w * 0.22, h * 0.50, w * 0.22, h * 0.5)
      ..cubicTo(w * 0.22, h * 0.48, w * 0.23, h * 0.46, w * 0.24, h * 0.44)
      ..lineTo(w * 0.09, h * 0.33)
      ..cubicTo(w * 0.06, h * 0.38, w * 0.05, h * 0.44, w * 0.05, h * 0.5)
      ..cubicTo(w * 0.05, h * 0.56, w * 0.06, h * 0.62, w * 0.09, h * 0.65)
      ..lineTo(w * 0.24, h * 0.54);
    
    final Path redPath = Path()
      ..moveTo(w * 0.5, h * 0.27)
      ..cubicTo(w * 0.56, h * 0.27, w * 0.61, h * 0.29, w * 0.65, h * 0.33)
      ..lineTo(w * 0.78, h * 0.20)
      ..cubicTo(w * 0.71, h * 0.14, w * 0.61, h * 0.05, w * 0.5, h * 0.05)
      ..cubicTo(w * 0.32, h * 0.05, w * 0.17, h * 0.18, w * 0.09, h * 0.33)
      ..lineTo(w * 0.24, h * 0.44)
      ..cubicTo(w * 0.28, h * 0.33, w * 0.38, h * 0.27, w * 0.5, h * 0.27);
    
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Facebook Icon using official blue
class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(10, 10),
          painter: _FacebookIconPainter(),
        ),
      ),
    );
  }
}

class _FacebookIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width * 0.65, size.height * 0.0)
      ..lineTo(size.width * 0.65, size.height * 0.25)
      ..lineTo(size.width * 0.50, size.height * 0.25)
      ..lineTo(size.width * 0.50, size.height * 0.40)
      ..lineTo(size.width * 0.65, size.height * 0.40)
      ..lineTo(size.width * 0.65, size.height * 1.0)
      ..lineTo(size.width * 0.85, size.height * 1.0)
      ..lineTo(size.width * 0.85, size.height * 0.40)
      ..lineTo(size.width * 1.0, size.height * 0.40)
      ..lineTo(size.width * 1.0, size.height * 0.25)
      ..lineTo(size.width * 0.85, size.height * 0.25)
      ..lineTo(size.width * 0.85, size.height * 0.15)
      ..lineTo(size.width * 1.0, size.height * 0.15)
      ..lineTo(size.width * 1.0, size.height * 0.0)
      ..close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
