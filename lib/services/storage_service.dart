import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

// This is your app's "private notebook" — expenses live here first,
// and only get erased once Google Sheets confirms it saved them.
class StorageService {
  static const _key = 'pending_expenses';

  Future<List<Expense>> getPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => Expense.fromJson(jsonDecode(e))).toList();
  }

  Future<void> addPending(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(expense.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> removePending(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((e) {
      final decoded = jsonDecode(e);
      return decoded['createdAt'] == expense.createdAt.toIso8601String();
    });
    await prefs.setStringList(_key, raw);
  }
}
