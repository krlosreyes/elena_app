// SPEC-304 — Cómo cada etapa del sueño afecta el METABOLISMO, con base
// científica verificable (regla del proyecto: fundamentos citables).
//
// Fuentes:
//  - Profundo (ondas lentas) ↔ hormona de crecimiento + sensibilidad a la
//    insulina: Tasali et al., PNAS 2008 — suprimir el sueño profundo 3 noches
//    (sin reducir el total) bajó la sensibilidad a la insulina ~25%.
//  - REM ↔ regulación de apetito (leptina/grelina): Spiegel et al., Ann Intern
//    Med 2004 — la falta de sueño baja leptina (saciedad) y sube grelina
//    (hambre); el REM correlaciona con la leptina.
//  - Fragmentación (despertares) ↔ insulina + cortisol: Stamatakis & Punjabi,
//    Chest 2010 — fragmentar el sueño 2 noches bajó la sensibilidad a la
//    insulina y subió el cortisol matutino.
//
// Pure Dart.

import 'package:flutter/material.dart';

enum SleepStageKind { deep, rem, light, awake }

class SleepStageScience {
  final String label;
  final Color color;

  /// Una línea de qué es la etapa.
  final String what;

  /// Cómo impacta el metabolismo (positivo o a cuidar).
  final String metabolicImpact;

  /// Cita verificable (autor, año, publicación).
  final String citation;

  const SleepStageScience({
    required this.label,
    required this.color,
    required this.what,
    required this.metabolicImpact,
    required this.citation,
  });

  static const deep = SleepStageScience(
    label: 'Profundo',
    color: Color(0xFF4338CA),
    what: 'Ondas lentas: la fase más reparadora de la noche.',
    metabolicImpact:
        'Concentra la hormona de crecimiento y restaura tu sensibilidad a la '
        'insulina. Es la etapa que más cuida tu metabolismo.',
    citation: 'Tasali et al., PNAS 2008',
  );

  static const rem = SleepStageScience(
    label: 'REM',
    color: Color(0xFF7C3AED),
    what: 'Sueño de los sueños: consolida memoria y regula emociones.',
    metabolicImpact:
        'Ayuda a equilibrar las hormonas del apetito (leptina y grelina): '
        'poco REM se asocia a más hambre al día siguiente.',
    citation: 'Spiegel et al., Ann Intern Med 2004',
  );

  static const light = SleepStageScience(
    label: 'Ligero',
    color: Color(0xFF818CF8),
    what: 'La mayor parte de la noche: transición y descanso.',
    metabolicImpact:
        'Es normal que sea la fracción más grande. Sirve de puente hacia el '
        'profundo y el REM, donde ocurre la reparación metabólica.',
    citation: 'Carskadon & Dement, 2011',
  );

  static const awake = SleepStageScience(
    label: 'Despierto',
    color: Color(0xFF64748B),
    what: 'Despertares breves dentro de tu ventana de sueño.',
    metabolicImpact:
        'Un poco es normal. Muchos despertares (fragmentación) suben el '
        'cortisol matutino y bajan la sensibilidad a la insulina.',
    citation: 'Stamatakis & Punjabi, Chest 2010',
  );

  static SleepStageScience of(SleepStageKind k) => switch (k) {
        SleepStageKind.deep => deep,
        SleepStageKind.rem => rem,
        SleepStageKind.light => light,
        SleepStageKind.awake => awake,
      };
}
