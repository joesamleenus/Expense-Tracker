import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import 'entry_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _storage = StorageService();
  final _sync = SyncService();
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _retryPending();
  }

  // Whenever the app opens, quietly try to send anything saved locally
  // from a time when there was no internet.
  Future<void> _retryPending() async {
    final pending = await _storage.getPending();
    if (!mounted) return;
    setState(() => _pendingCount = pending.length);
    for (final expense in pending) {
      final ok = await _sync.send(expense);
      if (ok) {
        await _storage.removePending(expense);
        if (mounted) setState(() => _pendingCount--);
      }
    }
  }

  void _openEntry(CategoryInfo category) {
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
        .then((_) => _retryPending());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What did you spend on?', style: Theme.of(context).textTheme.headlineMedium),
              if (_pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text('$_pendingCount waiting to sync', style: const TextStyle(color: Colors.orange, fontSize: 13)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: kCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final category = kCategories[index];
                    return _AnimatedCategoryCard(
                      category: category,
                      delay: index * 60,
                      onTap: () => _openEntry(category),
                    );
                  },
                ),
              ),
            ],
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
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
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              decoration: BoxDecoration(
                color: widget.category.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.category.color.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: widget.category.color, shape: BoxShape.circle),
                    child: Icon(widget.category.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.category.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, color: widget.category.color.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
