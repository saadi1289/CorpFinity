import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'dart:async';
import 'dart:math';
import '../models/user.dart';
import '../models/app_step.dart';
import '../models/energy_level.dart';
import '../models/goal_option.dart';
import '../models/challenge.dart';
import '../models/reminder.dart';
import '../services/challenge_service.dart';
import '../services/storage_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/circular_timer.dart';
import '../widgets/challenge_icon.dart';
import '../widgets/tutorial_overlay.dart';
import '../services/share_service.dart';
import 'reminders_page.dart';

class HomePage extends StatefulWidget {
  final User user;
  
  const HomePage({super.key, required this.user});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = StorageService();
  final _challengeService = ChallengeService();
  
  // State
  AppStep _currentStep = AppStep.welcome;
  GoalOption? _selectedGoal;

  int _streak = 0;
  String? _lastCompletedDate;
  
  // Water tracking
  int _waterIntake = 0;
  
  // Mood tracking
  String? _selectedMood;
  
  // Challenge
  GeneratedChallenge? _currentChallenge;

  // Reminders
  List<Reminder> _reminders = [];
  

  // Timer
  int _timeLeft = 0;
  int _totalTime = 0;
  bool _isTimerActive = false;
  bool _timerFinished = false;
  Timer? _timer;

  // Scroll controller for challenge view
  final _challengeScrollController = ScrollController();
  

  
  // Daily quote
  late ({String text, String author}) _dailyQuote;
  late String _timeOfDay;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _challengeScrollController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeData() async {
    // Set time of day
    final hour = DateTime.now().hour;
    _timeOfDay = hour < 12 ? 'Good Morning' : (hour < 18 ? 'Good Afternoon' : 'Good Evening');
    
    // Random quote
    _dailyQuote = AppConstants.quotes[Random().nextInt(AppConstants.quotes.length)];
    
    // Load water intake
    final waterResult = await _storage.getWaterIntake();
    final water = waterResult.dataOrNull ?? (count: 0, date: '');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (water.date == today) {
      setState(() => _waterIntake = water.count);
    } else {
      await _storage.saveWaterIntake(0, today);
    }
    
    // Load state
    final stateResult = await _storage.getState();
    final state = stateResult.dataOrNull;
    if (state != null) {
      setState(() {
        _streak = state['streak'] ?? 0;
        _lastCompletedDate = state['lastCompletedDate'];
      });
    }
    
    // Load reminders
    final remindersResult = await _storage.getReminders();
    setState(() => _reminders = remindersResult.dataOrNull ?? []);
  }
  
  int _parseDuration(String duration) {
    final num = int.tryParse(duration.split(' ')[0]) ?? 60;
    if (duration.toLowerCase().contains('sec')) return num;
    return num * 60;
  }
  

  
  void _selectGoal(GoalOption goal) {
    setState(() {
      _selectedGoal = goal;
      _currentStep = AppStep.energySelection;
    });
  }
  
  Future<void> _selectEnergy(EnergyLevel energy) async {
    setState(() {
      _currentStep = AppStep.generating;
    });
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final challenge = _challengeService.getChallengeFromDb(_selectedGoal!.id, energy);
    _initializeChallenge(challenge);
  }
  
  void _initializeChallenge(GeneratedChallenge challenge) {
    final seconds = _parseDuration(challenge.duration);
    // Reset scroll position to top
    if (_challengeScrollController.hasClients) {
      _challengeScrollController.jumpTo(0);
    }
    setState(() {
      _currentChallenge = challenge;
      _totalTime = seconds;
      _timeLeft = seconds;
      _isTimerActive = false;
      _timerFinished = false;
      _currentStep = AppStep.challengeView;
    });
  }
  
  void _toggleTimer() {
    setState(() => _isTimerActive = !_isTimerActive);
    
    if (_isTimerActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          _timer?.cancel();
          setState(() {
            _isTimerActive = false;
            _timerFinished = true;
          });
        }
      });
    } else {
      _timer?.cancel();
    }
  }
  
  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerActive = false;
      _timerFinished = false;
      _timeLeft = _totalTime;
    });
  }
  
  Future<void> _addWater() async {
    if (_waterIntake < 8) {
      final newCount = _waterIntake + 1;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await _storage.saveWaterIntake(newCount, today);
      setState(() => _waterIntake = newCount);
    }
  }
  
  Future<void> _openRemindersPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RemindersPage()),
    );
    // Reload reminders when returning
    final remindersResult = await _storage.getReminders();
    setState(() => _reminders = remindersResult.dataOrNull ?? []);
  }
  
  Future<void> _completeChallenge() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final isNewDay = _lastCompletedDate != today;
    
    // Save to history
    if (_currentChallenge != null) {
      final historyItem = ChallengeHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        completedAt: DateTime.now().toIso8601String(),
        title: _currentChallenge!.title,
        description: _currentChallenge!.description,
        duration: _currentChallenge!.duration,
        emoji: _currentChallenge!.emoji,
        funFact: _currentChallenge!.funFact,
      );
      
      final historyResult = await _storage.getHistory();
      final history = historyResult.dataOrNull ?? [];
      history.insert(0, historyItem);
      await _storage.saveHistory(history);
    }
    
    // Update streak
    final newStreak = isNewDay ? _streak + 1 : _streak;
    await _storage.saveState({
      'streak': newStreak,
      'lastCompletedDate': today,
    });
    
    setState(() {
      _streak = newStreak;
      _lastCompletedDate = today;
      _currentStep = AppStep.completed;
    });
  }
  
  void _resetFlow() {
    setState(() {
      _currentStep = AppStep.welcome;
      _selectedGoal = null;

      _currentChallenge = null;
      _selectedMood = null;
      _isTimerActive = false;
      _timerFinished = false;
    });
    _timer?.cancel();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _buildCurrentStep(),
    );
  }
  
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case AppStep.welcome:
        return _buildDashboard();
      case AppStep.goalSelection:
        return _buildGoalSelection();
      case AppStep.energySelection:
        return _buildEnergySelection();
      case AppStep.generating:
        return _buildGenerating();
      case AppStep.challengeView:
        return _buildChallengeView();
      case AppStep.completed:
        return _buildCompleted();
    }
  }
  
  // Due to character limit, I'll create this in a second file or continue below
  // The following methods will build each screen
  
  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _initializeData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(AppTheme.spacing6).copyWith(bottom: 96),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeOfDay,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.name.split(' ')[0],
                    style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
                  ),
                ],
              ),
              // Bell icon for reminders
              GestureDetector(
                onTap: _openRemindersPage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        _reminders.where((r) => r.isEnabled).isNotEmpty
                            ? LucideIcons.bellRing
                            : LucideIcons.bell,
                        size: 20,
                        color: AppColors.gray700,
                      ),
                      if (_reminders.where((r) => r.isEnabled).isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing6),
          
          // Hero Card - Start Flow
          _HeroCard(
            key: TutorialTargets.heroCard,
            onTap: () => setState(() => _currentStep = AppStep.goalSelection),
            child: Container(
                height: 192,
                padding: const EdgeInsets.all(AppTheme.spacing6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radius2Xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Start Your Flow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personalized CorpFinity challenges',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            (icon: HeroiconsOutline.bolt, solid: HeroiconsSolid.bolt),
                            (icon: HeroiconsOutline.lightBulb, solid: HeroiconsSolid.lightBulb),
                            (icon: HeroiconsOutline.heart, solid: HeroiconsSolid.heart),
                          ].map((iconData) {
                            return _HeroCardIcon(
                              outlineIcon: iconData.icon,
                              solidIcon: iconData.solid,
                            );
                          }).toList(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Go',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: AppTheme.spacing6),
          
          // Mood Tracker
          _buildMoodTracker(),
          const SizedBox(height: AppTheme.spacing6),
          
          _buildHydrationTracker(),
          const SizedBox(height: AppTheme.spacing6),
          
          _buildRemindersCard(),
          const SizedBox(height: AppTheme.spacing6),
          
          _buildQuickChallenges(),
          const SizedBox(height: AppTheme.spacing6),

          _buildDailyWisdom(),
        ],
      ),
    ),
    );
  }

  Widget _buildMoodTracker() {
    final activeMood = AppConstants.moods.firstWhere(
      (m) => m.label == _selectedMood,
      orElse: () => AppConstants.moods[0],
    );
    
    return Container(
      key: TutorialTargets.moodTracker,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: AppConstants.moods.map((mood) {
              final isSelected = _selectedMood == mood.label;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood.label),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? mood.color : mood.bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mood.color.withValues(alpha: isSelected ? 1.0 : 0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getMoodIcon(mood.icon),
                        color: isSelected ? Colors.white : mood.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppTextStyles.tiny.copyWith(
                        color: mood.color,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      child: Text(mood.label),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (_selectedMood != null) ...[
            const SizedBox(height: 24),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: activeMood.bg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: activeMood.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _MoodTipIcon(color: activeMood.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.moodTips[_selectedMood]!.title,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.moodTips[_selectedMood]!.desc,
                            style: AppTextStyles.caption.copyWith(color: AppColors.gray600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  IconData _getMoodIcon(String iconName) {
    final iconMap = {
      'Sun': LucideIcons.sun,
      'Smile': LucideIcons.smile,
      'Meh': LucideIcons.meh,
      'Cloud': LucideIcons.cloud,
      'Frown': LucideIcons.frown,
    };
    return iconMap[iconName] ?? LucideIcons.circle;
  }
  
  // Continue with other builder methods in next message
  Widget _buildHydrationTracker() {
    return Container(
      key: TutorialTargets.hydration,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.droplets, size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Text(
                      'Hydration',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$_waterIntake / 8 glasses today',
                  style: AppTextStyles.caption.copyWith(color: AppColors.info.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _waterIntake / 8,
                    minHeight: 8,
                    backgroundColor: AppColors.info.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _addWater,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.plus,
                size: 24,
                color: _waterIntake >= 8 ? AppColors.gray400 : AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRemindersCard() {
    final activeReminders = _reminders.where((r) => r.isEnabled).toList();
    
    return GestureDetector(
      onTap: _openRemindersPage,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.bellRing, size: 18, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reminders',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (activeReminders.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${activeReminders.length} active',
                          style: AppTextStyles.tiny.copyWith(color: AppColors.primary),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.gray400),
                  ],
                ),
              ],
            ),
            if (activeReminders.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Set up reminders to stay on track',
                style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ...activeReminders.take(2).map((reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(reminder.type.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray700),
                      ),
                    ),
                    Text(
                      reminder.formattedTime,
                      style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
                    ),
                  ],
                ),
              )),
              if (activeReminders.length > 2)
                Text(
                  '+${activeReminders.length - 2} more',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickChallenges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Relief', style: AppTextStyles.h3.copyWith(color: AppColors.gray800)),
            Text('Fast Track', style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 144,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ChallengeService.quickChallenges.length,
            itemBuilder: (context, index) {
              final challenge = ChallengeService.quickChallenges[index];
              return _TappableCard(
                onTap: () => _initializeChallenge(challenge),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(color: AppColors.gray100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ChallengeIcon(emoji: challenge.emoji, size: 28),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.clock, size: 10, color: AppColors.gray500),
                                const SizedBox(width: 4),
                                Text(
                                  challenge.duration,
                                  style: AppTextStyles.tiny.copyWith(color: AppColors.gray500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge.description,
                            style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
      ],
    );
  }
  
  Widget _buildDailyWisdom() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dark, AppColors.darkMuted],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          Text(
            'DAILY WISDOM',
            style: AppTextStyles.tiny.copyWith(
              color: AppColors.accent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"${_dailyQuote.text}"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '— ${_dailyQuote.author}',
            style: AppTextStyles.caption.copyWith(color: AppColors.gray400),
          ),
        ],
      ),
    );
  }
  
  // Continue with other build methods...
  Widget _buildGoalSelection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => setState(() => _currentStep = AppStep.welcome),
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            label: const Text('Back'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gray500),
          ),
          const SizedBox(height: 24),
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.target, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Focus',
                      style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What would you like to improve today?',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Goal cards
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              itemCount: AppConstants.goalOptions.length,
              itemBuilder: (context, index) {
                final goal = AppConstants.goalOptions[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 350 + (index * 80)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 25 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AnimatedGoalCard(
                      goal: goal,
                      icon: _getGoalIcon(goal.icon),
                      onTap: () => _selectGoal(goal),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(String iconName) {
    final iconMap = {
      'Brain': LucideIcons.brain,
      'Zap': LucideIcons.zap,
      'Moon': LucideIcons.moon,
      'Activity': LucideIcons.activity,
      'Utensils': LucideIcons.utensils,
      'Heart': LucideIcons.heart,
    };
    return iconMap[iconName] ?? LucideIcons.circle;
  }
  
  Widget _buildEnergySelection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => setState(() => _currentStep = AppStep.goalSelection),
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            label: const Text('Back'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gray500),
          ),
          const SizedBox(height: 24),
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.warmGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.gauge, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How\'s Your Energy?',
                      style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We\'ll match the intensity to how you feel',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Energy cards
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: AppConstants.energyOptions.length,
              itemBuilder: (context, index) {
                final option = AppConstants.energyOptions[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 120)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AnimatedEnergyCard(
                      option: option,
                      icon: _getEnergyIcon(option.icon),
                      onTap: () => _selectEnergy(option.value),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEnergyIcon(String iconName) {
    final iconMap = {
      'Leaf': LucideIcons.leaf,
      'Flame': LucideIcons.flame,
      'Zap': LucideIcons.zap,
    };
    return iconMap[iconName] ?? LucideIcons.sparkles;
  }
  
  Widget _buildGenerating() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Consulting Database...',
            style: AppTextStyles.h2.copyWith(color: AppColors.gray800),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best ${_selectedGoal?.label} challenge for you.',
            style: AppTextStyles.body.copyWith(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  
  Widget _buildChallengeView() {
    if (_currentChallenge == null) {
      return const Center(child: Text('No challenge loaded'));
    }
    
    return SingleChildScrollView(
      controller: _challengeScrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(AppTheme.spacing6).copyWith(bottom: 96),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _currentStep = AppStep.energySelection;
                  _timer?.cancel();
                  _isTimerActive = false;
                }),
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                label: const Text('Back'),
                style: TextButton.styleFrom(foregroundColor: AppColors.gray500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.clock, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _currentChallenge!.duration,
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Challenge title
          Text(
            _currentChallenge!.title,
            style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Timer
          CircularTimer(
            timeLeft: _timeLeft,
            totalTime: _totalTime,
            isActive: _isTimerActive,
            size: 220,
          ),
          const SizedBox(height: 24),
          
          // Timer controls - always visible
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset button - always visible
              GestureDetector(
                onTap: _resetTimer,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.rotateCcw,
                    size: 22,
                    color: _timeLeft != _totalTime ? AppColors.gray700 : AppColors.gray300,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Play/Pause button
              GestureDetector(
                onTap: _toggleTimer,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isTimerActive ? LucideIcons.pause : LucideIcons.play,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Skip/Complete button
              GestureDetector(
                onTap: _completeChallenge,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.circleCheck,
                    size: 22,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Instructions card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.info,
                        size: 16,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Instructions',
                      style: AppTextStyles.h4.copyWith(color: AppColors.gray800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _currentChallenge!.description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.gray600,
                    height: 1.6,
                  ),
                ),
                if (_currentChallenge!.funFact != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ChallengeIcon(emoji: '💡', size: 24, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Did you know?',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentChallenge!.funFact!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Mark complete button
          if (_timerFinished || _timeLeft == 0) ...[
            CustomButton(
              text: 'Mark as Complete',
              onPressed: _completeChallenge,
              fullWidth: true,
              icon: const Icon(LucideIcons.circleCheck, size: 18, color: Colors.white),
            ),
          ] else ...[
            TextButton(
              onPressed: _completeChallenge,
              child: Text(
                'Skip timer & mark complete',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCompleted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.circleCheck, size: 64, color: AppColors.success),
            ),
            const SizedBox(height: 32),
            Text('Well Done!', style: AppTextStyles.display.copyWith(color: AppColors.gray900)),
            const SizedBox(height: 8),
            Text(
              'You\'ve taken a moment for yourself.',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.gray500),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.warning.withValues(alpha: 0.1), AppColors.warning.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'CURRENT STREAK',
                    style: AppTextStyles.tiny.copyWith(color: AppColors.warning),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_streak',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.warning),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'days in a row',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Share',
                    onPressed: () => ShareService.shareChallenge(
                      context: context,
                      title: _currentChallenge?.title ?? 'Wellness Challenge',
                      duration: _currentChallenge?.duration ?? '',
                      streak: _streak,
                    ),
                    variant: ButtonVariant.secondary,
                    icon: const Icon(LucideIcons.share2, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Done',
                    onPressed: _resetFlow,
                    icon: const Icon(LucideIcons.check, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// Smooth touch feedback hero card
class _HeroCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  
  const _HeroCard({
    super.key,
    required this.onTap,
    required this.child,
  });
  
  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _elevationAnimation.value),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}


// Reusable tappable card with smooth feedback
class _TappableCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  
  const _TappableCard({
    required this.onTap,
    required this.child,
  });
  
  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// Animated goal card with press feedback
class _AnimatedGoalCard extends StatefulWidget {
  final GoalOption goal;
  final IconData icon;
  final VoidCallback onTap;
  
  const _AnimatedGoalCard({
    required this.goal,
    required this.icon,
    required this.onTap,
  });
  
  @override
  State<_AnimatedGoalCard> createState() => _AnimatedGoalCardState();
}

class _AnimatedGoalCardState extends State<_AnimatedGoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: _isPressed ? widget.goal.color : AppColors.gray100,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? widget.goal.color.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isPressed ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isPressed
                      ? widget.goal.color
                      : widget.goal.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.goal.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: AnimatedScale(
                  scale: _isPressed ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    widget.icon,
                    size: 26,
                    color: _isPressed ? Colors.white : widget.goal.color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.goal.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isPressed
                      ? widget.goal.color
                      : widget.goal.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.arrowRight,
                  size: 18,
                  color: _isPressed ? Colors.white : widget.goal.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated energy card with press feedback
class _AnimatedEnergyCard extends StatefulWidget {
  final dynamic option;
  final IconData icon;
  final VoidCallback onTap;
  
  const _AnimatedEnergyCard({
    required this.option,
    required this.icon,
    required this.onTap,
  });
  
  @override
  State<_AnimatedEnergyCard> createState() => _AnimatedEnergyCardState();
}

class _AnimatedEnergyCardState extends State<_AnimatedEnergyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: Border.all(
              color: _isPressed ? widget.option.color : AppColors.gray100,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? widget.option.color.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isPressed ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container with gradient background
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isPressed
                      ? widget.option.color
                      : widget.option.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.option.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: AnimatedScale(
                  scale: _isPressed ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: _isPressed ? Colors.white : widget.option.color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.value.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.option.value.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isPressed
                      ? widget.option.color
                      : widget.option.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.arrowRight,
                  size: 18,
                  color: _isPressed ? Colors.white : widget.option.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated lightbulb icon for mood tips with hover effect
class _MoodTipIcon extends StatefulWidget {
  final Color color;

  const _MoodTipIcon({required this.color});

  @override
  State<_MoodTipIcon> createState() => _MoodTipIconState();
}

class _MoodTipIconState extends State<_MoodTipIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1.0 - _animation.value,
                child: Icon(
                  HeroiconsOutline.lightBulb,
                  size: 16,
                  color: widget.color,
                ),
              ),
              Opacity(
                opacity: _animation.value,
                child: Transform.scale(
                  scale: 0.9 + (0.1 * _animation.value),
                  child: Icon(
                    HeroiconsSolid.lightBulb,
                    size: 16,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Animated icon for the hero card with hover/tap effects
class _HeroCardIcon extends StatefulWidget {
  final IconData outlineIcon;
  final IconData solidIcon;

  const _HeroCardIcon({
    required this.outlineIcon,
    required this.solidIcon,
  });

  @override
  State<_HeroCardIcon> createState() => _HeroCardIconState();
}

class _HeroCardIconState extends State<_HeroCardIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverChange(bool isHovered) {
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHoverChange(true),
      onExit: (_) => _handleHoverChange(false),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1.0 - _animation.value,
                    child: Icon(
                      widget.outlineIcon,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  Opacity(
                    opacity: _animation.value,
                    child: Transform.scale(
                      scale: 0.9 + (0.1 * _animation.value),
                      child: Icon(
                        widget.solidIcon,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
