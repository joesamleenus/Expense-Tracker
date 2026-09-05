import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_data.dart';
import 'recurring_service.dart';

class DataService {
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbw_H_AYhANgDcfI_YKMRKCobFGCoPSvqz8qBHfbgLYNQ9t_tHUcNXs-NWycl_ubLWA9Tg/exec';
  static const String secret = 'Joe';
  static const _cacheKey = 'dashboard_cache';

  Future<DashboardData?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    return DashboardData.fromJson(jsonDecode(raw));
  }

  Future<DashboardData> fetch() async {
    final uri = Uri.parse('$scriptUrl?secret=$secret');
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Server responded with code ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Unknown error');
    }
    final data = DashboardData.fromJson(decoded);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data.toJson()));
    await RecurringService().replaceAll(data.recurring);
    return data;
  }

  Future<bool> editEntry({required String id, required String category, required double amount, required String notes}) async {
    final response = await http
        .post(Uri.parse(scriptUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'secret': secret,
          'action': 'edit',
          'id': id,
          'category': category,
          'amount': amount,
          'notes': notes,
        }))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return false;
    final decoded = jsonDecode(response.body);
    return decoded['status'] == 'success';
  }

  Future<bool> deleteEntry(String id) async {
    final response = await http
        .post(Uri.parse(scriptUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'secret': secret,
          'action': 'delete',
          'id': id,
        }))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return false;
    final decoded = jsonDecode(response.body);
    return decoded['status'] == 'success';
  }

  Future<bool> addNote(String text) async {
    final response = await http
        .post(Uri.parse(scriptUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'secret': secret,
          'action': 'addNote',
          'text': text,
        }))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return false;
    final decoded = jsonDecode(response.body);
    return decoded['status'] == 'success';
  }

  Future<bool> deleteNote(String id) async {
    final response = await http
        .post(Uri.parse(scriptUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
          'secret': secret,
          'action': 'deleteNote',
          'id': id,
        }))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return false;
    final decoded = jsonDecode(response.body);
    return decoded['status'] == 'success';
  }

  Future<void> addRecurring({required String id, required String category, required double amount, required String notes}) async {
    try {
      await http.post(Uri.parse(scriptUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
        'secret': secret,
        'action': 'addRecurring',
        'id': id,
        'category': category,
        'amount': amount,
        'notes': notes,
      })).timeout(const Duration(seconds: 20));
    } catch (_) {}
  }

  Future<void> deleteRecurring(String id) async {
    try {
      await http.post(Uri.parse(scriptUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
        'secret': secret,
        'action': 'deleteRecurring',
        'id': id,
      })).timeout(const Duration(seconds: 20));
    } catch (_) {}
  }

  Future<void> markRecurringLogged({required String id, required String monthKey}) async {
    try {
      await http.post(Uri.parse(scriptUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({
        'secret': secret,
        'action': 'markRecurringLogged',
        'id': id,
        'monthKey': monthKey,
      })).timeout(const Duration(seconds: 20));
    } catch (_) {}
  }
}
