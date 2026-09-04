import 'package:flutter/material.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log History', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text('Search, edit, and delete your entries here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('Coming next', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
