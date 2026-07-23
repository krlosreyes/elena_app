// Módulo "Tu Glucosa" — card de entrada en Progreso (propuesta §7.3).
//
// Mismo patrón EXACTO que ResultsEntryCard/BadgesEntryCard (copy-paste
// consistente ya establecido en la pantalla — no hay un widget
// `EntryCard` genérico en la base). Autocontenida (`ConsumerWidget` con
// su propio estado de "oculto si no aplica"), mismo criterio ya
// documentado para `WeeklyCoachingCard` en analysis_screen.dart: no
// requiere que `AnalysisScreen` deje de ser `StatelessWidget`.
//
// Regla de visibilidad (§5.2): la card solo se muestra si
// `protocolActive == true` (activado por pathologies o manualmente
// desde Perfil) — nunca se insinúa a usuarios sin el protocolo activo,
// ni siquiera como "descúbrelo" (propuesta, Riesgos y limitaciones:
// riesgo de generar ansiedad/medicalizar innecesariamente).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_classification.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';

class GlucoseEntryCard extends ConsumerWidget {
  const GlucoseEntryCard({super.key});

  static const _color = Color(0xFFE879F9); // fucsia — distinto de los
  // 5 pilares y de las otras 3 cards de Progreso, para que se
  // distinga como una categoría aparte (dato clínico, no un hábito más).

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocolState = ref.watch(glucoseProtocolStateProvider).valueOrNull;
    if (protocolState == null || !protocolState.protocolActive) {
      return const SizedBox.shrink();
    }

    final readings = ref.watch(glucoseReadingsProvider).valueOrNull ?? const [];
    String subtitle = 'Aún sin registros';
    if (readings.isNotEmpty) {
      final last = readings.first; // ordenado desc por measuredAt.
      final classification =
          GlucoseClassifier.classify(last.valueMgDl, last.context);
      final tag = classification == GlucoseClassification.sinUmbral
          ? ''
          : ' · ${classification.label}';
      subtitle = '${last.valueMgDl} mg/dL$tag';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/analysis/glucosa'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water_drop_outlined,
                    color: _color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu Glucosa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
