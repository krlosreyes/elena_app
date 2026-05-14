// SPEC-89: tipografía canónica Metamorfosis Real.
//
// Fuentes:
// - Inter para body / UI / labels.
// - Space Grotesk para headlines expresivos (display, title).
//
// Ambos se cargan vía `google_fonts` que ya está en pubspec.yaml.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    return TextTheme(
      // ── Headlines (Space Grotesk) ─────────────────────────────────
      // Números gigantes, IMR Score grande.
      displayLarge: GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w900,
        fontSize: 84,
        letterSpacing: -2,
      ),
      // Títulos de secciones y fases.
      titleLarge: GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),

      // ── Body (Inter) ──────────────────────────────────────────────
      bodyLarge: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),

      // ── Labels / Captions (Inter) ─────────────────────────────────
      labelLarge: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      labelMedium: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.98,
      ),
    );
  }
}
