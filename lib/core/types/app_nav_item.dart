import 'package:flutter/widgets.dart';

/// Model định nghĩa item của Bottom Navigation Bar
class AppNavItem {
  final String labelKey;
  final IconData icon;
  final IconData activeIcon;

  const AppNavItem({
    required this.labelKey,
    required this.icon,
    required this.activeIcon,
  });
}
