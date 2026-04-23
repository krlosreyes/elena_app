// SPEC-19: Sección interactiva de pilares
//
// Contiene el estado de selección (selectedIndex) y renderiza
// PillarRingRow (menú) + PillarDetailPanel (contenido) coordinados.
// El GoalsDashboardWidget fue movido al perfil.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/shared/providers/sleep_provider.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'pillar_ring_row.dart';
import 'pillar_detail_panel.dart';

class PillarInteractiveSection extends ConsumerStatefulWidget {
  const PillarInteractiveSection({super.key, required this.user});
  final UserModel user;

  @override
  ConsumerState<PillarInteractiveSection> createState() => _PillarInteractiveSectionState();
}

class _PillarInteractiveSectionState extends ConsumerState<PillarInteractiveSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final fs = ref.watch(fastingProvider);
    final ss = ref.watch(globalSleepProvider);
    final hs = ref.watch(hydrationProvider);
    final es = ref.watch(exerciseProvider);
    final ns = ref.watch(nutritionProvider);

    final goal = widget.user.exerciseGoalMinutes.clamp(1, 180).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ─────────────────────────────────────────────────────────
        Text(
          'PILARES HOY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        const SizedBox(height: 10),

        // ── Anillos (menú de selección) ───────────────────────────────────
        PillarRingRow(
          fastingProgress:   fs.progressPercentage,
          sleepProgress:     (ss.lastLog?.duration.inHours.toDouble() ?? 0) / 9.0,
          hydrationProgress: hs.progressPercentage,
          exerciseProgress:  (es.todayMinutes / goal).clamp(0.0, 1.0),
          nutritionProgress: ns.progressPercentage,
          selectedIndex:     _selectedIndex,
          onSelected:        (i) => setState(() => _selectedIndex = i),
        ),
        const SizedBox(height: 12),

        // ── Panel de detalle del pilar seleccionado ───────────────────────
        PillarDetailPanel(
          selectedIndex: _selectedIndex,
          user: widget.user,
        ),
      ],
    );
  }
}
