// SPEC-264: los 5 pilares de un día como "anillos" (estilo Apple Fitness).
//
// Se comparte el LOGRO (cerró el anillo o no), nunca el dato crudo: ni peso, ni
// calorías, ni horas exactas. Cada competidor publica los suyos; el tablero los
// muestra. Los pilares de Elena son binarios (cumplió/no), así que cada anillo
// es cerrado o vacío.

import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

class ChallengeRings {
  final bool ayuno;
  final bool ejercicio;
  final bool nutricion;
  final bool sueno;
  final bool hidratacion;

  const ChallengeRings({
    this.ayuno = false,
    this.ejercicio = false,
    this.nutricion = false,
    this.sueno = false,
    this.hidratacion = false,
  });

  static const ChallengeRings empty = ChallengeRings();

  /// Anillos del día a partir del registro real de pilares.
  factory ChallengeRings.fromEntry(StreakEntry e) => ChallengeRings(
        ayuno: e.fastingCompleted,
        ejercicio: e.exerciseLogged,
        nutricion: e.nutritionLogged,
        sueno: e.sleepCompleted,
        hidratacion: e.hydrationCompleted,
      );

  /// Anillos cerrados hoy (0-5). Es el puntaje del día en el reto.
  int get closedCount {
    var c = 0;
    if (ayuno) c++;
    if (ejercicio) c++;
    if (nutricion) c++;
    if (sueno) c++;
    if (hidratacion) c++;
    return c;
  }

  Map<String, dynamic> toMap() => {
        'ayuno': ayuno,
        'ejercicio': ejercicio,
        'nutricion': nutricion,
        'sueno': sueno,
        'hidratacion': hidratacion,
      };

  factory ChallengeRings.fromMap(Map<String, dynamic>? m) {
    if (m == null) return empty;
    return ChallengeRings(
      ayuno: m['ayuno'] as bool? ?? false,
      ejercicio: m['ejercicio'] as bool? ?? false,
      nutricion: m['nutricion'] as bool? ?? false,
      sueno: m['sueno'] as bool? ?? false,
      hidratacion: m['hidratacion'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeRings &&
          ayuno == other.ayuno &&
          ejercicio == other.ejercicio &&
          nutricion == other.nutricion &&
          sueno == other.sueno &&
          hidratacion == other.hidratacion;

  @override
  int get hashCode =>
      Object.hash(ayuno, ejercicio, nutricion, sueno, hidratacion);
}
