import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _loading = false;
        _emailSent = true;
      });
    }
  }

  void _handleResend() {
    setState(() => _emailSent = false);
    _handleSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.gray700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessState() : _buildFormState(),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            LucideIcons.keyRound,
            size: 32,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Forgot Password?',
          style: AppTextStyles.h1.copyWith(color: AppColors.gray900),
        ),
        const SizedBox(height: 8),

        // Description
        Text(
          'No worries! Enter your email address and we\'ll send you a link to reset your password.',
          style: AppTextStyles.body.copyWith(color: AppColors.gray500),
        ),
        const SizedBox(height: 32),

        // Form
        Form(
          key: _formKey,
          child: Column(
            children: [
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
              const SizedBox(height: 24),

              CustomButton(
                text: _loading ? 'Sending...' : 'Send Reset Link',
                onPressed: _loading ? null : _handleSubmit,
                fullWidth: true,
                isLoading: _loading,
                icon: _loading
                    ? null
                    : const Icon(LucideIcons.send, size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Back to login
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text('Back to Sign In'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gray500),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 60),

        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.mailCheck,
            size: 48,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          'Check Your Email',
          style: AppTextStyles.h1.copyWith(color: AppColors.gray900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Description
        Text(
          'We\'ve sent a password reset link to',
          style: AppTextStyles.body.copyWith(color: AppColors.gray500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray800,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, size: 20, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The link will expire in 24 hours. Check your spam folder if you don\'t see it.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Resend button
        CustomButton(
          text: 'Open Email App',
          onPressed: () {
            // In a real app, you'd use url_launcher to open email app
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening email app...'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          fullWidth: true,
          icon: const Icon(LucideIcons.externalLink, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 16),

        // Didn't receive email
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive the email?',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
            ),
            TextButton(
              onPressed: _handleResend,
              child: Text(
                'Resend',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Back to login
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.arrowLeft, size: 16),
          label: const Text('Back to Sign In'),
          style: TextButton.styleFrom(foregroundColor: AppColors.gray500),
        ),
      ],
    );
  }
}
