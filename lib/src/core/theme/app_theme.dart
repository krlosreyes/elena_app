import 'package:flutter/material.dart';
// Asegúrate de que este archivo exista en la misma carpeta
import 'app_typography.dart'; 

class AppColors {
  static const Color metabolicGreen = Color(0xFF2D5A47);
  static const Color optimalCyan = Color(0xFFB3E5FC);
  static const Color circadianAmber = Color(0xFFFFB74D);
  
  static const Color background = Color(0xFFF1F5F9); 
  static const Color backgroundDark = Colors.black;
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF111827); // Gris muy oscuro para contraste
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
      // SPEC-72.10: `background` y `onBackground` se eliminaron — son
      // deprecated en Material 3. El rol que cubrían lo asume:
      //   - `scaffoldBackgroundColor` (línea de arriba) para el fondo de Scaffold.
      //   - `surface` / `onSurface` para superficies elevadas (cards, sheets).
      // Cualquier widget que en M3 leía `colorScheme.background` debe migrar
      // a `colorScheme.surface` o `theme.scaffoldBackgroundColor`.
      colorScheme: const ColorScheme.light(
        primary: AppColors.metabolicGreen,
        secondary: AppColors.optimalCyan,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      textTheme: AppTypography.textTheme.apply(
        bodyColor: Colors.white,       
        displayColor: Colors.white,    
        decorationColor: Colors.white,
      ),
      
      // SPEC-72.10: ver comentario en lightTheme — mismo razonamiento.
      colorScheme: const ColorScheme.dark(
        primary: AppColors.metabolicGreen,
        secondary: AppColors.optimalCyan,
        surface: AppColors.surfaceDark,
        onSurface: Colors.white,
      ),
    );
  }
}