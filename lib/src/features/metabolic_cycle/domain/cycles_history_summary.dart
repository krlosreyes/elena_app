// SPEC-156: snapshot derivado del histórico de ciclos cerrados.
//
// Pure Dart — sin Flutter ni Riverpod. Lo consume `CyclesHistoryCard`.

import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

class CyclesHistorySummary {
  /// Ciclos visibles (ordenados por cierre descendente — más reciente arriba).
  /// Vacío si no hay ciclos cerrados.
  final List<MetabolicCycle> visibleCycles;

  /// Ciclo de mayor `dailyScore` dentro de los visibles. Null si la lista
  /// está vacía o si todos tienen score null.
  final MetabolicCycle? bestCycle;

  /// Ciclo de menor `dailyScore` dentro de los visibles. Null si la lista
  /// tiene menos de 3 elementos (no tiene sentido destacar "el peor" en
  /// listas chicas) o si no hay scores.
  final MetabolicCycle? worstCycle;

  const CyclesHistorySummary({
    required this.visibleCycles,
    required this.bestCycle,
    required this.worstCycle,
  });

  /// Estado vacío para empty state visual.
  factory CyclesHistorySummary.empty() => const CyclesHistorySummary(
        visibleCycles: [],
        bestCycle: null,
        worstCycle: null,
      );

  bool get isEmpty => visibleCycles.isEmpty;
  bool get hasBest => bestCycle != null;
  bool get hasWorst => worstCycle != null;
}
