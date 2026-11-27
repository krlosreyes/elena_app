// SPEC-101: helper puro que mapea fase de ayuno + duración a la lista
// de beneficios obtenidos hasta ese momento. Sin dependencias de
// Flutter — testeable 100%.
//
// El copy se deriva de docs/CIRCADIAN_BIBLIOGRAPHY.md §2 (cronología
// del ayuno con 6 fases). Cada cadena cita terminología clínica
// concreta para que la app refuerce el principio "desmitificar el
// vacío" del Metabolic Clock Blueprint §15 (Regla 2).

import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';

class FastingBenefits {
  FastingBenefits._();

  /// Lista de beneficios concretos que el usuario obtuvo según la
  /// `phase` y `duration` actuales del ayuno. Devuelve al menos un
  /// item — siempre hay algo que reconocer.
  static List<String> benefitsFor(FastingPhase phase, Duration duration) {
    switch (phase) {
      case FastingPhase.none:
        // Ayuno apenas iniciado. Reconocemos el cambio aunque sea mínimo.
        return const [
          'Empezó tu ayuno: la insulina empieza a bajar',
        ];

      case FastingPhase.postAbsorption:
        return const [
          'La insulina va bajando hacia su nivel de reposo',
          'Tu hígado usa sus reservas de glucógeno',
          'No hubo nuevos picos de glucosa por comida',
        ];

      case FastingPhase.transition:
        return const [
          'Tu cuerpo empieza a usar más grasa como energía',
          'El cambio es gradual: glucosa y grasa se combinan',
          'La hormona de crecimiento tiende a subir en ayunas',
        ];

      case FastingPhase.fatBurning:
        return const [
          'Es probable que estés produciendo cuerpos cetónicos',
          'La grasa es ya una fuente principal de energía',
          'Ayunos así, repetidos, se asocian a mejor sensibilidad a la insulina',
        ];

      case FastingPhase.autophagy:
        return const [
          'Ayuno prolongado: en estudios se asocia a más autofagia',
          'En personas no hay una hora exacta en que empiece',
          'Hidrátate y escucha a tu cuerpo',
        ];

      case FastingPhase.survival:
        return const [
          'Ayuno muy prolongado',
          'Hazlo solo con supervisión médica',
          'Si te sientes mal, rompe el ayuno',
        ];
    }
  }

  /// Etiqueta corta del estado metabólico actual (para mostrar al
  /// usuario en el diálogo). Equivale al "milestone" alcanzado.
  static String milestoneLabel(FastingPhase phase) {
    switch (phase) {
      case FastingPhase.none:
        return 'Ayuno iniciado';
      case FastingPhase.postAbsorption:
        return 'Post-absorción';
      case FastingPhase.transition:
        return 'Transición a grasa';
      case FastingPhase.fatBurning:
        return 'Más grasa como energía';
      case FastingPhase.autophagy:
        return 'Ayuno prolongado';
      case FastingPhase.survival:
        return 'Ayuno muy prolongado';
    }
  }
}
