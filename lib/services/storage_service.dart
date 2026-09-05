import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class StorageService {
  static const _key = 'pending_expenses';
  static const _lastLoggedKey = 'last_logged_date';

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

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> markLoggedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoggedKey, _todayKey());
  }

  Future<bool> hasLoggedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLoggedKey) == _todayKey();
  }
}
