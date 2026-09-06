import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/user_prefs_service.dart';
import 'name_onboarding_screen.dart';
import 'main_tab_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _userPrefs = UserPrefsService();

  @override
  void initState() {
    super.initState();
    _proceed();
  }

  Future<void> _proceed() async {
    final name = await _userPrefs.getName();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => (name == null) ? const NameOnboardingScreen() : const MainTabScaffold(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset('assets/logo.png', width: 120, height: 120),
            ),
            const SizedBox(height: 20),
            const Text('Zaldora', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Text('Crafted by Joe Sam Leenus', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
