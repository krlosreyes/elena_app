// SPEC-200: sección "Score del Día" en Análisis — seguimiento día a día del
// puntaje diario (HOY, 0-100), con promedio y mejor/peor. Distinto del IMR
// longitudinal: este es el número grande del dashboard que llega a 100.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/domain/score_trend_point.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_trend_chart.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';

class DailyScoreTrendSection extends ConsumerWidget {
  const DailyScoreTrendSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(dailyScoreTrendProvider);
    // Sin historial todavía → no mostramos la sección (evita ruido vacío).
    if (points.isEmpty) return const SizedBox.shrink();

    final daysInPeriod = _spanDaysInclusive(points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Score del día',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
        ),
        ImrTrendChart.fromPoints(
          points: points,
          daysInPeriod: daysInPeriod,
          title: 'SCORE DEL DÍA · DÍA A DÍA',
        ),
      ],
    );
  }

  /// Días desde el punto más antiguo hasta hoy (inclusive). Mín 7, máx 31.
  static int _spanDaysInclusive(List<ScoreTrendPoint> points) {
    DateTime? earliest;
    for (final p in points) {
      final parts = p.date.split('-');
      if (parts.length != 3) continue;
      final dt = DateTime(
        int.tryParse(parts[0]) ?? 2000,
        int.tryParse(parts[1]) ?? 1,
        int.tryParse(parts[2]) ?? 1,
      );
      if (earliest == null || dt.isBefore(earliest)) earliest = dt;
    }
    if (earliest == null) return 7;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final span = today.difference(earliest).inDays + 1;
    return span.clamp(7, 31);
  }
}
