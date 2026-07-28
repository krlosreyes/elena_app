// SPEC-161: motor puro del HydrationWeeklyCard.
//
// Agrupa logs por día calendárico, suma litros, calcula promedio y
// elige el tier del insight según % vs target.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/hydration/domain/hydration_log.dart';
import 'package:elena_app/src/features/hydration/domain/hydration_weekly_insight.dart';

class HydrationWeeklyComputer {
  HydrationWeeklyComputer._();

  /// Umbrales de tier (% del target alcanzado en promedio semanal).
  static const double kSeverelyLowMax = 0.60;
  static const double kLowMax = 0.80;
  static const double kAdequateMax = 1.00;

  /// `targetLitersPerDay`: meta diaria del usuario (35ml × kg típica).
  /// `rangeStart` / `rangeEnd`: rango a reportar en el header.
  static HydrationWeeklyBreakdown compute({
    required List<HydrationLog> logs,
    required double targetLitersPerDay,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (logs.isEmpty) {
      return HydrationWeeklyBreakdown.empty(
        targetLitersPerDay: targetLitersPerDay,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    }

    final byDay = <String, double>{};
    for (final log in logs) {
      final key = _dateKey(log.timestamp);
      byDay[key] = (byDay[key] ?? 0) + log.amountInLiters;
    }

    final entries = <HydrationDayEntry>[];
    byDay.forEach((dateKey, liters) {
      final date = _parseDateKey(dateKey);
      final pct = targetLitersPerDay > 0 ? liters / targetLitersPerDay : 0.0;
      entries.add(HydrationDayEntry(
        date: date,
        liters: liters,
        percentVsTarget: pct,
      ));
    });
    entries.sort((a, b) => a.date.compareTo(b.date));

    final litersAvg =
        entries.fold<double>(0, (sum, e) => sum + e.liters) / entries.length;
    final percentAvg =
        targetLitersPerDay > 0 ? litersAvg / targetLitersPerDay : 0.0;

    return HydrationWeeklyBreakdown(
      days: entries,
      litersAvg: litersAvg,
      percentAvg: percentAvg,
      targetLitersPerDay: targetLitersPerDay,
      tier: pickTier(percentAvg),
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  static HydrationInsightTier pickTier(double percentAvg) {
    if (percentAvg < kSeverelyLowMax) return HydrationInsightTier.severelyLow;
    if (percentAvg < kLowMax) return HydrationInsightTier.low;
    if (percentAvg < kAdequateMax) return HydrationInsightTier.adequate;
    return HydrationInsightTier.optimal;
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
