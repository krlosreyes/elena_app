// SPEC-162: selector global del rango temporal del Análisis.
//
// Todos los widgets de la pantalla nueva (Resultados, Hábitos, Insights)
// reaccionan a este StateProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';

/// SPEC-168.5.5 (2026-06-03): default = 30 días. Carlos pidió rango
/// más corto por defecto para que la lectura sea más cercana al
/// presente y los buckets diarios (no semanales) sean más legibles.
/// El usuario puede ampliar a 3M/6M/A desde el SegmentedRangeControl.
final analysisRangeProvider =
    StateProvider<AnalysisRange>((_) => AnalysisRange.d30);

/// Fecha de inicio del rango actual (hoy menos N días). Null si "Todo".
final analysisRangeStartProvider = Provider<DateTime?>((ref) {
  final range = ref.watch(analysisRangeProvider);
  final days = range.daysFromToday;
  if (days == null) return null;
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: days));
});
