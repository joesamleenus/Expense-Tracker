import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/data_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => NotesScreenState();
}

class NotesScreenState extends State<NotesScreen> {
  final _dataService = DataService();
  final _noteController = TextEditingController();
  DashboardData? _data;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCached() async {
    try {
      final cached = await _dataService.loadCached();
      if (cached != null && mounted) setState(() => _data = cached);
    } catch (_) {}
  }

  Future<void> _fetch() async {
    if (_loading) return;
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

  Future<void> silentRefresh() => _fetch();

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final ok = await _dataService.addNote(text);
    if (ok) {
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
        );
      }
      await _fetch();
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _deleteNote(NoteEntry note) async {
    final rootContext = context;
    final confirmed = await showDialog<bool>(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this note?'),
        content: Text(note.text, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await _dataService.deleteNote(note.id);
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(rootContext).showSnackBar(
            const SnackBar(content: Text('Note deleted'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
          );
        }
        await _fetch();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _data?.notes ?? [];
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
                  Expanded(child: Text('Notes', style: Theme.of(context).textTheme.headlineMedium)),
                  IconButton(
                    icon: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, color: Color(0xFF6C63FF)),
                    onPressed: _loading ? null : _fetch,
                    tooltip: 'Fetch Data',
                  ),
                ],
              ),
              Text('Jot down anything money-related, like money lent to someone.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 6), child: Text("Couldn't fetch: $_error", style: const TextStyle(color: Colors.red, fontSize: 12))),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))]),
                child: Column(
                  children: [
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Write a note...', border: InputBorder.none),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveNote,
                        icon: _saving
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Save note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sticky_note_2_rounded, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No notes yet.', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final n = notes[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n.text, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(n.display, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                InkWell(onTap: () => _deleteNote(n), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent.withOpacity(0.7)))),
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
