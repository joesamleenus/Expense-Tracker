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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final _userPrefs = UserPrefsService();
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _creditOpacity;
  late final Animation<double> _creditScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

    _logoOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.32).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.32), weight: 20),
    ]).animate(_controller);

    _logoScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.88), weight: 20),
    ]).animate(_controller);

    _creditOpacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
    ]).animate(_controller);

    _creditScale = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(0.85), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
    ]).animate(_controller);

    _controller.forward();
    _proceed();
  }

  Future<void> _proceed() async {
    final name = await _userPrefs.getName();
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => (name == null) ? const NameOnboardingScreen() : const MainTabScaffold(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset('assets/logo.png', width: 120, height: 120),
                        ),
                        const SizedBox(height: 20),
                        const Text('Zaldora', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Opacity(
                  opacity: _creditOpacity.value,
                  child: Transform.scale(
                    scale: _creditScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('CRAFTED BY', style: TextStyle(fontSize: 12, letterSpacing: 3, color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text(
                          'Joe Sam Leenus',
                          style: TextStyle(color: AppTheme.accent, fontSize: 24, fontStyle: FontStyle.italic, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
