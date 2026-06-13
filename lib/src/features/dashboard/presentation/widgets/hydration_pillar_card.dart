// SPEC-119 (refactor god widget) — card del pilar Hidratación extraída de
// dashboard_screen.dart. ConsumerWidget autocontenido; recibe el estado por
// constructor y dispara las acciones vía hydrationProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_card_ui.dart';

class HydrationPillarCard extends ConsumerWidget {
  const HydrationPillarCard({super.key, required this.state});

  final HydrationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = Color(0xFF38BDF8);
    final progress = state.progressPercentage;
    final pct = (progress * 100).round();

    return PillarCardUi.shell(
      title: 'Soporte Metabólico',
      badge: 'Hidratación',
      accent: accent,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${state.currentFormatted} L',
              style: TextStyle(
                color: accent,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '/ ${state.goalFormatted} L',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PillarCardUi.progressBar(progress, accent),
        const SizedBox(height: 6),
        PillarCardUi.completionLabel(pct),
        const SizedBox(height: 16),
        PillarCardUi.benefitChip(
          accent: accent,
          text:
              'Cada 250ml mejora el flujo linfático y la eliminación de metabolitos',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: PillarCardUi.outlinedActionButton(
                label: '+250 ml',
                accent: accent,
                onPressed: state.isSaving
                    ? null
                    : () =>
                        ref.read(hydrationProvider.notifier).addWater(0.250),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillarCardUi.outlinedActionButton(
                label: '+500 ml',
                accent: accent,
                onPressed: state.isSaving
                    ? null
                    : () =>
                        ref.read(hydrationProvider.notifier).addWater(0.500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PillarCardUi.secondaryButton(
          label: 'Descontar último vaso (-250 ml)',
          icon: Icons.remove_circle_outline_rounded,
          // Deshabilitado si no hay nada que descontar o si hay una
          // operación en curso.
          onPressed: state.history.isEmpty
              ? null
              : () => ref
                  .read(hydrationProvider.notifier)
                  .removeLastWater(),
        ),
      ],
    );
  }
}
