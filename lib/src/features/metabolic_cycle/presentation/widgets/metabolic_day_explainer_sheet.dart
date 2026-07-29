// Hoja «¿Qué es el Día Metabólico?» (2026-07-28).
//
// Mismo patrón que streak_explainer_sheet.dart y
// daily_score_explainer_sheet.dart: una sola hoja reutilizable, abierta
// desde cada sitio donde aparece el término.
//
// Todo el texto viene de `metabolic_day_copy.dart` — este archivo solo
// lo pinta. La razón es que el término sale en 10 pantallas: si cada una
// redactara lo suyo, tendríamos 10 definiciones de la misma regla y
// ninguna forma de saber cuál está desactualizada.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_day_copy.dart';

/// [fastingProtocol] decide si se muestra la nota del modo calendárico.
/// Si no se pasa, la nota aparece igualmente pero como caso general —
/// es preferible explicar de más que dejar a alguien sin entender por
/// qué su día cierra a medianoche.
void showMetabolicDayExplainerSheet(
  BuildContext context, {
  String? fastingProtocol,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MetabolicDayExplainerSheet(
      fastingProtocol: fastingProtocol,
    ),
  );
}

class _MetabolicDayExplainerSheet extends StatelessWidget {
  final String? fastingProtocol;

  const _MetabolicDayExplainerSheet({this.fastingProtocol});

  @override
  Widget build(BuildContext context) {
    final esCalendario =
        fastingProtocol == null || usaDiaCalendario(fastingProtocol!);

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.autorenew_rounded,
                    color: AppColors.metabolicGreen, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Tu Día Metabólico',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // La definición, destacada: es lo único que el usuario tiene
            // que llevarse si no lee nada más.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.metabolicGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.metabolicGreen.withValues(alpha: 0.22),
                ),
              ),
              child: const Text(
                kMetabolicDayCoreDefinition,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              kMetabolicDayRationale,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),

            const _Rule(
              icon: Icons.play_circle_outline_rounded,
              title: kMetabolicDayStartTitle,
              body: kMetabolicDayStartBody,
            ),
            const SizedBox(height: 10),
            const _Rule(
              icon: Icons.flag_outlined,
              title: kMetabolicDayEndTitle,
              body: kMetabolicDayEndBody,
            ),
            const SizedBox(height: 10),
            _Rule(
              icon: Icons.shield_outlined,
              title: kMetabolicDayAutoCloseTitle,
              body: kMetabolicDayAutoCloseBody,
            ),

            if (esCalendario) ...[
              const SizedBox(height: 10),
              const _Rule(
                icon: Icons.calendar_today_rounded,
                title: kMetabolicDayCalendarTitle,
                body: kMetabolicDayCalendarBody,
                muted: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool muted;

  const _Rule({
    required this.icon,
    required this.title,
    required this.body,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        muted ? Colors.white.withValues(alpha: 0.4) : AppColors.metabolicGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.5,
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
