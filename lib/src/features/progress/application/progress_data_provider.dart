import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../health/data/health_repository.dart';
import '../../health/domain/daily_log.dart';

/// Datos procesados para la pantalla de progreso.
class ProgressData {
  final List<DailyLog> logs;

  /// Promedio de imrScore en el período (solo días con score > 0).
  final double averageImr;

  /// Delta IMR: media esta semana − media semana anterior.
  /// null si no hay suficientes datos (< 2 días en alguna semana).
  final double? trendVsLastWeek;

  /// Días consecutivos (hasta hoy) con imrScore > 0.
  final int currentStreak;

  /// Máximo de horas de ayuno registrado en el período.
  final int bestFastingHours;

  /// Top 3 días con mayor imrScore.
  final List<DailyLog> topDays;

  const ProgressData({
    required this.logs,
    required this.averageImr,
    required this.trendVsLastWeek,
    required this.currentStreak,
    required this.bestFastingHours,
    required this.topDays,
  });

  factory ProgressData.fromLogs(List<DailyLog> logs) {
    // ── Promedio IMR (solo días activos) ──────────────────────────────────
    final activeLogs = logs.where((l) => l.imrScore > 0).toList();
    final averageImr = activeLogs.isEmpty
        ? 0.0
        : activeLogs.map((l) => l.imrScore).reduce((a, b) => a + b) /
            activeLogs.length;

    // ── Tendencia vs semana anterior ─────────────────────────────────────
    final now = DateTime.now();
    final todayId = DateFormat('yyyy-MM-dd').format(now);
    final weekAgoId =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 7)));
    final twoWeeksAgoId =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 14)));

    final thisWeek = activeLogs
        .where((l) =>
            l.id.compareTo(weekAgoId) >= 0 && l.id.compareTo(todayId) <= 0)
        .toList();
    final lastWeek = activeLogs
        .where((l) =>
            l.id.compareTo(twoWeeksAgoId) >= 0 && l.id.compareTo(weekAgoId) < 0)
        .toList();

    double? trendVsLastWeek;
    if (thisWeek.length >= 2 && lastWeek.length >= 2) {
      final avgThis = thisWeek.map((l) => l.imrScore).reduce((a, b) => a + b) /
          thisWeek.length;
      final avgLast = lastWeek.map((l) => l.imrScore).reduce((a, b) => a + b) /
          lastWeek.length;
      trendVsLastWeek = avgThis - avgLast;
    }

    // ── Racha actual ─────────────────────────────────────────────────────
    int currentStreak = 0;
    final sortedDesc = [...logs]..sort((a, b) => b.id.compareTo(a.id));
    for (int i = 0; i < sortedDesc.length; i++) {
      final expectedDate = now.subtract(Duration(days: i));
      final expectedId = DateFormat('yyyy-MM-dd').format(expectedDate);
      if (i < sortedDesc.length &&
          sortedDesc[i].id == expectedId &&
          sortedDesc[i].imrScore > 0) {
        currentStreak++;
      } else {
        break;
      }
    }

    // ── Mejor ayuno ──────────────────────────────────────────────────────
    int bestFastingHours = 0;
    for (final log in logs) {
      if (log.fastingStartTime != null && log.fastingEndTime != null) {
        final hours =
            log.fastingEndTime!.difference(log.fastingStartTime!).inHours;
        if (hours > bestFastingHours) bestFastingHours = hours;
      }
    }

    // ── Top 3 días ───────────────────────────────────────────────────────
    final sorted = [...activeLogs]
      ..sort((a, b) => b.imrScore.compareTo(a.imrScore));
    final topDays = sorted.take(3).toList();

    return ProgressData(
      logs: logs,
      averageImr: averageImr,
      trendVsLastWeek: trendVsLastWeek,
      currentStreak: currentStreak,
      bestFastingHours: bestFastingHours,
      topDays: topDays,
    );
  }
}

/// Expone los datos procesados para la pantalla de progreso (30 días).
final progressDataProvider =
    FutureProvider.autoDispose.family<ProgressData, String>((ref, uid) async {
  final logs =
      await ref.read(healthRepositoryProvider).fetchRecentLogs(uid, days: 30);
  return ProgressData.fromLogs(logs);
});
