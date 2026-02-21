import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color brandBlue = Color(0xFF1565C0); // Azul Prominente
  static const Color brandDark = Color(0xFF0D47A1); // Azul Oscuro
  static const Color brandTeal = Color(0xFF009688); // Verde Azulado

  static const Color brandLightBlue = Color(0xFFE3F2FD); // Azul muy claro para fondos
  static const Color surfaceColor = Color(0xFFF5F5F5); // Gris muy claro para fondos de pantalla

  // Alias para compatibilidad si se usaba primaryColor directamente (aunque primaryColor suele ser de Theme)
  static const Color primaryColor = brandBlue;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandBlue,
        primary: brandBlue,
        secondary: brandTeal,
        background: Colors.white,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Gris muy claro
      
      // Text Theme
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: brandBlue,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: brandBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: brandBlue),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brandTeal.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandTeal, width: 2),
        ),
        labelStyle: const TextStyle(color: brandBlue),
        prefixIconColor: brandTeal,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
