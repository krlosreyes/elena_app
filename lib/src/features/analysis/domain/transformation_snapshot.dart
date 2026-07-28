// SPEC-148 §RF-148-01 (2026-06-05): value objects de la comparativa
// 30 días.
//
// `TransformationDelta<T>` representa un indicador con dos puntos
// temporales — el "antes" (hace 30d) y el "ahora". El delta se
// calcula solo cuando ambos están presentes.
//
// `TransformationSnapshot` agrupa los 6 deltas que la card muestra y
// expone `visible` (los deltas computables) + `isEmpty` (ningún
// indicador tiene ambos puntos).
//
// Pure Dart — sin Flutter ni Riverpod. Testeable 100%.

/// Indicador en dos puntos temporales.
///
/// - `past` = valor del indicador en la ventana "hace 30 días"
///   (±5d, definido por `TransformationComputer`). Null si no hubo
///   medición en esa ventana.
/// - `current` = valor del último dato disponible (hasta 7 días atrás).
///   Null si nunca se midió.
/// - `delta` = `current - past`. Null si cualquiera de los dos lo es.
class TransformationDelta<T extends num> {
  final T? past;
  final T? current;
  final String label;
  final String unit;

  /// Cuántos días atrás fue medido `past` (informativo para sublabel
  /// "hace X días" cuando past está fuera de la ventana ideal de 30d).
  /// Null si past es null.
  final int? pastAgeDays;

  /// Cuántos días atrás fue medido `current` (típicamente 0-7). Null
  /// si current es null. Útil cuando current es de hace 5 días y la
  /// card quiere indicar "valor del lunes".
  final int? currentAgeDays;

  const TransformationDelta({
    required this.past,
    required this.current,
    required this.label,
    required this.unit,
    this.pastAgeDays,
    this.currentAgeDays,
  });

  /// Diferencia signed entre current y past. Null si cualquiera lo es.
  /// Tipado como `num` porque la sustracción int-int o double-double
  /// puede ser int o double según T.
  num? get delta {
    final p = past;
    final c = current;
    if (p == null || c == null) return null;
    return c - p;
  }

  /// True si tenemos ambos puntos y el delta se puede mostrar.
  bool get hasBoth => past != null && current != null;

  /// True si el delta es 0 dentro de un epsilon (útil para evitar
  /// pintar flechas direccionales cuando el cambio es despreciable).
  bool isStableWithin(num epsilon) {
    final d = delta;
    if (d == null) return false;
    return d.abs() <= epsilon;
  }

  /// Construye un delta vacío (ambos null). Útil para placeholders.
  factory TransformationDelta.empty({
    required String label,
    required String unit,
  }) {
    return TransformationDelta<T>(
      past: null,
      current: null,
      label: label,
      unit: unit,
    );
  }
}

/// Snapshot agrupando los indicadores que la `TransformationCard`
/// renderiza. El orden es el del SPEC §2.2.
///
/// SPEC-138 (2026-06-05): añadido `upfSharePct` — delta del % UPF
/// semanal vs el período anterior. Solo se computa cuando hay ≥14 días
/// con datos NOVA (decisión TransformationComputer; la métrica vino
/// con SPEC-138 que arrancó después de SPEC-148, por lo que el
/// histórico es nuevo).
class TransformationSnapshot {
  final TransformationDelta<double> weightKg;
  final TransformationDelta<int> imr;
  final TransformationDelta<double> waistCm;
  final TransformationDelta<double> bodyFatPct;
  final TransformationDelta<double> sleepHoursAvg;
  final TransformationDelta<int> fastingDaysOf7;

  /// SPEC-138 §16.4: porcentaje de slots NOVA 4 en la ventana semanal.
  /// `past` = % UPF en la ventana de 30 días atrás (±5d).
  /// `current` = % UPF de los últimos 7 días.
  ///
  /// Delta NEGATIVO = mejora (bajó el consumo de ultraprocesados),
  /// alineado con marco motivacional. El narrador solo cuenta mejoras
  /// — no narra empeoramientos para no estigmatizar.
  final TransformationDelta<int> upfSharePct;

  const TransformationSnapshot({
    required this.weightKg,
    required this.imr,
    required this.waistCm,
    required this.bodyFatPct,
    required this.sleepHoursAvg,
    required this.fastingDaysOf7,
    required this.upfSharePct,
  });

  /// Lista ordenada de los deltas en el orden de presentación.
  List<TransformationDelta> get all => [
        weightKg,
        imr,
        waistCm,
        bodyFatPct,
        sleepHoursAvg,
        fastingDaysOf7,
        upfSharePct,
      ];

  /// Deltas que tienen ambos puntos (se renderizan con delta visible).
  Iterable<TransformationDelta> get visible => all.where((d) => d.hasBoth);

  /// True si NINGÚN indicador tiene ambos puntos — la card no se
  /// renderiza y se muestra el placeholder cálido del SPEC §2.4.
  bool get isEmpty => !all.any((d) => d.hasBoth);

  /// Snapshot completamente vacío — placeholder para estados de carga
  /// y casos de usuario sin historial.
  factory TransformationSnapshot.empty() => TransformationSnapshot(
        weightKg: TransformationDelta.empty(label: 'Peso', unit: 'kg'),
        imr: TransformationDelta.empty(label: 'IMR', unit: ''),
        waistCm: TransformationDelta.empty(label: 'Cintura', unit: 'cm'),
        bodyFatPct: TransformationDelta.empty(label: '% Grasa', unit: '%'),
        sleepHoursAvg: TransformationDelta.empty(
          label: 'Sueño',
          unit: 'h prom',
        ),
        fastingDaysOf7: TransformationDelta.empty(
          label: 'Ayuno',
          unit: 'd/7',
        ),
        upfSharePct: TransformationDelta.empty(
          label: 'Ultraprocesado',
          unit: '%',
        ),
      );
}
