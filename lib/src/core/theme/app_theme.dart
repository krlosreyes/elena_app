// SPEC-89: paleta canónica Metamorfosis Real aplicada a ElenaApp.
//
// Tokens fuente: docs PALETTE-FOR-ELENAAPP.md (sincronizado con
// metamorfosis-web/src/styles/global.css → @theme).
//
// La app es dark-only por decisión de diseño. El antiguo `lightTheme`
// queda eliminado; cualquier consumidor que lo llame recibe el mismo
// dark theme.
//
// Mantenemos los nombres `AppColors.metabolicGreen, backgroundDark,
// surfaceDark, optimalCyan, circadianAmber, background, surface,
// border, textPrimary, textSecondary` como ALIASES de los tokens
// canónicos para no romper los 73 call sites existentes en 21
// archivos. Cualquier código nuevo debe preferir los tokens
// canónicos directos (`bgBase, bgSurface, bgElevated, textPrimary,
// textSecondary, textMuted, accent, accentStrong, statusGood,
// statusWarn, statusBad, borderSubtle, borderDefault, borderStrong`).

import 'package:flutter/material.dart';

import 'app_typography.dart';

class AppColors {
  AppColors._();

  // ─────────────────────── Backgrounds (3 niveles) ───────────────────────
  /// Fondo principal de la app (scaffold). Midnight navy.
  static const Color bgBase = Color(0xFF020617);

  /// Cards, tablas, contenedores con borde sutil.
  static const Color bgSurface = Color(0xFF0C1422);

  /// Modales, sheets, inputs, hover states, segmentos activos.
  static const Color bgElevated = Color(0xFF1A2332);

  // ─────────────────────── Text (3 niveles) ──────────────────────────────
  /// Headlines, body principal, datos importantes.
  static const Color textPrimary = Color(0xFFF1F5F9);

  /// Descripciones, párrafos secundarios, copy de apoyo.
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Labels uppercase tracking-wide, captions, metadata, placeholders.
  static const Color textMuted = Color(0xFF64748B);

  // ─────────────────────── Accent (UNO SOLO) ─────────────────────────────
  /// CTAs primarios, links activos, foco, badges importantes, IMR
  /// óptimo. Teal de salud / metabolismo.
  static const Color accent = Color(0xFF00C49A);

  /// Estado hover/pressed del CTA primario. NO usar como base color.
  static const Color accentStrong = Color(0xFF00B389);

  // ─────────────────────── Status ────────────────────────────────────────
  /// Success, IMR zona "OPTIMIZADO" o "EFICIENTE".
  static const Color statusGood = Color(0xFF10B981);

  /// Warning, IMR zona "FUNCIONAL" o "INESTABLE".
  static const Color statusWarn = Color(0xFFF59E0B);

  /// Error, IMR zona "DETERIORADO", borrar/eliminar.
  static const Color statusBad = Color(0xFFEF4444);

  // ─────────────────────── Bordes (opacidades de blanco) ────────────────
  /// Divisor entre filas de tabla. ~4% blanco.
  static const Color borderSubtle = Color(0x0AFFFFFF);

  /// Borde por defecto de cards, inputs, tabs inactivos. ~8% blanco.
  static const Color borderDefault = Color(0x14FFFFFF);

  /// Borde resaltado (hover de card). ~12% blanco.
  static const Color borderStrong = Color(0x1FFFFFFF);

  // ─────────────────────── ALIASES LEGACY ────────────────────────────────
  // Mantenidos para no romper los 73 call sites existentes (21 archivos).
  // Nuevo código debe usar tokens canónicos directamente.

  /// LEGACY → mapea a [accent].
  static const Color metabolicGreen = accent;

  /// LEGACY → mapea a [bgBase].
  static const Color backgroundDark = bgBase;

  /// LEGACY → mapea a [bgSurface].
  static const Color surfaceDark = bgSurface;

  /// LEGACY → mapea a [bgBase] (la app es dark-only).
  static const Color background = bgBase;

  /// LEGACY → mapea a [bgSurface].
  static const Color surface = bgSurface;

  /// LEGACY → mapea a [borderDefault].
  static const Color border = borderDefault;

  /// LEGACY → mapea a [accent] (era cyan claro; ahora el accent
  /// canónico es teal — mismo rol semántico).
  static const Color optimalCyan = accent;

  /// LEGACY → mapea a [statusWarn] (era ámbar circadiano; semánticamente
  /// es un warning según la paleta canónica).
  static const Color circadianAmber = statusWarn;
}

class AppTheme {
  AppTheme._();

  /// Único theme válido. La app es dark-only.
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.bgBase,
        secondary: AppColors.accent,
        onSecondary: AppColors.bgBase,
        surface: AppColors.bgSurface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.bgElevated,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.statusBad,
        onError: AppColors.textPrimary,
        outline: AppColors.borderDefault,
      ),
      textTheme: AppTypography.textTheme,
      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.bgBase,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.borderDefault),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgElevated,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.statusBad),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgElevated,
        modalBackgroundColor: AppColors.bgElevated,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  /// LEGACY → alias de [dark] para no romper consumidores que aún
  /// llamen `AppTheme.darkTheme`. Eliminar en SPEC futura cuando
  /// todos los call sites usen `AppTheme.dark`.
  static ThemeData get darkTheme => dark;

  /// LEGACY → mismo dark theme (la app ya no soporta light). El
  /// nombre se mantiene solo para que consumidores existentes no
  /// rompan; siempre devuelve dark.
  static ThemeData get lightTheme => dark;
}
