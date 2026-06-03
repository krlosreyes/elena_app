// SPEC-161: motor puro del ExerciseWeeklyCard.
//
// Agrupa logs por día, suma minutos, detecta tipo predominante y
// elige tier por % vs target.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_weekly_insight.dart';

class ExerciseWeeklyComputer {
  ExerciseWeeklyComputer._();

  /// Umbrales de tier (% del target alcanzado en promedio semanal).
  static const double kSedentaryMax = 0.50;
  static const double kLowMax = 0.80;
  static const double kMeetsTargetMax = 1.20;

  static ExerciseWeeklyBreakdown compute({
    required List<ExerciseLog> logs,
    required int targetMinutesPerDay,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (logs.isEmpty) {
      return ExerciseWeeklyBreakdown.empty(
        targetMinutesPerDay: targetMinutesPerDay,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    }

    // Agrupar por día: { dateKey: [logs del día] }.
    final byDay = <String, List<ExerciseLog>>{};
    for (final log in logs) {
      final key = _dateKey(log.timestamp);
      byDay.putIfAbsent(key, () => []).add(log);
    }

    final entries = <ExerciseDayEntry>[];
    byDay.forEach((dateKey, dayLogs) {
      final date = _parseDateKey(dateKey);
      final totalMinutes = dayLogs.fold<int>(
        0,
        (sum, l) => sum + l.durationMinutes,
      );
      final pct = targetMinutesPerDay > 0
          ? totalMinutes / targetMinutesPerDay
          : 0.0;
      entries.add(ExerciseDayEntry(
        date: date,
        minutes: totalMinutes,
        percentVsTarget: pct,
        predominantType: _pickPredominantType(dayLogs),
      ));
    });
    entries.sort((a, b) => a.date.compareTo(b.date));

    final minutesAvg =
        entries.fold<int>(0, (sum, e) => sum + e.minutes) / entries.length;
    final percentAvg = targetMinutesPerDay > 0
        ? minutesAvg / targetMinutesPerDay
        : 0.0;

    return ExerciseWeeklyBreakdown(
      days: entries,
      minutesAvg: minutesAvg,
      percentAvg: percentAvg,
      targetMinutesPerDay: targetMinutesPerDay,
      tier: pickTier(percentAvg),
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  static ExerciseInsightTier pickTier(double percentAvg) {
    if (percentAvg < kSedentaryMax) return ExerciseInsightTier.sedentary;
    if (percentAvg < kLowMax) return ExerciseInsightTier.low;
    if (percentAvg <= kMeetsTargetMax) return ExerciseInsightTier.meetsTarget;
    return ExerciseInsightTier.aboveTarget;
  }

  /// Tipo predominante del día: el que sumó más minutos. Null si
  /// ningún log tiene `type` (logs legacy puros).
  static ExerciseType? _pickPredominantType(List<ExerciseLog> logs) {
    final byType = <ExerciseType, int>{};
    for (final l in logs) {
      if (l.type != null) {
        byType[l.type!] = (byType[l.type!] ?? 0) + l.durationMinutes;
      }
    }
    if (byType.isEmpty) return null;
    return byType.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static DateTime _parseDateKey(String s) {
    final parts = s.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

/// Label corto para mostrar al lado de los minutos del día.
extension ExerciseTypeLabel on ExerciseType {
  String get shortLabel {
    switch (this) {
      case ExerciseType.liss:
        return 'LISS';
      case ExerciseType.hiit:
        return 'HIIT';
      case ExerciseType.strength:
        return 'Fuerza';
      case ExerciseType.mobility:
        return 'Movil.';
    }
  }
}
