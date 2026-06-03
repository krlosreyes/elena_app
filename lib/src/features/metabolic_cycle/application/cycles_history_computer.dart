// SPEC-156: motor puro del CyclesHistoryCard.
//
// Toma la lista cruda de ciclos cerrados (del repository) y devuelve un
// snapshot con: los N más recientes ordenados, el mejor, el peor.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/metabolic_cycle/domain/cycles_history_summary.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

class CyclesHistoryComputer {
  CyclesHistoryComputer._();

  /// Default de ciclos visibles. ~1 semana metabólica típica.
  static const int kDefaultMaxToShow = 7;

  /// Mínimo de ciclos visibles para destacar "el peor". En listas
  /// chicas el "peor" tiene poco valor narrativo y puede desmotivar.
  static const int kMinForWorstHighlight = 3;

  /// Construye el summary desde la lista de ciclos cerrados que entrega
  /// `metabolicCyclesHistoryProvider`. La lista entrante puede o no estar
  /// ordenada; nosotros la reordenamos por `closedAt` descendente y
  /// cortamos a `maxToShow`.
  static CyclesHistorySummary compute({
    required List<MetabolicCycle> closedCycles,
    int maxToShow = kDefaultMaxToShow,
  }) {
    if (closedCycles.isEmpty) {
      return CyclesHistorySummary.empty();
    }

    // Filtrar solo cerrados con closedAt no-null (defensa).
    final closed = closedCycles.where((c) => c.closedAt != null).toList();
    if (closed.isEmpty) {
      return CyclesHistorySummary.empty();
    }

    closed.sort((a, b) => b.closedAt!.compareTo(a.closedAt!));
    final visible = closed.take(maxToShow).toList();

    final best = pickBestCycle(visible);
    final worst = visible.length >= kMinForWorstHighlight
        ? pickWorstCycle(visible)
        : null;

    return CyclesHistorySummary(
      visibleCycles: visible,
      bestCycle: best,
      worstCycle: worst,
    );
  }

  /// El ciclo de mayor `dailyScore` de la lista. Si hay empates, gana
  /// el más reciente (closedAt mayor). Null si la lista está vacía o
  /// no hay scores.
  static MetabolicCycle? pickBestCycle(List<MetabolicCycle> cycles) {
    MetabolicCycle? best;
    for (final c in cycles) {
      if (c.dailyScore == null) continue;
      if (best == null) {
        best = c;
        continue;
      }
      final bestScore = best.dailyScore!;
      final currScore = c.dailyScore!;
      if (currScore > bestScore) {
        best = c;
      } else if (currScore == bestScore &&
          c.closedAt != null &&
          best.closedAt != null &&
          c.closedAt!.isAfter(best.closedAt!)) {
        best = c;
      }
    }
    return best;
  }

  /// El ciclo de menor `dailyScore`. Empates → el más reciente.
  static MetabolicCycle? pickWorstCycle(List<MetabolicCycle> cycles) {
    MetabolicCycle? worst;
    for (final c in cycles) {
      if (c.dailyScore == null) continue;
      if (worst == null) {
        worst = c;
        continue;
      }
      final worstScore = worst.dailyScore!;
      final currScore = c.dailyScore!;
      if (currScore < worstScore) {
        worst = c;
      } else if (currScore == worstScore &&
          c.closedAt != null &&
          worst.closedAt != null &&
          c.closedAt!.isAfter(worst.closedAt!)) {
        worst = c;
      }
    }
    return worst;
  }
}
