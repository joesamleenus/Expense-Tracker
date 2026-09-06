import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsService {
  static const _nameKey = 'user_name';

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey);
    return (name != null && name.trim().isNotEmpty) ? name.trim() : null;
  }

  Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
  }
}
