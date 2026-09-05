import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/category_screen.dart';
import 'screens/data_screen.dart';
import 'screens/log_screen.dart';
import 'screens/notes_screen.dart';
import 'widgets/custom_nav_bar.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainTabScaffold(),
    );
  }
}

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _index = index);
    _controller.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: _onPageChanged,
        children: const [
          CategoryScreen(),
          DataScreen(),
          LogScreen(),
          NotesScreen(),
        ],
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: _index, onTap: _onTabTapped),
    );
  }
}
