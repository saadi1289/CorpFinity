import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/theme/app_theme.dart';
import 'src/models/user.dart';
import 'src/models/app_view.dart';
import 'src/services/auth_service.dart';
import 'src/services/notification_service.dart';
import 'src/widgets/app_layout.dart';
import 'src/widgets/bottom_navbar.dart';
import 'src/widgets/splash_screen.dart';
import 'src/widgets/tutorial_overlay.dart';
import 'src/pages/onboarding_page.dart';
import 'src/pages/auth_page.dart';
import 'src/pages/home_page.dart';
import 'src/pages/challenges_page.dart';
import 'src/pages/insights_page.dart';
import 'src/pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().initialize();
  
  // Optimize for high refresh rate displays and set system UI
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set system UI overlay style for a polished look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  
  // Disable debug prints in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  runApp(
    const ProviderScope(
      child: CorpFinityApp(),
    ),
  );
}

class CorpFinityApp extends StatelessWidget {
  const CorpFinityApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CorpFinity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _authService = AuthService();

  User? _user;
  AppView _currentView = AppView.home;
  bool _loading = true;
  bool _showSplash = true;
  bool _showOnboarding = false;
  bool _showTutorial = false;
  String _challengesInitialTab = 'goals';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
    final user = await _authService.getUser();
    setState(() {
      _user = user;
      _showOnboarding = !hasSeenOnboarding;
      _showTutorial = user != null && !hasSeenTutorial;
      _loading = false;
    });
  }

  void _onSplashComplete() {
    setState(() => _showSplash = false);
  }

  Future<void> _onOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    setState(() => _showOnboarding = false);
  }
  
  void _handleLogin(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
    setState(() {
      _user = user;
      _showTutorial = !hasSeenTutorial;
    });
  }
  
  void _handleUpdateUser(User user) {
    setState(() => _user = user);
  }
  
  Future<void> _handleLogout() async {
    await _authService.logout();
    setState(() {
      _user = null;
      _currentView = AppView.home;
    });
  }
  
  void _handleChangeView(AppView view) {
    setState(() {
      // Reset to goals tab when navigating to challenges via bottom nav
      if (view == AppView.challenges) {
        _challengesInitialTab = 'goals';
      }
      _currentView = view;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Show splash screen
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    // Loading state
    if (_loading) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Show onboarding for first-time users
    if (_showOnboarding) {
      return OnboardingPage(onComplete: _onOnboardingComplete);
    }

    // Not authenticated - show auth page
    if (_user == null) {
      return AuthPage(onLogin: _handleLogin);
    }
    
    // Authenticated - show app with bottom navigation
    Widget appContent = AppLayout(
      bottomBar: BottomNavbar(
        currentView: _currentView,
        onChangeView: _handleChangeView,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: _buildCurrentPage(),
      ),
    );

    // Show tutorial overlay for first-time users
    if (_showTutorial) {
      return TutorialOverlay(
        onComplete: _onTutorialComplete,
        child: appContent,
      );
    }

    return appContent;
  }

  Future<void> _onTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
    setState(() => _showTutorial = false);
  }
  
  Widget _buildCurrentPage() {
    switch (_currentView) {
      case AppView.home:
        return HomePage(key: const ValueKey('home'), user: _user!);
      case AppView.challenges:
        return ChallengesPage(key: ValueKey('challenges-$_challengesInitialTab'), initialTab: _challengesInitialTab);
      case AppView.insights:
        return const InsightsPage(key: ValueKey('insights'));
      case AppView.profile:
        return ProfilePage(
          key: const ValueKey('profile'),
          user: _user!,
          onLogout: _handleLogout,
          onUpdateUser: _handleUpdateUser,
          onNavigateToHistory: () {
            setState(() {
              _challengesInitialTab = 'history';
              _currentView = AppView.challenges;
            });
          },
        );
    }
  }
}
