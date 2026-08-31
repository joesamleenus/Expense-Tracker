import 'package:flutter/material.dart';
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

class _EntryScreenState extends State<EntryScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _storage = StorageService();
  final _sync = SyncService();

  bool _saving = false;
  bool _saved = false;
  String? _error;

  Future<void> _onUpdate() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() => _error = 'Amount is required');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final expense = Expense(
      category: widget.category.name,
      amount: amount,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    // Save locally first. This guarantees the entry is never lost,
    // whether or not there's internet right now.
    await _storage.addPending(expense);

    final synced = await _sync.send(expense);
    if (synced) {
      await _storage.removePending(expense);
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.category.color;
    return Scaffold(
      body: SafeArea(
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
                  onPressed: _saving || _saved ? null : _onUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _saved
                        ? const Icon(Icons.check_rounded, key: ValueKey('check'), color: Colors.white)
                        : _saving
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                              )
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
    );
  }
}
