import 'package:flutter/material.dart';

/// Returns a dark-themed [ThemeData] for use with [showDatePicker] and
/// [showTimePicker] builder callbacks so they match the app's premium dark aesthetic.
ThemeData darkPickerTheme(BuildContext context) {
  return Theme.of(context).copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF009688),       // Teal — selection & accent
      onPrimary: Colors.white,          // Text on selected day
      surface: Color(0xFF1E1E1E),       // Dialog background
      onSurface: Colors.white,          // Regular text/numbers
      secondary: Color(0xFF009688),
      onSecondary: Colors.white,
      outline: Color(0xFF2E2E2E),
      surfaceContainerHighest: Color(0xFF2A2A2A),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF009688), // Cancel / OK button text
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Color(0xFF009688)),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF444444)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF009688), width: 2),
      ),
    ),
  );
}
