// SPEC-17: Reencuadre de Pilares Funcionales
//
// Fuente única de verdad para el vocabulario de pilares en toda la app.
// Los nombres funcionales comunican el MECANISMO científico (el por qué),
// no solo el comportamiento que se registra (el qué).
//
// RF-17-02: Las dimensiones de tracking internas (ayuno, ejercicio, nutrición,
// sueño, hidratación) NO cambian. Solo cambia el lenguaje visible al usuario.
//
// Refs científicas:
//   Longo VD & Panda S (2016). Fasting, Circadian Rhythms, and TRE. Cell Metab.
//   Wolfe RR (2006). The underappreciated role of muscle in health. Am J Clin Nutr.
//   Crofts C et al. (2015). Understanding insulin resistance. J Insulin Resistance.

import 'package:flutter/material.dart';

abstract class PillarConstants {
  const PillarConstants._();

  // ── Nombres funcionales ──────────────────────────────────────────────────────
  // Cada constante es el label visible al usuario en UI, tooltips y reportes.

  /// Ayuno intermitente y ritmo circadiano del ayuno.
  /// Tracking interno: FastingNotifier, FastingInterval
  static const String pilarAyuno = 'Ayuno Consciente';

  /// Preservación y ganancia de masa muscular — predictor de longevidad metabólica.
  /// Tracking interno: ExerciseNotifier, ExerciseLog
  static const String pilarEjercicio = 'Sarcopenia & Resistencia';

  /// Calidad de macronutrientes e índice insulínico de los alimentos.
  /// Tracking interno: NutritionNotifier, NutritionLog
  static const String pilarNutricion = 'Nutrición Científica';

  /// Sueño + hidratación como pilares de recuperación y regulación hormonal.
  /// Tracking interno: SleepNotifier, HydrationNotifier
  static const String pilarSoporte = 'Soporte Metabólico';

  /// Timing de comidas y ventana circadiana como regulador central del metabolismo.
  /// Tracking interno: NutritionNotifier, circadianAlignment (IMR engine)
  /// Nota: concepto transversal — no tiene fila de tracking propia; se integra
  /// en la alineación circadiana del bloque Comportamiento del IMR.
  static const String pilarInsulina = 'Gestión de Insulina';

  // ── Etiquetas de dimensión de tracking (para UI compacta) ────────────────────
  // Cuando un pilar funcional agrupa varias dimensiones (Soporte Metabólico),
  // estas etiquetas identifican la métrica específica en filas de resumen.

  static const String trackingLabelSueno       = 'Sueño';
  static const String trackingLabelHidratacion = 'Hidratación';

  // ── Descripciones científicas breves (1-2 oraciones) ─────────────────────────
  // RF-17-04: DEBE incluir una definición científica breve visible en la UI.

  static const Map<String, String> descriptions = {
    pilarAyuno:
        'El ayuno activa la lipólisis visceral a partir de las 14-16 horas, '
        'cuando el glucógeno hepático se agota y el cuerpo cambia de fuente '
        'energética. La consistencia semanal produce adaptaciones metabólicas '
        'que duran días después del ayuno.',

    pilarEjercicio:
        'La masa muscular es el predictor más fuerte de longevidad metabólica '
        '(Wolfe, 2006). El entrenamiento de resistencia activa AMPK y mejora '
        'la sensibilidad a la insulina durante 24-48 horas post-esfuerzo.',

    pilarNutricion:
        'La calidad de los macronutrientes y el índice insulínico de los '
        'alimentos determinan la carga glucémica real de cada comida. '
        'Comer dentro de la ventana circadiana potencia el efecto del ayuno.',

    pilarSoporte:
        'El sueño regula cortisol, grelina y leptina — hormonas que controlan '
        'el hambre, el estrés y la recuperación muscular. La hidratación '
        'adecuada transporta cetonas y optimiza la función metabólica celular.',

    pilarInsulina:
        'La insulina es el regulador central del metabolismo de grasa '
        '(Crofts et al., 2015). Concentrar las comidas en la primera mitad '
        'del día, alineadas con el ritmo circadiano, minimiza los picos '
        'insulínicos y potencia la quema de grasa durante el ayuno nocturno.',
  };

  // ── Colores por pilar ─────────────────────────────────────────────────────────

  static const Map<String, Color> colors = {
    pilarAyuno:     Color(0xFF10B981),  // verde esmeralda
    pilarEjercicio: Color(0xFF2DD4BF),  // teal
    pilarNutricion: Color(0xFFFB923C),  // naranja
    pilarSoporte:   Color(0xFF818CF8),  // índigo
    pilarInsulina:  Color(0xFFF59E0B),  // ámbar
  };

  // ── Emojis por pilar ──────────────────────────────────────────────────────────

  static const Map<String, String> emojis = {
    pilarAyuno:     '⏱️',
    pilarEjercicio: '💪',
    pilarNutricion: '🥦',
    pilarSoporte:   '🌙',
    pilarInsulina:  '⚡',
  };

  // ── Mapping funcional → dimensiones de tracking ───────────────────────────────
  // RF-17-03: Permite a cualquier feature consultar a qué pilar funcional
  // pertenece una dimensión de tracking, sin hardcodear strings en múltiples sitios.

  static const Map<String, List<String>> trackingMap = {
    pilarAyuno:     ['FastingNotifier', 'FastingInterval'],
    pilarEjercicio: ['ExerciseNotifier', 'ExerciseLog'],
    pilarNutricion: ['NutritionNotifier', 'NutritionLog'],
    pilarSoporte:   ['SleepNotifier', 'HydrationNotifier'],
    pilarInsulina:  ['NutritionNotifier', 'NutritionLog', 'circadianAlignment'],
  };

  // ── Mapping IMR → pilares funcionales ────────────────────────────────────────
  // Coherencia entre el lenguaje visible y los bloques del algoritmo IMR.
  //
  //   Bloque Estructura  (50%) ←→ Resultado de Composición Corporal
  //                                (impacta todos los pilares indirectamente)
  //   Bloque Metabólico  (25%) ←→ Ayuno Consciente + Gestión de Insulina (timing)
  //   Bloque Comportamiento (25%) ←→ Sarcopenia & Resistencia
  //                                 + Nutrición Científica
  //                                 + Soporte Metabólico

  static const String imrBlockEstructura    = 'Composición Corporal';
  static const String imrBlockMetabolico    = pilarAyuno;           // 'Ayuno Consciente'
  static const String imrBlockComportamiento = 'Hábitos Circadianos';
}
