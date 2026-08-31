import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryInfo(this.name, this.icon, this.color);
}

// Your 9 categories — must match the dropdown/spelling in the Google Sheet exactly.
const List<CategoryInfo> kCategories = [
  CategoryInfo('Rent', Icons.home_rounded, Color(0xFF6C63FF)),
  CategoryInfo('Subscriptions', Icons.repeat_rounded, Color(0xFF00BFA6)),
  CategoryInfo('Entertainment', Icons.movie_rounded, Color(0xFFFF6584)),
  CategoryInfo('Food & Coffee', Icons.local_cafe_rounded, Color(0xFFFFA726)),
  CategoryInfo('Groceries', Icons.shopping_cart_rounded, Color(0xFF4CAF50)),
  CategoryInfo('Health & Wellbeing', Icons.favorite_rounded, Color(0xFFEF5350)),
  CategoryInfo('Shopping', Icons.shopping_bag_rounded, Color(0xFFAB47BC)),
  CategoryInfo('Travel', Icons.flight_takeoff_rounded, Color(0xFF29B6F6)),
  CategoryInfo('Other', Icons.more_horiz_rounded, Color(0xFF78909C)),
];

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400),
      ),
    );
  }
}
