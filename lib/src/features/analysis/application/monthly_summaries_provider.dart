// SPEC-112: provider derivado que dado un (year, month) devuelve un
// stream de los DailySummaryDoc del mes. Reutiliza
// `historicSummariesProvider` mapeando el rango al primer y último día
// del mes solicitado.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/historic_summaries_provider.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';

/// Identifica un mes calendario. Se usa como key del `.family` para
/// que Riverpod cachee por mes.
class MonthKey {
  final int year;
  final int month;

  const MonthKey({required this.year, required this.month});

  /// Mes actual (now).
  factory MonthKey.now() {
    final n = DateTime.now();
    return MonthKey(year: n.year, month: n.month);
  }

  /// Mes anterior, ajustando año si se cruza enero.
  MonthKey previous() {
    if (month == 1) return MonthKey(year: year - 1, month: 12);
    return MonthKey(year: year, month: month - 1);
  }

  /// Mes siguiente, ajustando año si se cruza diciembre.
  MonthKey next() {
    if (month == 12) return MonthKey(year: year + 1, month: 1);
    return MonthKey(year: year, month: month + 1);
  }

  /// Primer día del mes.
  DateTime firstDay() => DateTime(year, month, 1);

  /// Último día del mes (día 0 del mes siguiente = último del actual).
  DateTime lastDay() => DateTime(year, month + 1, 0);

  /// Cantidad de días del mes.
  int daysInMonth() => lastDay().day;

  /// Clave string `YYYY-MM-DD` del primer día.
  String fromDateKey() {
    final m = month.toString().padLeft(2, '0');
    return '$year-$m-01';
  }

  /// Clave string `YYYY-MM-DD` del último día.
  String toDateKey() {
    final m = month.toString().padLeft(2, '0');
    final d = daysInMonth().toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  @override
  bool operator ==(Object other) =>
      other is MonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

/// Stream de los docs persistidos del mes. Wrapper de
/// `historicSummariesProvider` que construye el rango correcto.
final monthlySummariesProvider =
    StreamProvider.family<List<DailySummaryDoc>, MonthKey>((ref, month) {
  final range = HistoricSummariesRange(
    fromIncl: month.fromDateKey(),
    toIncl: month.toDateKey(),
  );
  return ref.watch(historicSummariesProvider(range).stream);
});
