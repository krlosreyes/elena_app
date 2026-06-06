// SPEC-153: provider que alimenta el WeeklyCoachingCard.
//
// Consume `periodDataProvider(AnalysisPeriod.week)` que ya hace la query
// doble (current + previous). Sin suscripciones Firestore adicionales.
//
// ⚠️ SPEC-190 (2026-06-05) PARCIAL: este provider sigue consumiendo
// `DailySummaryDoc[]` por día calendárico (viola §1 de
// METABOLIC_DAY_CONSTITUTION.md). Migrar a "ciclos cerrados" requiere
// arquitectura nueva (`cycle_summary` collection o re-agrupación
// al vuelo de `metabolic_cycles`).
//
// TODO(SPEC-192): refactorizar para que consuma `last7ClosedCyclesProvider`
// y compute insights sobre `cycle.feedback.magnitudes` consolidadas.
// Razón del defer: SPEC-190 se enfoca en pilares Today (Tier 1) y
// providers de logs raw (Tier 2). La analytics retrospectiva queda
// para Tier 4. Ver `specs/SPEC-190-*.md` §3.4.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/analysis/application/period_comparison_provider.dart';
import 'package:elena_app/src/features/analysis/application/weekly_coaching_computer.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_period.dart';
import 'package:elena_app/src/features/analysis/domain/weekly_coaching_insight.dart';

/// AsyncValue del insight semanal. Loading mientras Firestore responde,
/// error si la query falla, data con el WeeklyCoachingInsight cuando
/// llegan los docs.
final weeklyCoachingProvider =
    Provider.autoDispose<AsyncValue<WeeklyCoachingInsight>>((ref) {
  final periodAsync = ref.watch(periodDataProvider(AnalysisPeriod.week));

  return periodAsync.whenData((data) {
    final today = DateTime.now();
    final todayMidnight = DayBoundaryResolver.startOfDay(today);
    final rangeEnd = todayMidnight;
    final rangeStart = todayMidnight.subtract(
      Duration(days: AnalysisPeriod.week.days - 1),
    );

    return WeeklyCoachingComputer.compute(
      current: data.currentDocs,
      previous: data.previousDocs,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  });
});
