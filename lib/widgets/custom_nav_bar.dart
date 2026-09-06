import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    Icons.home_rounded,
    Icons.pie_chart_rounded,
    Icons.receipt_long_rounded,
    Icons.sticky_note_2_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(0.16), blurRadius: 22, offset: const Offset(0, 10)),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _items.length;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: tabWidth * currentIndex + (tabWidth - 44) / 2,
                    top: (64 - 44) / 2,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.12), shape: BoxShape.circle),
                    ),
                  ),
                  Row(
                    children: List.generate(_items.length, (i) {
                      final selected = i == currentIndex;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(i),
                          child: Center(
                            child: AnimatedScale(
                              scale: selected ? 1.18 : 1.0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutBack,
                              child: Icon(_items[i], color: selected ? AppTheme.accent : Colors.grey.shade400, size: 24),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
