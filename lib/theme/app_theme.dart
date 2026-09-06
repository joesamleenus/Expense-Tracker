import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryInfo(this.name, this.icon, this.color);
}

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
  // Colors extracted directly from the Zaldora logo artwork.
  static const Color accent = Color(0xFFFE6E03);
  static const Color dark = Color(0xFF35312D);
  static const Color warmBackground = Color(0xFFFBF8F5);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: warmBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
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
