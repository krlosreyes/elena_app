// Progreso v4 (2026-11-05): datos derivados para la pantalla.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/domain/recomposition.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_insight.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:elena_app/src/features/metabolic_cycle/data/metabolic_cycle_repository_impl.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/progress/application/progress_notifier.dart';

/// Recomposición entre la medición más reciente y la más cercana a 30 días
/// antes. Null = todavía no hay dos mediciones comparables.
final recompositionProvider = Provider<Recomposition?>((ref) {
  final history = ref.watch(progressProvider.select((s) => s.biometricHistory));
  return Recomposition.compute(history);
});

final _last30ClosedCyclesProvider = StreamProvider<List<MetabolicCycle>>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(const []);
  return ref
      .watch(metabolicCycleRepositoryProvider)
      .watchRecentClosed(account.uid, limit: 30);
});

/// Días metabólicos de los últimos 30 días: (cerrados por ti, total).
final closedByYou30Provider = Provider<(int, int)?>((ref) {
  final cycles = ref.watch(_last30ClosedCyclesProvider).valueOrNull;
  if (cycles == null) return null;
  return countClosedByYou(cycles, DateTime.now());
});

(int, int) countClosedByYou(List<MetabolicCycle> cycles, DateTime now) {
  final cutoff = now.subtract(const Duration(days: 30));
  final recent = cycles.where((c) => c.startedAt.isAfter(cutoff)).toList();
  final byYou = recent
      .where((c) => c.closureReason == ClosureReason.manualNextFasting)
      .length;
  return (byYou, recent.length);
}

/// Resumen de glucosa en ayunas para Progreso.
class GlucoseProgress {
  const GlucoseProgress({
    required this.avg14,
    required this.prevAvg14,
    required this.recent,
    required this.insight,
  });

  /// Promedio en ayunas de los últimos 14 días (null = sin lecturas).
  final double? avg14;

  /// Promedio de los 14 días anteriores (para el cambio).
  final double? prevAvg14;

  /// Hasta 14 lecturas en ayunas recientes, de la más vieja a la nueva.
  final List<int> recent;

  final GlucoseInsight? insight;

  double? get delta =>
      (avg14 != null && prevAvg14 != null) ? avg14! - prevAvg14! : null;

  static GlucoseProgress from(
    List<GlucoseReading> readings,
    List<GlucoseInsight> insights,
    DateTime now,
  ) {
    final ayunas = readings
        .where((r) => r.context == GlucoseReadingContext.ayunas)
        .toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final c14 = now.subtract(const Duration(days: 14));
    final c28 = now.subtract(const Duration(days: 28));
    double? avg(Iterable<GlucoseReading> rs) {
      final l = rs.toList();
      if (l.isEmpty) return null;
      return l.map((r) => r.valueMgDl).reduce((a, b) => a + b) / l.length;
    }

    final last = ayunas.where((r) => r.measuredAt.isAfter(c14));
    final prev = ayunas
        .where((r) => r.measuredAt.isAfter(c28) && !r.measuredAt.isAfter(c14));
    final lastList = last.map((r) => r.valueMgDl).toList();
    return GlucoseProgress(
      avg14: avg(last),
      prevAvg14: avg(prev),
      recent: lastList.length > 14
          ? lastList.sublist(lastList.length - 14)
          : lastList,
      insight: insights.isEmpty ? null : insights.first,
    );
  }
}

/// Null si el seguimiento de glucosa NO está activo (la tarjeta no se
/// muestra).
final glucoseProgressProvider = Provider<GlucoseProgress?>((ref) {
  final state = ref.watch(glucoseProtocolStateProvider).valueOrNull;
  if (state == null || !state.shouldPromptForReadings) return null;
  final readings = ref.watch(glucoseReadingsProvider).valueOrNull ?? const [];
  final insights = ref.watch(glucoseInsightsProvider);
  return GlucoseProgress.from(readings, insights, DateTime.now());
});
