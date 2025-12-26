import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareService {
  static Future<void> shareChallenge({
    required BuildContext context,
    required String title,
    required String duration,
    required int streak,
  }) async {
    final text = '''
🌟 Just completed a wellness challenge on CorpFinity!

💪 Challenge: $title
⏱️ Duration: $duration
🔥 Current Streak: $streak days

Join me on my wellness journey! #CorpFinity #Wellness #SelfCare
''';

    await _showShareSheet(context, text, 'Challenge Completed');
  }

  static Future<void> shareStreak({
    required BuildContext context,
    required int streak,
    required int totalChallenges,
  }) async {
    final text = '''
🔥 I'm on a $streak-day wellness streak with CorpFinity!

📊 Stats:
• $streak days in a row
• $totalChallenges challenges completed

Taking care of my wellbeing one day at a time! #CorpFinity #WellnessJourney
''';

    await _showShareSheet(context, text, 'Share Your Progress');
  }

  static Future<void> shareAchievement({
    required BuildContext context,
    required String title,
    required String emoji,
    required String description,
  }) async {
    final text = '''
$emoji Achievement Unlocked on CorpFinity!

🏆 $title
$description

Building healthy habits every day! #CorpFinity #Achievement #Wellness
''';

    await _showShareSheet(context, text, 'Share Achievement');
  }

  static Future<void> _showShareSheet(
    BuildContext context,
    String text,
    String title,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareSheet(text: text, title: title),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final String text;
  final String title;

  const _ShareSheet({required this.text, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ShareOption(
                  icon: Icons.copy,
                  label: 'Copy',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareOption(
                  icon: Icons.message,
                  label: 'Message',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Text copied! Paste in your messaging app.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareOption(
                  icon: Icons.more_horiz,
                  label: 'More',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Text copied! Share anywhere.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.grey[700]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
