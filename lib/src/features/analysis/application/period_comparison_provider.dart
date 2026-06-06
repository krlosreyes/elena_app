// SPEC-113: providers de la pantalla Análisis.
//
// PERF (post-SPEC-113): consolidación en `periodDataProvider`. Una
// sola suscripción Firestore al rango doble (período actual + previo
// juntos). Splitea client-side. Pasa de 2 streams Firestore por
// pantalla → 1.
//
// ⚠️ SPEC-192 (2026-06-05) — EXCEPCIÓN DOCUMENTADA al §1 de la
// constitución. Este provider permanece intencionalmente calendárico
// porque alimenta charts retrospectivos del Analysis tab (heatmap,
// strip, trend chart) que muestran "tu mes de junio" en el eje X.
// Migrar a ciclos rompería la semántica visual ("ciclos del último
// mes" puede ser 15-60 días reales según ritmo del usuario).
//
// La comparativa CYCLE-AWARE para coaching la ofrece
// `cycleComparisonProvider` (SPEC-192.3a), que consume el
// `WeeklyCoachingCard`. Esta separación es CONSCIENTE:
//   - period_comparison: vista retrospectiva calendárica (charts)
//   - cycleComparison:    coaching cycle-aware (insights)
//
// El refactor completo a SchemaCycle queda como SPEC-192.4 + 192.5
// post-MVP, donde decidirá si Analysis tab también migra a vista
// cíclica o mantiene esta dualidad.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/analysis/application/period_comparison_service.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_repository_impl.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_period.dart';
import 'package:elena_app/src/features/analysis/domain/period_comparison.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Helper: formato YYYY-MM-DD. SPEC-138: delega en la fuente única del día.
String _fmt(DateTime t) => DayBoundaryResolver.dayKeyIso(t);

/// Bundle con los docs del período actual + el comparison ya computado.
/// Empaquetar ambos en un solo provider evita que la pantalla haga 2
/// watches paralelos sobre la misma fuente de datos.
class PeriodData {
  final List<DailySummaryDoc> currentDocs;
  final PeriodComparison comparison;

  /// SPEC-153: docs del período inmediatamente anterior, expuestos para
  /// providers derivados (WeeklyCoachingCard usa current + previous para
  /// computar deltas por pilar). La query base ya los trae — exponerlos
  /// evita duplicar la suscripción Firestore.
  final List<DailySummaryDoc> previousDocs;

  const PeriodData({
    required this.currentDocs,
    required this.comparison,
    this.previousDocs = const [],
  });
}

/// Provider unificado: una query Firestore al rango doble, splittea
/// client-side en current + previous, computa el comparison y
/// devuelve ambos. `autoDispose` libera el stream al salir; el caché
/// offline de Firestore absorbe el cold-start al volver.
final periodDataProvider = StreamProvider.family
    .autoDispose<PeriodData, AnalysisPeriod>((ref, period) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) {
    return Stream.value(PeriodData(
      currentDocs: const [],
      comparison: PeriodComparison.empty(period.days),
    ));
  }
  final repo = ref.watch(dailySummaryRepositoryProvider);

  // Rangos.
  final today = DateTime.now();
  final todayMidnight = DayBoundaryResolver.startOfDay(today); // SPEC-138
  final doubleFrom =
      todayMidnight.subtract(Duration(days: 2 * period.days - 1));
  final currentFrom = todayMidnight.subtract(Duration(days: period.days - 1));
  final boundary = _fmt(currentFrom);

  return repo
      .watchRange(
    userId: uid,
    fromIncl: _fmt(doubleFrom),
    toIncl: _fmt(todayMidnight),
  )
      .map((allDocs) {
    final currentDocs = <DailySummaryDoc>[];
    final previousDocs = <DailySummaryDoc>[];
    for (final d in allDocs) {
      if (d.date.compareTo(boundary) >= 0) {
        currentDocs.add(d);
      } else {
        previousDocs.add(d);
      }
    }
    final comparison = PeriodComparisonService.compute(
      currentDocs: currentDocs,
      previousDocs: previousDocs,
      daysInPeriod: period.days,
    );
    return PeriodData(
      currentDocs: currentDocs,
      previousDocs: previousDocs,
      comparison: comparison,
    );
  });
});

/// Selector derivado: expone solo el `PeriodComparison` cuando la UI
/// solo necesita ese fragmento (e.g., hero card).
final periodComparisonProvider = Provider.family
    .autoDispose<AsyncValue<PeriodComparison>, AnalysisPeriod>((ref, period) {
  return ref.watch(periodDataProvider(period)).whenData((d) => d.comparison);
});

/// Selector derivado: expone solo los docs del período actual.
final currentPeriodDocsProvider = Provider.family
    .autoDispose<AsyncValue<List<DailySummaryDoc>>, AnalysisPeriod>(
        (ref, period) {
  return ref.watch(periodDataProvider(period)).whenData((d) => d.currentDocs);
});
