// SPEC-296 — "Cómo te beneficia" por tipo de actividad (educativo, opción A).
// Texto corto y honesto por categoría ACSM. Sin números del score (eso es
// una mejora futura, opción B).

import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';

class ExerciseBenefit {
  const ExerciseBenefit._();

  /// Beneficio principal del tipo de actividad, en una frase.
  static String forType(ExerciseType? type) {
    switch (type) {
      case ExerciseType.strength:
        return 'Preserva y construye músculo, sube tu metabolismo basal y '
            'mejora tu sensibilidad a la insulina.';
      case ExerciseType.hiit:
        return 'Dispara el gasto calórico y mejora tu capacidad '
            'cardiovascular en poco tiempo.';
      case ExerciseType.liss:
        return 'Activa el gasto calórico suave, mejora la circulación y '
            'ayuda a ordenar tu ritmo circadiano.';
      case ExerciseType.mobility:
        return 'Cuida articulaciones y postura, baja el estrés y mejora tu '
            'recuperación.';
      case null:
        return 'Moverte hoy suma a tu energía, tu metabolismo y tu descanso.';
    }
  }

  /// Emoji representativo del tipo (para el ícono de la tarjeta).
  static String emojiFor(ExerciseType? type) {
    switch (type) {
      case ExerciseType.strength:
        return '🏋️';
      case ExerciseType.hiit:
        return '🔥';
      case ExerciseType.liss:
        return '🚶';
      case ExerciseType.mobility:
        return '🧘';
      case null:
        return '🏃';
    }
  }
}
