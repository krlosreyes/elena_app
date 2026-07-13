// SPEC-255 RF-01: BottomSheet educativo de la racha.
//
// Espejo del patrón de daily_score_explainer_sheet.dart (SPEC-140/170).
// Objetivo: que el usuario entienda EXACTAMENTE qué cuenta como "día de
// racha" (regla real en StreakEntry.qualifiesForStreak), que sepa que la
// racha es gratis en todos los tiers (no gateada — ver feature_gate.dart),
// y que conozca el mecanismo de reservas (freeze) que la protege.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

void showStreakExplainerSheet(BuildContext context) {
  AnalyticsService.logEvent(AnalyticsEvents.streakExplainerOpened);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _StreakExplainerSheet(),
  );
}

class _StreakExplainerSheet extends StatelessWidget {
  const _StreakExplainerSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
            const Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Text(
                  'Tu racha',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Un día cuenta para tu racha cuando refleja un día '
              'metabólico real — no cualquier actividad menor.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            _RuleCard(
              accent: AppColors.metabolicGreen,
              icon: Icons.check_circle_outline_rounded,
              title: 'Regla principal',
              body: 'Completa 3 de tus 5 pilares, y que al menos uno '
                  'sea ayuno o sueño. Son los dos con más evidencia '
                  'sobre tu metabolismo — un día sin ninguno de los dos '
                  'no cuenta, aunque hayas hecho ejercicio, tomado agua '
                  'y registrado una comida.',
            ),
            const SizedBox(height: 12),
            _RuleCard(
              accent: const Color(0xFF22D3EE),
              icon: Icons.stars_rounded,
              title: 'Alternativa: 4 de 5',
              body: 'Si completas 4 o más pilares (los que sean), '
                  'también cuenta. Alta adherencia al día completo '
                  'compensa que falte ayuno o sueño ese día puntual.',
            ),
            const SizedBox(height: 22),
            const Text(
              'RESERVAS DE RACHA',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            _RuleCard(
              accent: const Color(0xFFF59E0B),
              icon: Icons.shield_outlined,
              title: 'Un mal día no te cuesta la racha',
              body: 'Cada 7 días reales seguidos ganas 1 reserva (tope '
                  '2). Si un día no llegas al mínimo, una reserva lo '
                  'perdona automáticamente y tu racha sigue. Es gratis '
                  'para todos — no depende de tu plan.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.metabolicGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.metabolicGreen.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: AppColors.metabolicGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Si tu racha se rompe alguna vez, tu récord más '
                      'largo queda guardado para siempre — no se '
                      'pierde. Volver a empezar también cuenta.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fundamento: AASM 2015, Sutton 2018 (Cell Metab), '
              'Walker 2017, Spiegel 1999 (Lancet) — ayuno y sueño son '
              'los vectores con más peso sobre el eje hormonal '
              '(grelina/leptina/insulina).',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
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
