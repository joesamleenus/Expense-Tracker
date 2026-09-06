import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/recurring_template.dart';
import '../models/expense.dart';
import '../services/recurring_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../services/data_service.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final _recurringService = RecurringService();
  final _storage = StorageService();
  final _sync = SyncService();
  final _dataService = DataService();
  List<RecurringTemplate> _templates = [];
  bool _loading = true;

  static const _monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];

  String get _currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String get _currentMonthName => _monthNames[DateTime.now().month - 1];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _recurringService.getAll();
    if (!mounted) return;
    setState(() {
      _templates = list;
      _loading = false;
    });
  }

  Color _colorForCategory(String name) {
    for (final c in kCategories) {
      if (c.name == name) return c.color;
    }
    return const Color(0xFF78909C);
  }

  IconData _iconForCategory(String name) {
    for (final c in kCategories) {
      if (c.name == name) return c.icon;
    }
    return Icons.more_horiz_rounded;
  }

  Future<void> _openAdd() async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = kCategories.first.name;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add recurring expense', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: kCategories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                    onChanged: (v) => setModalState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes (e.g. Spotify Premium)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0) return;
                        final template = RecurringTemplate(
                          id: DateTime.now().toIso8601String(),
                          category: selectedCategory,
                          amount: amount,
                          notes: notesController.text.trim(),
                        );
                        await _recurringService.add(template);
                        _dataService.addRecurring(id: template.id, category: template.category, amount: template.amount, notes: template.notes);
                        if (mounted) Navigator.of(sheetContext).pop();
                        await _load();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(RecurringTemplate template) async {
    final rootContext = context;
    final confirmed = await showDialog<bool>(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this recurring expense?'),
        content: Text('${template.category} · ₹${template.amount.toStringAsFixed(0)}${template.notes.isNotEmpty ? ' · ${template.notes}' : ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _recurringService.remove(template.id);
      _dataService.deleteRecurring(template.id);
      await _load();
    }
  }

  Future<void> _logNow(RecurringTemplate template) async {
    final rootContext = context;
    final expense = Expense(
      category: template.category,
      amount: template.amount,
      notes: template.notes,
      createdAt: DateTime.now(),
    );
    await _storage.addPending(expense);
    _sync.send(expense).then((ok) async {
      if (ok) await _storage.removePending(expense);
    });
    await _recurringService.markLogged(template.id, _currentMonthKey);
    _dataService.markRecurringLogged(id: template.id, monthKey: _currentMonthKey);
    if (mounted) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text('Logged for $_currentMonthName'), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.warmBackground,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Recurring Expenses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _templates.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.repeat_rounded, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('No recurring expenses yet.', style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text('Tap + to add something like a subscription.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                    itemCount: _templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final t = _templates[index];
                      final color = _colorForCategory(t.category);
                      final loggedThisMonth = t.lastLoggedMonth == _currentMonthKey;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  child: Icon(_iconForCategory(t.category), color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.notes.isNotEmpty ? t.notes : t.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      Text(t.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text('₹${t.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (loggedThisMonth)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade400),
                                    const SizedBox(width: 6),
                                    Text('Logged for $_currentMonthName', style: TextStyle(color: Colors.green.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _confirmDelete(t),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                    label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade100), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _logNow(t),
                                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                    label: Text(loggedThisMonth ? 'Log again' : 'Update', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
