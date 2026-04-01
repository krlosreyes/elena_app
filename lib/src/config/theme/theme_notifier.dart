import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Declaración manual del provider
final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  Future<void> setThemeMode(ThemeMode mode) async {
    // Hard-locked to DARK
    state = ThemeMode.dark;
  }

  Future<void> toggleTheme() async {
    // Hard-locked to DARK
    state = ThemeMode.dark;
  }
}
