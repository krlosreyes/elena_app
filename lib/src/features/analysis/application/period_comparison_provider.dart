// SPEC-113: providers de la pantalla Análisis.
//
// PERF (post-SPEC-113): consolidación en `periodDataProvider`. Una
// sola suscripción Firestore al rango doble (período actual + previo
// juntos). Splitea client-side. Pasa de 2 streams Firestore por
// pantalla → 1.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/period_comparison_service.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_repository_impl.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_period.dart';
import 'package:elena_app/src/features/analysis/domain/period_comparison.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Helper: formato YYYY-MM-DD.
String _fmt(DateTime t) {
  final m = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '${t.year}-$m-$d';
}

/// Bundle con los docs del período actual + el comparison ya computado.
/// Empaquetar ambos en un solo provider evita que la pantalla haga 2
/// watches paralelos sobre la misma fuente de datos.
class PeriodData {
  final List<DailySummaryDoc> currentDocs;
  final PeriodComparison comparison;

  const PeriodData({
    required this.currentDocs,
    required this.comparison,
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
  final todayMidnight = DateTime(today.year, today.month, today.day);
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
    return PeriodData(currentDocs: currentDocs, comparison: comparison);
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
