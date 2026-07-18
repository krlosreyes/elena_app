import 'package:flutter/material.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

/// SPEC-119: extraídos de `onboarding_screen.dart` (ARCH-03). Estos 3
/// helpers (`_header`, `_stepHelperLine`, `_sectionTitle`) eran
/// funciones puras — solo tomaban `String`/`bool` como parámetros, sin
/// leer ningún campo de `_OnboardingScreenState` — así que la
/// extracción a widgets propios es mecánica y no cambia comportamiento.

/// Header de cada paso del onboarding: título grande + sub-copy.
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.title,
    required this.sub,
    required this.isDark,
  });

  final String title;
  final String sub;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -1)),
      Text(sub,
          style: TextStyle(
              color: isDark ? Colors.white38 : const Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 24)
    ]);
  }
}

/// SPEC-131: línea explicativa contextual debajo del header de cada
/// paso. Da contexto al usuario cero-contexto sobre POR QUÉ pedimos
/// estos datos sin invadir visualmente.
class OnboardingStepHelperLine extends StatelessWidget {
  const OnboardingStepHelperLine({
    super.key,
    required this.text,
    required this.isDark,
  });

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.metabolicGreen.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.metabolicGreen.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: AppColors.metabolicGreen,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondary
                      : const Color(0xFF475569),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título de sub-sección dentro de un paso (ej. "TALLAS (INFERENCIA)").
class OnboardingSectionTitle extends StatelessWidget {
  const OnboardingSectionTitle({
    super.key,
    required this.title,
    required this.isDark,
  });

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(title,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF10B981),
                letterSpacing: 1.5)));
  }
}

/// SPEC-70.8: tarjeta individual de cada contraindicación. Reusable para
/// los 5 items listados en el paso 0 del onboarding (T1D, TCA, IRC,
/// embarazo/lactancia, sarcopenia >75).
///
/// SPEC-119: renombrado de `_DisclaimerItem` (privado) a
/// `DisclaimerItem` (público) al extraerlo — sin cambios de
/// comportamiento.
class DisclaimerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isDark;

  const DisclaimerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.65);
    final iconColor =
        isDark ? const Color(0xFF10B981) : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
