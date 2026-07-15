// Propuesta "racha protagonista" (2026-07-15, P4): ninguna parte de la app
// avisaba PROACTIVAMENTE que la racha estaba en riesgo — el usuario solo
// se enteraba después de perderla (banner de racha rota, ya reencuadrado
// con compasión en SPEC-255 RF-03). Duolingo notifica antes del corte del
// día; Apple Watch avisa "quedan 10 min y no cerraste tu anillo de pie".
// Este banner es el equivalente: aparece en horario de tarde/noche si hoy
// todavía no calificó y hay una racha real en juego (ver
// `streakAtRiskProvider` en streak_notifier.dart para las condiciones
// exactas, incluida la exclusión cuando ya hay una reserva disponible que
// protegería el día de todos modos).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/application/ui_interaction_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/presentation/widgets/streak_explainer_sheet.dart';

class StreakAtRiskBanner extends ConsumerWidget {
  const StreakAtRiskBanner({super.key});

  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atRisk = ref.watch(streakAtRiskProvider);
    final dismissed = ref.watch(uiInteractionProvider).isStreakAtRiskDismissed;

    if (!atRisk || dismissed) return const SizedBox.shrink();

    final currentStreak = ref.watch(streakProvider.select((s) => s.currentStreak));
    final reason = ref.watch(
      streakProvider.select((s) => s.todayEntry?.missReason),
    );

    final String whatIsMissing;
    if (reason == null) {
      whatIsMissing = 'Todavía no registraste ningún pilar hoy.';
    } else if (reason.isAnchorIssue) {
      whatIsMissing = 'Te falta ayuno o sueño para que hoy cuente.';
    } else {
      final n = reason.missingPillarsCount!;
      whatIsMissing = n == 1
          ? 'Te falta 1 pilar más para que hoy cuente.'
          : 'Te faltan $n pilares más para que hoy cuente.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: _amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TU RACHA DE $currentStreak DÍAS ESTÁ EN RIESGO HOY',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _amber,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  whatIsMissing,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => ref
                          .read(uiInteractionProvider.notifier)
                          .dismissStreakAtRisk(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Ahora no',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => showStreakExplainerSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _amber,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Ver qué me falta',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
