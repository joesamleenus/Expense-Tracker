import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../services/user_prefs_service.dart';
import 'entry_screen.dart';
import 'recurring_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _storage = StorageService();
  final _sync = SyncService();
  final _userPrefs = UserPrefsService();
  int _pendingCount = 0;
  String? _lastError;
  Timer? _retryTimer;
  bool _retrying = false;
  bool _loggedToday = true;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadName();
    _retryPending();
    _checkLoggedToday();
    _retryTimer = Timer.periodic(const Duration(seconds: 8), (_) => _retryPending());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadName() async {
    final name = await _userPrefs.getName();
    if (mounted) setState(() => _name = name ?? '');
  }

  Future<void> _checkLoggedToday() async {
    final logged = await _storage.hasLoggedToday();
    if (mounted) setState(() => _loggedToday = logged);
  }

  Future<void> _retryPending() async {
    if (_retrying) return;
    _retrying = true;
    try {
      final pending = await _storage.getPending();
      if (!mounted) return;
      setState(() {
        _pendingCount = pending.length;
        _lastError = null;
      });
      for (final expense in pending) {
        final ok = await _sync.send(expense);
        if (ok) {
          await _storage.removePending(expense);
          if (mounted) setState(() => _pendingCount--);
        } else {
          if (mounted) setState(() => _lastError = SyncService.lastError);
          break;
        }
      }
    } finally {
      _retrying = false;
    }
  }

  void _openEntry(CategoryInfo category) {
    HapticFeedback.lightImpact();
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, animation, __) => EntryScreen(category: category),
            transitionsBuilder: (_, animation, __, child) {
              final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
                child: FadeTransition(opacity: curved, child: child),
              );
            },
          ),
        )
        .then((_) {
      _retryPending();
      _checkLoggedToday();
    });
  }

  void _openRecurring() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecurringScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final greetingName = _name.isNotEmpty ? _name : '';
    final headline = greetingName.isNotEmpty ? 'Hey $greetingName, I\'m listening...' : 'Hey there, I\'m listening...';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1E6), Color(0xFFFBF8F5)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(headline, style: Theme.of(context).textTheme.headlineMedium)),
                    IconButton(
                      icon: const Icon(Icons.repeat_rounded, color: AppTheme.accent),
                      onPressed: _openRecurring,
                      tooltip: 'Recurring expenses',
                    ),
                  ],
                ),
                if (!_loggedToday)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_twilight_rounded, size: 15, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Expanded(child: Text(greetingName.isNotEmpty ? "Don't forget to log today, $greetingName" : "Haven't logged anything today yet", style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                if (_pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 15, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text('$_pendingCount waiting to sync', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                  ),
                if (_lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('Sync error: $_lastError', style: const TextStyle(color: Colors.red, fontSize: 10)),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const crossAxisCount = 3;
                      const spacing = 14.0;
                      final rows = (kCategories.length / crossAxisCount).ceil();
                      final tileWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
                      final tileHeight = (constraints.maxHeight - spacing * (rows - 1)) / rows;
                      final aspectRatio = tileWidth / tileHeight;
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kCategories.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: aspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final category = kCategories[index];
                          return _AnimatedCategoryCard(
                            category: category,
                            delay: index * 55,
                            onTap: () => _openEntry(category),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Crafted by Joe Sam Leenus',
                    style: TextStyle(fontSize: 11, color: AppTheme.dark.withOpacity(0.35), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCategoryCard extends StatefulWidget {
  final CategoryInfo category;
  final int delay;
  final VoidCallback onTap;

  const _AnimatedCategoryCard({required this.category, required this.delay, required this.onTap});

  @override
  State<_AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<_AnimatedCategoryCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                color: widget.category.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.category.color.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(color: widget.category.color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  double base = box.maxHeight;
                  if (base < 80) base = 80;
                  if (base > 260) base = 260;
                  double circlePad = base * 0.11;
                  if (circlePad < 10) circlePad = 10;
                  if (circlePad > 18) circlePad = 18;
                  double iconSize = base * 0.18;
                  if (iconSize < 20) iconSize = 20;
                  if (iconSize > 32) iconSize = 32;
                  double fontSize = base * 0.085;
                  if (fontSize < 12) fontSize = 12;
                  if (fontSize > 16) fontSize = 16;
                  double gap = base * 0.07;
                  if (gap < 8) gap = 8;
                  if (gap > 14) gap = 14;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(circlePad),
                          decoration: BoxDecoration(
                            color: widget.category.color,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: widget.category.color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Icon(widget.category.icon, color: Colors.white, size: iconSize),
                        ),
                        SizedBox(height: gap),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            widget.category.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: fontSize, color: widget.category.color.withOpacity(0.95)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
