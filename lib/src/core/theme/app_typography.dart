import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class AppTypography {
  static TextTheme get textTheme {
    return TextTheme(
      // IMR Score y números gigantes
      displayLarge: GoogleFonts.publicSans(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w900,
        fontSize: 84,
        letterSpacing: -2,
      ),
      // Títulos de secciones y fases
      titleLarge: GoogleFonts.publicSans(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      // Texto principal
      bodyLarge: GoogleFonts.publicSans(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      // Texto secundario (Labels)
      bodyMedium: GoogleFonts.publicSans(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      // Micro-copy (Unidades, labels de grid)
      labelSmall: GoogleFonts.publicSans(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}