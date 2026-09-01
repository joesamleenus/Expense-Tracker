import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';

class SyncService {
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbw_H_AYhANgDcfI_YKMRKCobFGCoPSvqz8qBHfbgLYNQ9t_tHUcNXs-NWycl_ubLWA9Tg/exec';
  static const String secret = 'Joe';

  static String? lastError;

  Future<bool> send(Expense expense) async {
    try {
      final response = await http
          .post(
            Uri.parse(scriptUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'secret': secret,
              'clientId': expense.createdAt.toIso8601String(),
              'category': expense.category,
              'amount': expense.amount,
              'notes': expense.notes,
              'timestamp': expense.createdAt.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          lastError = null;
          return true;
        }
        lastError = 'Sheet said: ${data['message'] ?? 'unknown error'}';
        return false;
      }
      lastError = 'Server responded with code ${response.statusCode}';
      return false;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }
}
