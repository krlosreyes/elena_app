import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Dark Telemetry
  static const Color backgroundDark = Color(0xFF0A0A0A); 
  static const Color surfaceDark = Color(0xFF151515); 
  static const Color borderDark = Color(0xFF2A2A2A);
  
  // Accents
  static const Color neonGreen = Color(0xFF00FF9D); // Primary Accent (IMX)
  static const Color neonCyan = Color(0xFF00E5FF); // Secondary Accent
  static const Color alertAmber = Color(0xFFFFC107);
  static const Color dangerRed = Color(0xFFFF1744);

  // Alias para compatibilidad
  static const Color primaryColor = neonGreen;

  static ThemeData get darkTelemetryTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: neonCyan,
        surface: surfaceDark,
        error: dangerRed,
      ),
      scaffoldBackgroundColor: backgroundDark,
      
      // Text Theme: Sans-serif for body, Monospace for headers/display
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.inter(color: const Color(0xFFE0E0E0), fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: const Color(0xFFE0E0E0)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFFE0E0E0)),
        bodySmall: GoogleFonts.inter(color: Colors.grey.shade500),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: neonGreen),
        titleTextStyle: GoogleFonts.robotoMono(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Background transparent for the neon look
          foregroundColor: neonGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: neonGreen, width: 1.5), // Neon border
          ),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) 
                ? neonGreen.withOpacity(0.1) 
                : null
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonCyan,
          textStyle: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neonCyan, width: 1.5), // Glow on focus
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIconColor: Colors.grey,
        hintStyle: TextStyle(color: Colors.grey.shade700),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0, // Flat design
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1), // Subtle border
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
        space: 24,
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
