import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/expense.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

class EntryScreen extends StatefulWidget {
  final CategoryInfo category;
  const EntryScreen({super.key, required this.category});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _storage = StorageService();
  final _sync = SyncService();
  late final AnimationController _successController;

  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  Future<void> _onUpdate() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() => _error = 'Amount is required');
      HapticFeedback.mediumImpact();
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      HapticFeedback.mediumImpact();
      return;
    }

    final expense = Expense(
      category: widget.category.name,
      amount: amount,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _storage.addPending(expense);
    await _storage.markLoggedToday();

    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() {
      _error = null;
      _saved = true;
    });
    _successController.forward();

    _sync.send(expense).then((synced) async {
      if (synced) {
        await _storage.removePending(expense);
      }
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.category.color;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        child: Icon(widget.category.icon, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(widget.category.name, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
                      hintText: '0.00',
                      border: InputBorder.none,
                      errorText: _error,
                    ),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saved ? null : _onUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        elevation: 4,
                        shadowColor: color.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _saved
                            ? const Icon(Icons.check_rounded, key: ValueKey('check'), color: Colors.white)
                            : const Text('Update',
                                key: ValueKey('label'),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_saved)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _successController,
                builder: (context, child) {
                  final burst = CurvedAnimation(parent: _successController, curve: Curves.easeOut).value;
                  return Opacity(
                    opacity: (1 - burst).clamp(0.0, 0.35),
                    child: Center(
                      child: Container(
                        width: 120 + burst * 400,
                        height: 120 + burst * 400,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
}
