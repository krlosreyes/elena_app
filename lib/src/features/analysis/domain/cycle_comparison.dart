// SPEC-192.3a (2026-06-05): comparativa de "últimos N ciclos cerrados
// vs los N ciclos cerrados anteriores".
//
// Cumple METABOLIC_DAY_CONSTITUTION.md §1 — cero referencia al reloj.
// La "semana" se redefine como "7 ciclos cerrados", no como "7 días".
//
// Análogo a `PeriodComparison` (que sigue calendárico para charts
// retrospectivos del Analysis tab — excepción documentada en
// SPEC-192 §4). `CycleComparison` es la versión cycle-aware usada
// por `WeeklyCoachingCard`.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/analysis/domain/cycle_summary.dart';

/// Delta por pilar entre dos ventanas de ciclos cerrados.
///
/// Formato: (current promedio, previous promedio, delta absoluto).
/// `delta = current - previous`. Positivo = mejoró.
class CyclePillarDelta {
  final double current;
  final double previous;

  const CyclePillarDelta({
    required this.current,
    required this.previous,
  });

  /// Diferencia signed. Positivo = current > previous (mejora).
  double get delta => current - previous;

  /// True si la diferencia es despreciable (< epsilon).
  bool isStableWithin(double epsilon) => delta.abs() <= epsilon;
}

class CycleComparison {
  /// Cuántos ciclos cerrados hay en la ventana actual.
  final int currentCount;

  /// Cuántos ciclos cerrados hay en la ventana anterior.
  final int previousCount;

  /// IMR promedio.
  final CyclePillarDelta imrScore;

  /// Magnitudes promedio por pilar (0.0-1.0).
  final CyclePillarDelta fastingMagnitude;
  final CyclePillarDelta sleepQualityScore;
  final CyclePillarDelta hydrationMagnitude;
  final CyclePillarDelta exerciseMagnitude;
  final CyclePillarDelta nutritionMagnitude;

  /// Rango temporal de la ventana actual (informativo).
  /// Null si no hay ciclos en current.
  final DateTime? currentRangeStart;
  final DateTime? currentRangeEnd;

  const CycleComparison({
    required this.currentCount,
    required this.previousCount,
    required this.imrScore,
    required this.fastingMagnitude,
    required this.sleepQualityScore,
    required this.hydrationMagnitude,
    required this.exerciseMagnitude,
    required this.nutritionMagnitude,
    this.currentRangeStart,
    this.currentRangeEnd,
  });

  /// True si NO hay ningún ciclo en ninguna ventana — placeholder
  /// "aún no hay historial" para el widget.
  bool get isEmpty => currentCount == 0 && previousCount == 0;

  /// True si tenemos ambas ventanas con al menos 1 ciclo cada una.
  /// El widget puede renderizar la comparativa entera.
  bool get hasBothWindows => currentCount > 0 && previousCount > 0;

  /// Snapshot vacío. Útil para estados de carga.
  factory CycleComparison.empty() => const CycleComparison(
        currentCount: 0,
        previousCount: 0,
        imrScore: CyclePillarDelta(current: 0, previous: 0),
        fastingMagnitude: CyclePillarDelta(current: 0, previous: 0),
        sleepQualityScore: CyclePillarDelta(current: 0, previous: 0),
        hydrationMagnitude: CyclePillarDelta(current: 0, previous: 0),
        exerciseMagnitude: CyclePillarDelta(current: 0, previous: 0),
        nutritionMagnitude: CyclePillarDelta(current: 0, previous: 0),
      );

  /// Helper para tests/UI: lista los 5 deltas de pilares en orden canónico.
  List<({String label, CyclePillarDelta delta})> get pillarDeltas => [
        (label: 'Ayuno', delta: fastingMagnitude),
        (label: 'Sueño', delta: sleepQualityScore),
        (label: 'Hidratación', delta: hydrationMagnitude),
        (label: 'Ejercicio', delta: exerciseMagnitude),
        (label: 'Nutrición', delta: nutritionMagnitude),
      ];

  /// Compatibility helper: representa la duración temporal de la
  /// ventana actual como "rango". El widget legacy puede mostrarlo
  /// igual que `PeriodComparison` para no romper UI.
  Duration get currentDuration {
    final start = currentRangeStart;
    final end = currentRangeEnd;
    if (start == null || end == null) return Duration.zero;
    return end.difference(start);
  }
}

/// Servicio puro que computa una `CycleComparison` a partir de dos
/// listas de summaries (current + previous). Determinístico.
class CycleComparisonService {
  CycleComparisonService._();

  /// Construye la comparativa promediando los pilares de cada ventana.
  ///
  /// Si una ventana está vacía, los promedios de ESA ventana caen a 0
  /// y el delta queda en `current - 0`. El widget decide si renderizar
  /// con base en `hasBothWindows`.
  static CycleComparison compute({
    required List<CycleSummaryDoc> currentSummaries,
    required List<CycleSummaryDoc> previousSummaries,
  }) {
    if (currentSummaries.isEmpty && previousSummaries.isEmpty) {
      return CycleComparison.empty();
    }

    final cur = _averages(currentSummaries);
    final prev = _averages(previousSummaries);

    DateTime? rangeStart;
    DateTime? rangeEnd;
    if (currentSummaries.isNotEmpty) {
      // Las listas vienen ordenadas desc por closedAt (más reciente
      // primero) por el provider que las construyó.
      rangeEnd = currentSummaries.first.closedAt;
      rangeStart = currentSummaries.last.startedAt;
    }

    return CycleComparison(
      currentCount: currentSummaries.length,
      previousCount: previousSummaries.length,
      imrScore: CyclePillarDelta(
          current: cur.imr.toDouble(), previous: prev.imr.toDouble()),
      fastingMagnitude: CyclePillarDelta(
          current: cur.fasting, previous: prev.fasting),
      sleepQualityScore: CyclePillarDelta(
          current: cur.sleep, previous: prev.sleep),
      hydrationMagnitude: CyclePillarDelta(
          current: cur.hydration, previous: prev.hydration),
      exerciseMagnitude: CyclePillarDelta(
          current: cur.exercise, previous: prev.exercise),
      nutritionMagnitude: CyclePillarDelta(
          current: cur.nutrition, previous: prev.nutrition),
      currentRangeStart: rangeStart,
      currentRangeEnd: rangeEnd,
    );
  }

  static ({
    double imr,
    double fasting,
    double sleep,
    double hydration,
    double exercise,
    double nutrition,
  }) _averages(List<CycleSummaryDoc> docs) {
    if (docs.isEmpty) {
      return (
        imr: 0.0,
        fasting: 0.0,
        sleep: 0.0,
        hydration: 0.0,
        exercise: 0.0,
        nutrition: 0.0,
      );
    }
    final n = docs.length;
    return (
      imr: docs.fold<double>(0, (s, d) => s + d.imrScore) / n,
      fasting: docs.fold<double>(0, (s, d) => s + d.fastingMagnitude) / n,
      sleep: docs.fold<double>(0, (s, d) => s + d.sleepQualityScore) / n,
      hydration:
          docs.fold<double>(0, (s, d) => s + d.hydrationMagnitude) / n,
      exercise: docs.fold<double>(0, (s, d) => s + d.exerciseMagnitude) / n,
      nutrition:
          docs.fold<double>(0, (s, d) => s + d.nutritionMagnitude) / n,
    );
  }
}
