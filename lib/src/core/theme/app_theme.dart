import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color elenaGreen = Color(0xFF00C853); // Elena Green
  static const Color deepEmerald = Color(0xFF27AE60); // Deep Emerald
  static const Color black = Color(0xFF000000);
  static const Color surface = Color(0xFF161616);
  static const Color outline = Color(0xFF333333);
}

class AppTheme {
  static const Color primary = AppColors.elenaGreen;
  static const Color background = AppColors.black;
  static const Color surface = AppColors.surface;
  static const Color outline = AppColors.outline;
  static const Color textBody = Colors.white;
  static const Color textDim = Color(0xFF999999);

  static ThemeData get darkTheme {
    TextTheme baseTextTheme = const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    );

    TextTheme robustTextTheme;
    try {
      robustTextTheme = GoogleFonts.publicSansTextTheme(baseTextTheme);
    } catch (e) {
      debugPrint('⚠️ Fallback de Fuentes: Error cargando GoogleFonts: $e');
      robustTextTheme = baseTextTheme;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.black,
        secondary: primary,
        surface: surface,
        onSurface: Colors.white,
        outline: outline,
      ),
      textTheme: robustTextTheme,
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: surface,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 8,
      ),
    );
  }
}
