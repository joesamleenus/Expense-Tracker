import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_data.dart';

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
    return data;
  }
}
