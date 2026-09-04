import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dashboard_data.dart';
import '../services/data_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _dataService = DataService();
  final _searchController = TextEditingController();
  DashboardData? _data;
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCached();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCached() async {
    try {
      final cached = await _dataService.loadCached();
      if (cached != null && mounted) setState(() => _data = cached);
    } catch (_) {}
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _dataService.fetch();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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

  List<LogEntry> get _filtered {
    final list = _data?.log ?? [];
    if (_query.isEmpty) return list;
    return list.where((e) {
      return e.category.toLowerCase().contains(_query) ||
          e.notes.toLowerCase().contains(_query) ||
          e.amount.toString().contains(_query) ||
          e.display.toLowerCase().contains(_query);
    }).toList();
  }

  Future<void> _openEdit(LogEntry entry) async {
    final amountController = TextEditingController(text: entry.amount.toStringAsFixed(entry.amount.truncateToDouble() == entry.amount ? 0 : 2));
    final notesController = TextEditingController(text: entry.notes);
    String selectedCategory = entry.category;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit expense', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
                    decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final amount = double.tryParse(amountController.text.trim());
                              if (amount == null || amount <= 0) return;
                              setModalState(() => saving = true);
                              final ok = await _dataService.editEntry(id: entry.id, category: selectedCategory, amount: amount, notes: notesController.text.trim());
                              if (ok && mounted) {
                                Navigator.of(context).pop();
                                _fetch();
                              } else {
                                setModalState(() => saving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

  Future<void> _confirmDelete(LogEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text('₹${entry.amount.toStringAsFixed(0)} · ${entry.category}${entry.notes.isNotEmpty ? ' · ${entry.notes}' : ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await _dataService.deleteEntry(entry.id);
      if (ok) _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Log History', style: Theme.of(context).textTheme.headlineMedium)),
                  IconButton(
                    icon: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, color: Color(0xFF6C63FF)),
                    onPressed: _loading ? null : _fetch,
                    tooltip: 'Fetch Data',
                  ),
                ],
              ),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Text("Couldn't fetch: $_error", style: const TextStyle(color: Colors.red, fontSize: 12))),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by category, notes, or amount',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _data == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Tap the refresh icon to load your history', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : entries.isEmpty
                        ? Center(child: Text(_query.isEmpty ? 'No expenses logged yet.' : 'No matches for "$_query"', style: const TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final e = entries[index];
                              final color = _colorForCategory(e.category);
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      child: Icon(_iconForCategory(e.category), color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text(e.display, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                          if (e.notes.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(e.notes, style: TextStyle(color: Colors.grey.shade700, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('₹${e.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                        Row(
                                          children: [
                                            InkWell(onTap: () => _openEdit(e), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit_rounded, size: 17, color: Colors.grey.shade500))),
                                            InkWell(onTap: () => _confirmDelete(e), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, size: 17, color: Colors.redAccent.withOpacity(0.7)))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
