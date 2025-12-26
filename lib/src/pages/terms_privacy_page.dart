import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

class TermsPrivacyPage extends StatefulWidget {
  const TermsPrivacyPage({super.key});

  @override
  State<TermsPrivacyPage> createState() => _TermsPrivacyPageState();
}

class _TermsPrivacyPageState extends State<TermsPrivacyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.gray700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Legal',
          style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray400,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.bodyMedium,
          tabs: const [
            Tab(text: 'Terms of Service'),
            Tab(text: 'Privacy Policy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsOfService(),
          _buildPrivacyPolicy(),
        ],
      ),
    );
  }

  Widget _buildTermsOfService() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLastUpdated('November 28, 2025'),
          const SizedBox(height: 24),
          _buildSection(
            'Welcome to CorpFinity',
            'By using CorpFinity, you agree to these Terms of Service. Please read them carefully before using our wellness application.',
          ),
          _buildSection(
            '1. Acceptance of Terms',
            'By accessing or using CorpFinity, you agree to be bound by these Terms. If you do not agree to these Terms, please do not use the app.',
          ),
          _buildSection(
            '2. Description of Service',
            'CorpFinity is a wellness application designed to help users improve their mental and physical well-being through guided challenges, reminders, and progress tracking.',
          ),
          _buildSection(
            '3. User Accounts',
            'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account.',
          ),
          _buildSection(
            '4. User Conduct',
            'You agree to use CorpFinity only for lawful purposes and in accordance with these Terms. You will not misuse the service or attempt to access it using unauthorized methods.',
          ),
          _buildSection(
            '5. Health Disclaimer',
            'CorpFinity provides general wellness information and is not a substitute for professional medical advice. Always consult with a healthcare provider before starting any new wellness routine.',
          ),
          _buildSection(
            '6. Intellectual Property',
            'All content, features, and functionality of CorpFinity are owned by us and are protected by international copyright, trademark, and other intellectual property laws.',
          ),
          _buildSection(
            '7. Termination',
            'We reserve the right to terminate or suspend your account at any time for any reason, including violation of these Terms.',
          ),
          _buildSection(
            '8. Changes to Terms',
            'We may update these Terms from time to time. We will notify you of any changes by posting the new Terms on this page.',
          ),
          _buildContactSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLastUpdated('November 28, 2025'),
          const SizedBox(height: 24),
          _buildSection(
            'Your Privacy Matters',
            'At CorpFinity, we are committed to protecting your privacy. This policy explains how we collect, use, and safeguard your information.',
          ),
          _buildSection(
            '1. Information We Collect',
            '• Account information (name, email)\n• Wellness activity data\n• App usage statistics\n• Device information for notifications',
          ),
          _buildSection(
            '2. How We Use Your Information',
            '• To provide and improve our services\n• To personalize your wellness experience\n• To send reminders and notifications\n• To analyze app performance',
          ),
          _buildSection(
            '3. Data Storage',
            'Your wellness data is stored locally on your device. We do not upload your personal wellness history to external servers without your explicit consent.',
          ),
          _buildSection(
            '4. Data Sharing',
            'We do not sell, trade, or rent your personal information to third parties. We may share anonymized, aggregated data for research purposes.',
          ),
          _buildSection(
            '5. Your Rights',
            '• Access your personal data\n• Request data correction\n• Delete your account and data\n• Opt-out of notifications\n• Export your data',
          ),
          _buildSection(
            '6. Security',
            'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
          ),
          _buildSection(
            '7. Children\'s Privacy',
            'CorpFinity is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
          ),
          _buildSection(
            '8. Changes to This Policy',
            'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page.',
          ),
          _buildContactSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.calendar, size: 14, color: AppColors.info),
          const SizedBox(width: 8),
          Text(
            'Last updated: $date',
            style: AppTextStyles.caption.copyWith(color: AppColors.info),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.gray600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.mail, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact Us',
                style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If you have any questions about these terms or our privacy practices, please contact us at:',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: 8),
          Text(
            'support@corpfinity.app',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
