import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _retryPending();
  }

  Future<void> _retryPending() async {
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
        .then((_) => _retryPending());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEDEBFF), Color(0xFFF7F7FB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What did you spend on?', style: Theme.of(context).textTheme.headlineMedium),
                if (_pendingCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
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
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Sync error: $_lastError', style: const TextStyle(color: Colors.red, fontSize: 10)),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const crossAxisCount = 3;
                      const spacing = 14.0;
                      final rows = (kCategories.length / crossAxisCount).ceil();
                      final tileWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
                      final tileHeight = (constraints.maxHeight - spacing * (rows - 1)) / rows;
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kCategories.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: tileWidth / tileHeight,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: widget.category.color.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: widget.category.color, shape: BoxShape.circle),
                    child: Icon(widget.category.icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: widget.category.color.withOpacity(0.95)),
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
