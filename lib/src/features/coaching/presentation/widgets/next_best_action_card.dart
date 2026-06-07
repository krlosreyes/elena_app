// SPEC-194 inc3 — card "Tu siguiente paso": la acción de coaching priorizada
// por el motor de decisión. Se oculta sola en período de gracia o si no hay
// candidato (CoachingSelection.primary == null).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/coaching/application/coaching_providers.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/action_explainer_sheet.dart';

class NextBestActionCard extends ConsumerWidget {
  const NextBestActionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(coachingSelectionProvider);
    final primary = selection.primary;
    if (primary == null) return const SizedBox.shrink();

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
                onPressed: () => ActionExplainerSheet.show(context, primary),
                child: const Text('Saber más'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _pillarLabel(Pillar p) => switch (p) {
        Pillar.fasting => 'Ayuno',
        Pillar.nutrition => 'Nutrición',
        Pillar.hydration => 'Hidratación',
        Pillar.sleep => 'Sueño',
        Pillar.exercise => 'Ejercicio',
      };
}

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
