import 'package:flutter/material.dart';

class ThemeManager {
  // Notifier tema global (default Light Mode)
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool get isDark => themeModeNotifier.value == ThemeMode.dark;

  static void toggleTheme() {
    themeModeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  static void setTheme(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }
}
