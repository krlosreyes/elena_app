// SPEC-162: selector global del rango temporal del Análisis.
//
// Todos los widgets de la pantalla nueva (Resultados, Hábitos, Insights)
// reaccionan a este StateProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';

/// Default = 3 meses. Suficiente para detectar patrones sin abrumar.
final analysisRangeProvider =
    StateProvider<AnalysisRange>((_) => AnalysisRange.m3);

/// Fecha de inicio del rango actual (hoy menos N días). Null si "Todo".
final analysisRangeStartProvider = Provider<DateTime?>((ref) {
  final range = ref.watch(analysisRangeProvider);
  final days = range.daysFromToday;
  if (days == null) return null;
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: days));
});
