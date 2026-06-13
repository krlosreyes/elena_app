// SPEC-162: selector global del rango temporal del Análisis.
//
// Todos los widgets de la pantalla nueva (Resultados, Hábitos, Insights)
// reaccionan a este StateProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';

/// Default = Mes (30 días). Rango de la pantalla principal Progreso.
/// Los detalles de cada pilar tienen su propio scope aislado (ProviderScope
/// override) para no contaminar este provider global.
final analysisRangeProvider =
    StateProvider<AnalysisRange>((_) => AnalysisRange.m1);

/// Fecha de inicio del rango actual (hoy menos N días).
final analysisRangeStartProvider = Provider<DateTime>((ref) {
  final range = ref.watch(analysisRangeProvider);
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: range.daysFromToday));
});
