import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color metabolicGreen = Color(0xFF2D5A47);
  static const Color optimalCyan = Color(0xFFB3E5FC);
  static const Color circadianAmber = Color(0xFFFFB74D);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get lightTheme {
    TextTheme baseTextTheme = const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.metabolicGreen, 
        fontWeight: FontWeight.w900, 
        fontSize: 84, 
        letterSpacing: -2,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary, 
        fontWeight: FontWeight.w800, 
        fontSize: 22,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary, 
        fontSize: 16, 
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary, 
        fontSize: 14,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.metabolicGreen,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.metabolicGreen,
        secondary: AppColors.optimalCyan,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),

      textTheme: GoogleFonts.publicSansTextTheme(baseTextTheme),

      // CORRECCIÓN: Usamos CardThemeData en lugar de CardTheme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.metabolicGreen,
        unselectedItemColor: AppColors.textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}