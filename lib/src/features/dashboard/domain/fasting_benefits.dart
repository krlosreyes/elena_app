// SPEC-101: helper puro que mapea fase de ayuno + duración a la lista
// de beneficios obtenidos hasta ese momento. Sin dependencias de
// Flutter — testeable 100%.
//
// El copy se deriva de docs/CIRCADIAN_BIBLIOGRAPHY.md §2 (cronología
// del ayuno con 6 fases). Cada cadena cita terminología clínica
// concreta para que la app refuerce el principio "desmitificar el
// vacío" del Metabolic Clock Blueprint §15 (Regla 2).

import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';

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
          'Iniciaste el bloqueo de insulina',
        ];

      case FastingPhase.postAbsorption:
        return const [
          'Niveles de insulina descendieron a basal',
          'Tu hígado está usando las reservas de glucógeno como combustible',
          'Eliminaste el pico glucémico postprandial',
        ];

      case FastingPhase.transition:
        return const [
          'Iniciaste la gluconeogénesis hepática',
          'Tu cuerpo cambió de combustible: ahora quema grasa, no glucosa',
          'Adrenalina y GH subieron — preservan masa muscular',
        ];

      case FastingPhase.fatBurning:
        return const [
          'Cetosis nutricional activa — produces cuerpos cetónicos',
          'Lipólisis sostenida: estás quemando grasa real',
          'Inflamación sistémica reducida',
          'Sensibilidad a la insulina mejorada',
        ];

      case FastingPhase.autophagy:
        return const [
          'Autofagia activa — tus células reciclan organelas dañadas',
          'IGF-1 a la baja: pausa de señales de crecimiento',
          'Renovación mitocondrial en curso',
        ];

      case FastingPhase.survival:
        return const [
          'Estado regenerativo profundo',
          'Renovación celular avanzada',
          'Mantén supervisión clínica activa',
        ];
    }
  }

  /// Etiqueta corta del estado metabólico actual (para mostrar al
  /// usuario en el diálogo). Equivale al "milestone" alcanzado.
  static String milestoneLabel(FastingPhase phase) {
    switch (phase) {
      case FastingPhase.none:
        return 'Bloqueo de insulina iniciado';
      case FastingPhase.postAbsorption:
        return 'Post-absorción';
      case FastingPhase.transition:
        return 'Cetogénesis temprana';
      case FastingPhase.fatBurning:
        return 'Quema de grasa activa';
      case FastingPhase.autophagy:
        return 'Autofagia activa';
      case FastingPhase.survival:
        return 'Regeneración profunda';
    }
  }
}
