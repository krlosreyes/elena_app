// SPEC-194 inc3 — card "Tu siguiente paso": la acción de coaching priorizada
// por el motor de decisión. Se oculta sola en período de gracia o si no hay
// candidato (CoachingSelection.primary == null).
//
// SPEC-194 + SPEC-193: telemetría de conducta. `coaching_action_shown` se
// dispara una vez por acción distinta (dedup por id, post-frame para no
// contar rebuilds); `coaching_action_followed` al tocar "Saber más".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/features/coaching/application/coaching_completion_service.dart';
import 'package:elena_app/src/features/coaching/application/coaching_fatigue_notifier.dart';
import 'package:elena_app/src/features/coaching/application/coaching_providers.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/action_explainer_sheet.dart';

class NextBestActionCard extends ConsumerStatefulWidget {
  const NextBestActionCard({super.key});

  @override
  ConsumerState<NextBestActionCard> createState() => _NextBestActionCardState();
}

class _NextBestActionCardState extends ConsumerState<NextBestActionCard> {
  String? _lastShownId;

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(coachingSelectionProvider);
    final primary = selection.primary;
    // SPEC-194 RF-06: fase circadiana activa, para segmentar la telemetría
    // (tasa de acciones completadas por fase → recalibración SPEC-193/195).
    final phaseName = ref.watch(coachingSnapshotProvider).currentPhase.name;
    // SPEC-194: cachear la acción activa para correlacionar con el registro
    // del pilar (coaching_action_completed). null cuando no hay acción.
    ref.read(coachingCompletionProvider).setActive(primary);
    if (primary == null) return const SizedBox.shrink();

    // SPEC-193: una sola vez por acción distinta. addPostFrameCallback evita
    // contar rebuilds; el id evita re-disparar la misma acción.
    if (_lastShownId != primary.id) {
      _lastShownId = primary.id;
      final shownId = primary.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AnalyticsService.logEvent(
          AnalyticsEvents.coachingActionShown,
          params: {
            AnalyticsParams.actionId: shownId,
            AnalyticsParams.source: primary.source.name,
            AnalyticsParams.pillar: primary.pillar.name,
            AnalyticsParams.phase: phaseName,
          },
        );
        // RF-2.5: registrar la exhibición en el store anti-fatiga (persistente).
        // POST-FRAME a propósito: mutar el store en build dispararía un
        // rebuild del propio card (lo observa vía snapshot→selección). Tras
        // el frame, la acción ya se mostró al menos una vez; el anti-fatiga
        // la despriorizará en la próxima sesión/apertura.
        if (mounted) {
          ref.read(coachingFatigueProvider.notifier).recordShown(shownId);
        }
      });
    }

    final theme = Theme.of(context);
    final secondary = selection.secondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    primary.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _PillarChip(label: _pillarLabel(primary.pillar)),
              ],
            ),
            const SizedBox(height: 8),
            Text(primary.actionText, style: theme.textTheme.bodyMedium),
            if (secondary != null) ...[
              const SizedBox(height: 6),
              Text(
                'También: ${secondary.actionText}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  AnalyticsService.logEvent(
                    AnalyticsEvents.coachingActionFollowed,
                    params: {
                      AnalyticsParams.actionId: primary.id,
                      AnalyticsParams.source: primary.source.name,
                      AnalyticsParams.phase: phaseName,
                    },
                  );
                  ActionExplainerSheet.show(context, primary);
                },
                child: const Text('Saber más'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _pillarLabel(Pillar p) => switch (p) {
      Pillar.fasting => 'Ayuno',
      Pillar.nutrition => 'Nutrición',
      Pillar.hydration => 'Hidratación',
      Pillar.sleep => 'Sueño',
      Pillar.exercise => 'Ejercicio',
    };

class _PillarChip extends StatelessWidget {
  const _PillarChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
