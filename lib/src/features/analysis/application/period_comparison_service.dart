// SPEC-113: servicio puro que computa la comparación del período
// actual contra el anterior. Sin Riverpod ni Flutter.

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/domain/period_comparison.dart';

class PeriodComparisonService {
  PeriodComparisonService._();

  /// `currentDocs`: docs del período actual (puede tener ≤ daysInPeriod).
  /// `previousDocs`: docs del período inmediatamente anterior, mismo
  /// largo. Si está vacío, el promedio anterior queda null.
  static PeriodComparison compute({
    required List<DailySummaryDoc> currentDocs,
    required List<DailySummaryDoc> previousDocs,
    required int daysInPeriod,
  }) {
    if (currentDocs.isEmpty) {
      return PeriodComparison.empty(daysInPeriod);
    }

    // Promedio actual.
    final sumCurrent =
        currentDocs.fold<int>(0, (acc, d) => acc + d.imrScore);
    final avgCurrent = (sumCurrent / currentDocs.length).round();

    // Promedio previo (solo si hay docs).
    int? avgPrevious;
    if (previousDocs.isNotEmpty) {
      final sumPrev =
          previousDocs.fold<int>(0, (acc, d) => acc + d.imrScore);
      avgPrevious = (sumPrev / previousDocs.length).round();
    }

    // Mejor y peor día. En empate, gana el más reciente.
    DailySummaryDoc best = currentDocs.first;
    DailySummaryDoc worst = currentDocs.first;
    for (final d in currentDocs) {
      if (d.imrScore > best.imrScore ||
          (d.imrScore == best.imrScore &&
              _parseDate(d.date).isAfter(_parseDate(best.date)))) {
        best = d;
      }
      if (d.imrScore < worst.imrScore ||
          (d.imrScore == worst.imrScore &&
              _parseDate(d.date).isAfter(_parseDate(worst.date)))) {
        worst = d;
      }
    }

    return PeriodComparison(
      imrAverage: avgCurrent,
      imrAveragePrevious: avgPrevious,
      bestDayImr: best.imrScore,
      bestDayDate: _parseDate(best.date),
      worstDayImr: worst.imrScore,
      worstDayDate: _parseDate(worst.date),
      daysWithData: currentDocs.length,
      daysInPeriod: daysInPeriod,
    );
  }

  /// `YYYY-MM-DD` → DateTime. Defensivo ante malformaciones.
  static DateTime _parseDate(String s) {
    try {
      final parts = s.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
  }
}
