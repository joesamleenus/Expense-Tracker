import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';

class SyncService {
  // Paste the Web App URL you got after deploying Code.gs
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbw_H_AYhANgDcfI_YKMRKCobFGCoPSvqz8qBHfbgLYNQ9t_tHUcNXs-NWycl_ubLWA9Tg/exec';

  // Must match the SECRET value inside your Apps Script exactly
  static const String secret = 'Joe';

  Future<bool> send(Expense expense) async {
    try {
      final response = await http
          .post(
            Uri.parse(scriptUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'secret': secret,
              'category': expense.category,
              'amount': expense.amount,
              'notes': expense.notes,
              'timestamp': expense.createdAt.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
