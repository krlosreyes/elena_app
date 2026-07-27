// SPEC-161: snapshot semanal de ejercicio + insight adaptativo.
//
// Pure Dart — sin Flutter ni Riverpod. Lo consume ExerciseWeeklyCard.

import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';

/// Tier del insight según % del target alcanzado en promedio semanal.
enum ExerciseInsightTier {
  empty,
  sedentary,    // <50% del target
  low,          // 50-80%
  meetsTarget,  // 80-120%
  aboveTarget,  // >120%
}

class ExerciseDayEntry {
  final DateTime date;

  /// Minutos totales registrados ese día.
  final int minutes;

  /// % vs target diario del usuario (1.0 = 100%).
  final double percentVsTarget;

  /// Tipo de ejercicio predominante del día (mayor duración).
  /// Null si los logs son legacy sin `type`.
  final ExerciseType? predominantType;

  const ExerciseDayEntry({
    required this.date,
    required this.minutes,
    required this.percentVsTarget,
    required this.predominantType,
  });
}

class ExerciseWeeklyBreakdown {
  /// Lista de días ordenada del más antiguo al más reciente. Solo
  /// días con al menos 1 log.
  final List<ExerciseDayEntry> days;

  /// Minutos promedio sobre los días con registros. 0 si no hay.
  final double minutesAvg;

  /// % promedio vs target diario del usuario (1.0 = 100%).
  final double percentAvg;

  /// Target diario en minutos del usuario.
  final int targetMinutesPerDay;

  /// Tier del insight.
  final ExerciseInsightTier tier;

  final DateTime rangeStart;
  final DateTime rangeEnd;

  const ExerciseWeeklyBreakdown({
    required this.days,
    required this.minutesAvg,
    required this.percentAvg,
    required this.targetMinutesPerDay,
    required this.tier,
    required this.rangeStart,
    required this.rangeEnd,
  });

  factory ExerciseWeeklyBreakdown.empty({
    required int targetMinutesPerDay,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return ExerciseWeeklyBreakdown(
      days: const [],
      minutesAvg: 0,
      percentAvg: 0,
      targetMinutesPerDay: targetMinutesPerDay,
      tier: ExerciseInsightTier.empty,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  bool get isEmpty => days.isEmpty;
}

/// Mensaje del coach por tier. Bibliografía: OMS 150 min/semana, AHA
/// 2018, Mattson 2017 (ejercicio + ayuno = sensibilidad insulínica).
class ExerciseCoachingMessage {
  final String headline;
  final String action;
  final String citation;

  const ExerciseCoachingMessage({
    required this.headline,
    required this.action,
    required this.citation,
  });

  static ExerciseCoachingMessage? forTier(ExerciseInsightTier tier) {
    switch (tier) {
      case ExerciseInsightTier.empty:
        return null;
      case ExerciseInsightTier.sedentary:
        return const ExerciseCoachingMessage(
          headline: 'Movimiento insuficiente. Tu insulina no se regula.',
          action:
              'Empieza con 20 min de caminata después de la comida más grande.',
          citation: 'OMS 150 min/sem + Mattson 2017',
        );
      case ExerciseInsightTier.low:
        return const ExerciseCoachingMessage(
          headline: 'Cerca pero corto. Te faltan minutos para el efecto metabólico.',
          action:
              'Suma 10 min al día. La OMS marca 150 min/semana como mínimo.',
          citation: 'OMS 2020 + AHA 2018',
        );
      case ExerciseInsightTier.meetsTarget:
        return const ExerciseCoachingMessage(
          headline: 'En target. Sostén el ritmo.',
          action:
              'Varía tipo: LISS + fuerza 2x/semana mejora sensibilidad a la insulina más que solo cardio.',
          citation: 'AHA 2018 + Mattson 2017',
        );
      case ExerciseInsightTier.aboveTarget:
        return const ExerciseCoachingMessage(
          headline: 'Volumen alto. Verificá recuperación.',
          action:
              'Asegurá ≥1 día de descanso completo y 7+ h de sueño para que el músculo repare.',
          citation: 'AHA 2018 + Walker 2017',
        );
    }
  }
}
