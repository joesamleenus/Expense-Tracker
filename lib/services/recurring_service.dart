import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_template.dart';

class RecurringService {
  static const _key = 'recurring_templates';

  Future<List<RecurringTemplate>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => RecurringTemplate.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _saveAll(List<RecurringTemplate> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, list.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> add(RecurringTemplate template) async {
    final list = await getAll();
    list.add(template);
    await _saveAll(list);
  }

  Future<void> remove(String id) async {
    final list = await getAll();
    list.removeWhere((e) => e.id == id);
    await _saveAll(list);
  }

  Future<void> markLogged(String id, String monthKey) async {
    final list = await getAll();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx != -1) {
      list[idx].lastLoggedMonth = monthKey;
      await _saveAll(list);
    }
  }

  // Called after every Fetch Data — replaces the local list with
  // whatever the sheet has, keeping both sides in sync.
  Future<void> replaceAll(List<RecurringTemplate> serverList) async {
    await _saveAll(serverList);
  }
}
