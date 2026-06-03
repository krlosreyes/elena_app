// SPEC-153: dominio del WeeklyCoachingCard.
//
// Encapsula el resultado del análisis semanal de pilares + el insight
// adaptativo que se muestra al usuario.
//
// Pure Dart — sin Flutter ni Riverpod. Testeable 100%.

/// Pilar que el algoritmo identifica como el que más arrastra esta
/// semana. Cada uno trae su pool fijo de insight + acción + cita,
/// alineado con la bibliografía operacional del proyecto (misma que
/// `CycleClosureCard` de SPEC-149).
enum WeakPillar {
  fasting,
  sleep,
  hydration,
  exercise,
  meals;

  /// Label visible en el insight.
  String get label {
    switch (this) {
      case WeakPillar.fasting:
        return 'ayuno';
      case WeakPillar.sleep:
        return 'sueño';
      case WeakPillar.hydration:
        return 'hidratación';
      case WeakPillar.exercise:
        return 'ejercicio';
      case WeakPillar.meals:
        return 'adherencia a la ventana';
    }
  }

  /// Headline del insight. Empieza siempre con "Tu …" para tono coach.
  String get insightHeadline {
    switch (this) {
      case WeakPillar.fasting:
        return 'Tu ayuno está corto. La autofagia profunda requiere ≥16h.';
      case WeakPillar.sleep:
        return 'Tu sueño es el que más arrastra. <7h compromete tu reparación metabólica.';
      case WeakPillar.hydration:
        return 'Tu hidratación está bajo el target. 35ml/kg es la base mínima.';
      case WeakPillar.exercise:
        return 'Tu ejercicio está bajo. Sin movimiento, la insulina no se regula bien.';
      case WeakPillar.meals:
        return 'Tu adherencia a la ventana cayó. Cerrar tarde rompe el ritmo circadiano.';
    }
  }

  /// Acción concreta para resolver el pilar débil. Una sola cosa
  /// accionable — no un menú.
  String get suggestedAction {
    switch (this) {
      case WeakPillar.fasting:
        return 'Marcá el inicio del próximo ayuno entre 19:00 y 21:00.';
      case WeakPillar.sleep:
        return 'Apuntá a apagar pantallas 1h antes de tu hora objetivo de dormir.';
      case WeakPillar.hydration:
        return 'Bebé un vaso de agua cada 90 min hasta las 21:00.';
      case WeakPillar.exercise:
        return 'Sumá 20 min de caminata después de la comida más grande.';
      case WeakPillar.meals:
        return 'Cerrá tu ventana de comida antes de las 21:00.';
    }
  }

  /// Cita científica. Misma bibliografía que `CycleFeedbackGenerator`
  /// para consistencia narrativa across coaching surfaces.
  String get citation {
    switch (this) {
      case WeakPillar.fasting:
        return 'Mattson 2017 + Sutton 2018';
      case WeakPillar.sleep:
        return 'Walker 2017 + AASM';
      case WeakPillar.hydration:
        return 'EFSA 2010 + Popkin 2010';
      case WeakPillar.exercise:
        return 'AHA 2018 + Mattson 2017';
      case WeakPillar.meals:
        return 'Lopez-Minguez 2018';
    }
  }
}

/// Snapshot del análisis semanal. Lo consume `WeeklyCoachingCard`.
class WeeklyCoachingInsight {
  /// Promedio actual de cada pilar (0.0..1.0). 0 si no hay docs.
  final double fastingAvg;
  final double sleepAvg;
  final double hydrationAvg;
  final double exerciseAvg;
  final double mealsAvg;

  /// Delta vs el período anterior (-1.0..+1.0). Null si no había
  /// período anterior con docs (usuario nuevo).
  final double? fastingDelta;
  final double? sleepDelta;
  final double? hydrationDelta;
  final double? exerciseDelta;
  final double? mealsDelta;

  /// Pilar más débil de la semana. Null si todos están bien (≥80%) o
  /// si no hay docs (caso empty).
  final WeakPillar? weakest;

  /// Total de días con data en la ventana actual.
  final int daysWithData;

  /// Fecha de inicio del rango (inclusivo) para mostrar el header.
  final DateTime rangeStart;

  /// Fecha de fin del rango (inclusivo).
  final DateTime rangeEnd;

  const WeeklyCoachingInsight({
    required this.fastingAvg,
    required this.sleepAvg,
    required this.hydrationAvg,
    required this.exerciseAvg,
    required this.mealsAvg,
    required this.fastingDelta,
    required this.sleepDelta,
    required this.hydrationDelta,
    required this.exerciseDelta,
    required this.mealsDelta,
    required this.weakest,
    required this.daysWithData,
    required this.rangeStart,
    required this.rangeEnd,
  });

  /// Estado vacío — sin docs en el período actual.
  factory WeeklyCoachingInsight.empty({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return WeeklyCoachingInsight(
      fastingAvg: 0,
      sleepAvg: 0,
      hydrationAvg: 0,
      exerciseAvg: 0,
      mealsAvg: 0,
      fastingDelta: null,
      sleepDelta: null,
      hydrationDelta: null,
      exerciseDelta: null,
      mealsDelta: null,
      weakest: null,
      daysWithData: 0,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  /// True si no hay data útil para mostrar (empty state).
  bool get isEmpty => daysWithData == 0;

  /// True si todos los pilares ≥80% — mensaje motivacional sin acción.
  bool get isFullySustained =>
      !isEmpty &&
      weakest == null &&
      fastingAvg >= 0.80 &&
      sleepAvg >= 0.80 &&
      hydrationAvg >= 0.80 &&
      exerciseAvg >= 0.80 &&
      mealsAvg >= 0.80;
}
