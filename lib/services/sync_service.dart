import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';

class SyncService {
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbw_H_AYhANgDcfI_YKMRKCobFGCoPSvqz8qBHfbgLYNQ9t_tHUcNXs-NWycl_ubLWA9Tg/exec';
  static const String secret = 'Joe';

  Future<bool> send(Expense expense) async {
    try {
      final bodyJson = jsonEncode({
        'secret': secret,
        'category': expense.category,
        'amount': expense.amount,
        'notes': expense.notes,
        'timestamp': expense.createdAt.toIso8601String(),
      });

      final response = await _postFollowingRedirects(Uri.parse(scriptUrl), bodyJson);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Google always redirects this kind of request once. This follows
  // that redirect manually, making sure it stays a POST (with your data
  // intact) instead of silently becoming an empty GET request.
  Future<http.Response> _postFollowingRedirects(Uri url, String body) async {
    final client = http.Client();
    try {
      var request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = body
        ..followRedirects = false;

      var streamed = await client.send(request).timeout(const Duration(seconds: 15));
      var response = await http.Response.fromStream(streamed);

      int redirects = 0;
      while ((response.statusCode == 301 || response.statusCode == 302 || response.statusCode == 303) &&
          response.headers['location'] != null &&
          redirects < 5) {
        final nextUrl = Uri.parse(response.headers['location']!);
        var nextRequest = http.Request('POST', nextUrl)
          ..headers['Content-Type'] = 'application/json'
          ..body = body
          ..followRedirects = false;
        streamed = await client.send(nextRequest).timeout(const Duration(seconds: 15));
        response = await http.Response.fromStream(streamed);
        redirects++;
      }

      return response;
    } finally {
      client.close();
    }
  }
}
