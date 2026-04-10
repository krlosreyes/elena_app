import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppColors {
  static const Color metabolicGreen = Color(0xFF2D5A47);
  static const Color optimalCyan = Color(0xFFB3E5FC);
  static const Color circadianAmber = Color(0xFFFFB74D);
  
  // Fondo Slate 100 para Light Mode
  static const Color background = Color(0xFFF1F5F9); 
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.metabolicGreen,
      textTheme: AppTypography.textTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.metabolicGreen,
        secondary: AppColors.optimalCyan,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        background: AppColors.background,
        onBackground: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
    );
  }

  // DENTRO DE AppTheme.darkTheme
static ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    
    // CORRECCIÓN CRÍTICA: Forzamos colores claros para el modo oscuro
    textTheme: AppTypography.textTheme.apply(
      bodyColor: Colors.white,       // Esto rescatará el "IMR SCORE"
      displayColor: Colors.white,    // Esto rescatará el número "59"
      decorationColor: Colors.white,
    ),
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.metabolicGreen,
      surface: Color(0xFF1E293B),
      onSurface: Colors.white,       // Asegura contraste en elementos de superficie
      background: Color(0xFF0F172A),
      onBackground: Colors.white,    // Asegura contraste en el fondo general
    ),
  );
}
}