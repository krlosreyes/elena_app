// Fix números (2026-10-30): "Tu semana" = los últimos 7 días del calendario.
//
// Antes, el boletín semanal tomaba "los últimos 7 ciclos cerrados" sin mirar
// la fecha. Un usuario que registró poco veía "TU SEMANA · AGO 21 – OCT 1":
// una "semana" de seis semanas, con datos viejos. Ahora la ventana actual son
// los 7 días que terminan hoy y la anterior, los 7 días previos.
//
// Todo lo de este archivo es puro (sin Riverpod ni Firestore) salvo
// `weeklyPillarDaysProvider`, para poder testearlo directo.

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/cycle_summary_computer.dart';
import 'package:elena_app/src/features/analysis/domain/cycle_summary.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

/// Días que abarca la ventana semanal.
const int kWeeklyWindowDays = 7;

/// Un pilar cuenta como "cumplido" ese día si su magnitud llega a este valor.
/// Es el mismo umbral que `WeeklyCoachingComputer.kSustainedThreshold`.
const double kPillarDayMetThreshold = 0.80;

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Primer día (inclusivo, a medianoche local) de la ventana actual.
DateTime weeklyWindowStart(DateTime now) =>
    _startOfDay(now).subtract(const Duration(days: kWeeklyWindowDays - 1));

/// Último día (inclusivo) de la ventana actual: hoy.
DateTime weeklyWindowEnd(DateTime now) => _startOfDay(now);

/// Separa los ciclos cerrados en la ventana actual (últimos 7 días, hoy
/// incluido) y la anterior (los 7 días previos). Lo que es más viejo se
/// descarta. Un ciclo pertenece al día en que se CERRÓ.
({List<MetabolicCycle> current, List<MetabolicCycle> previous})
    splitCyclesByWeeklyWindow(List<MetabolicCycle> cycles, DateTime now) {
  final currentStart = weeklyWindowStart(now);
  final previousStart =
      currentStart.subtract(const Duration(days: kWeeklyWindowDays));
  final current = <MetabolicCycle>[];
  final previous = <MetabolicCycle>[];
  for (final c in cycles) {
    final closedAt = c.closedAt?.toLocal();
    if (closedAt == null) continue;
    if (!closedAt.isBefore(currentStart)) {
      current.add(c);
    } else if (!closedAt.isBefore(previousStart)) {
      previous.add(c);
    }
  }
  return (current: current, previous: previous);
}

/// Cuántos de los últimos 7 días cumplió cada pilar.
class WeeklyPillarDays {
  final int fasting;
  final int sleep;
  final int hydration;
  final int exercise;
  final int nutrition;

  const WeeklyPillarDays({
    required this.fasting,
    required this.sleep,
    required this.hydration,
    required this.exercise,
    required this.nutrition,
  });

  static const empty = WeeklyPillarDays(
    fasting: 0,
    sleep: 0,
    hydration: 0,
    exercise: 0,
    nutrition: 0,
  );
}

/// Cuenta, por pilar, los DÍAS distintos de la ventana en los que algún ciclo
/// cerrado ese día alcanzó [kPillarDayMetThreshold]. Nunca pasa de 7, aunque
/// el usuario cierre dos ciclos el mismo día.
WeeklyPillarDays computeWeeklyPillarDays(
  List<CycleSummaryDoc> summaries,
  DateTime now,
) {
  final start = weeklyWindowStart(now);
  int countDays(double Function(CycleSummaryDoc s) magnitude) {
    final days = <DateTime>{};
    for (final s in summaries) {
      final day = _startOfDay(s.closedAt.toLocal());
      if (day.isBefore(start)) continue;
      if (magnitude(s) >= kPillarDayMetThreshold) days.add(day);
    }
    return math.min(days.length, kWeeklyWindowDays);
  }

  return WeeklyPillarDays(
    fasting: countDays((s) => s.fastingMagnitude),
    sleep: countDays((s) => s.sleepQualityScore),
    hydration: countDays((s) => s.hydrationMagnitude),
    exercise: countDays((s) => s.exerciseMagnitude),
    nutrition: countDays((s) => s.nutritionMagnitude),
  );
}

/// "X de 7 días" por pilar para el boletín "Tu semana" del tab Progreso.
final weeklyPillarDaysProvider =
    Provider.autoDispose<AsyncValue<WeeklyPillarDays>>((ref) {
  final cyclesAsync = ref.watch(last14ClosedCyclesProvider);
  return cyclesAsync.whenData((all) {
    final now = DateTime.now();
    final current = splitCyclesByWeeklyWindow(all, now).current;
    return computeWeeklyPillarDays(
      CycleSummaryComputer.fromCycles(current),
      now,
    );
  });
});
