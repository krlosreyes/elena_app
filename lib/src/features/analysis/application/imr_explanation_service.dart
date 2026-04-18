// SPEC-13: IMR Explicado al Usuario
// Servicio que traduce IMRv2Result (datos técnicos del ScoreEngine) a
// IMRExplanation (lenguaje accesible + acción accionable).
// No expone fórmulas matemáticas. Opera de forma completamente estática.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/features/analysis/domain/imr_explanation.dart';

class IMRExplanationService {
  const IMRExplanationService._();

  // ─── API pública ────────────────────────────────────────────────────────────

  /// Genera la explicación completa del IMR a partir de los resultados del motor.
  ///
  /// [result]       — salida directa de ScoreEngine.calculateIMR()
  /// [fastingHours] — horas de ayuno actuales (para recomendación específica)
  /// [sleepHours]   — horas de sueño del último registro
  /// [exerciseMin]  — minutos de ejercicio del día
  static IMRExplanation explain(
    IMRv2Result result, {
    double fastingHours = 0,
    double sleepHours = 0,
    double exerciseMin = 0,
  }) {
    final List<IMRBlockDetail> blocks = _buildBlocks(result);
    final IMRBlockDetail weakest = _findWeakest(blocks);
    final Color zoneColor = IMRZoneColors.forZone(result.zone);

    return IMRExplanation(
      plainSummary: IMRZoneColors.summaryForZone(result.zone, result.totalScore),
      blocks: blocks,
      weakestBlock: weakest,
      actionableRecommendation: _buildRecommendation(
        weakest: weakest,
        result: result,
        fastingHours: fastingHours,
        sleepHours: sleepHours,
        exerciseMin: exerciseMin,
      ),
      zoneColor: zoneColor,
      zoneEmoji: IMRZoneColors.emojiForZone(result.zone),
    );
  }

  // ─── Construcción de bloques ────────────────────────────────────────────────

  static List<IMRBlockDetail> _buildBlocks(IMRv2Result result) {
    // Scores clampeados para seguridad
    final double struct   = result.structureScore.clamp(0.0, 1.0);
    final double metabol  = result.metabolicScore.clamp(0.0, 1.0);
    final double behavior = result.behaviorScore.clamp(0.0, 1.0);

    // Puntos que cada bloque aporta al score total
    final int structPts   = (struct   * 50).round();
    final int metabolPts  = (metabol  * 25).round();
    final int behaviorPts = (behavior * 25).round();

    return [
      IMRBlockDetail(
        name:               'Estructura',
        functionalName:     'Composición Corporal',
        description:        'Tu grasa visceral y masa muscular determinan '
                            'la base de tu metabolismo. Es el bloque de mayor peso.',
        rawScore:           struct,
        pointsContributed:  structPts,
        weightPercent:      50,
        icon:               Icons.account_circle_outlined,
        color:              _blockColor(struct),
        isWeakest:          false, // se asigna en _findWeakest
      ),
      IMRBlockDetail(
        name:               'Metabólico',
        functionalName:     'Ayuno Consciente',
        description:        'Las horas de ayuno activo y tu consistencia '
                            'semanal con el protocolo.',
        rawScore:           metabol,
        pointsContributed:  metabolPts,
        weightPercent:      25,
        icon:               Icons.timer_outlined,
        color:              _blockColor(metabol),
        isWeakest:          false,
      ),
      IMRBlockDetail(
        name:               'Comportamiento',
        functionalName:     'Hábitos Circadianos',
        description:        'La alineación de tu sueño, ejercicio, '
                            'nutrición y horarios de comida con tu reloj biológico.',
        rawScore:           behavior,
        pointsContributed:  behaviorPts,
        weightPercent:      25,
        icon:               Icons.self_improvement_rounded,
        color:              _blockColor(behavior),
        isWeakest:          false,
      ),
    ];
  }

  static Color _blockColor(double score) {
    if (score >= 0.80) return const Color(0xFF1ABC9C);
    if (score >= 0.60) return const Color(0xFF27AE60);
    if (score >= 0.40) return const Color(0xFFF39C12);
    if (score >= 0.20) return const Color(0xFFE67E22);
    return const Color(0xFFC0392B);
  }

  // ─── Identificación del bloque más débil ────────────────────────────────────

  /// Encuentra el bloque con menor score ponderado (considerando su peso
  /// relativo en el IMR, no solo el score bruto).
  static IMRBlockDetail _findWeakest(List<IMRBlockDetail> blocks) {
    // Comparamos score ponderado: rawScore * weightPercent
    IMRBlockDetail weakest = blocks.first;
    double minWeighted = weakest.rawScore * weakest.weightPercent;

    for (final block in blocks.skip(1)) {
      final double w = block.rawScore * block.weightPercent;
      if (w < minWeighted) {
        minWeighted = w;
        weakest = block;
      }
    }

    // Reconstruir la lista con isWeakest correctamente asignado
    // (inmutable — devolvemos una copia marcada)
    final marked = blocks.map((b) => IMRBlockDetail(
      name:              b.name,
      functionalName:    b.functionalName,
      description:       b.description,
      rawScore:          b.rawScore,
      pointsContributed: b.pointsContributed,
      weightPercent:     b.weightPercent,
      icon:              b.icon,
      color:             b.color,
      isWeakest:         b.name == weakest.name,
    )).toList();

    return marked.firstWhere((b) => b.isWeakest);
  }

  // ─── Generación de recomendaciones ──────────────────────────────────────────

  static String _buildRecommendation({
    required IMRBlockDetail weakest,
    required IMRv2Result result,
    required double fastingHours,
    required double sleepHours,
    required double exerciseMin,
  }) {
    switch (weakest.name) {
      case 'Estructura':
        return _structureRecommendation(result);
      case 'Metabólico':
        return _metabolicRecommendation(result, fastingHours);
      case 'Comportamiento':
        return _behaviorRecommendation(result, sleepHours, exerciseMin);
      default:
        return 'Mantén la consistencia en todos tus pilares para ver mejoras sostenidas en tu IMR.';
    }
  }

  static String _structureRecommendation(IMRv2Result result) {
    if (result.structureScore < 0.35) {
      return 'Tu composición corporal es el principal freno de tu IMR. '
             'El ayuno extendido a 18-20 horas activa la lipólisis visceral, '
             'que es el tipo de grasa que más impacta este bloque.';
    }
    if (result.structureScore < 0.60) {
      return 'Incorporar 2-3 sesiones de entrenamiento de resistencia por semana '
             'aumenta tu masa magra y mejora directamente tu FFMI, '
             'el segundo componente de este bloque.';
    }
    return 'Tu estructura está bien. Mantener el protocolo de ayuno y ejercicio '
           'sostendrá y mejorará gradualmente tu composición corporal.';
  }

  static String _metabolicRecommendation(IMRv2Result result, double fastingHours) {
    if (fastingHours < 8) {
      return 'Llevas ${fastingHours.toStringAsFixed(0)}h de ayuno. '
             'El beneficio metabólico real comienza en las 14h, '
             'cuando el cuerpo agota el glucógeno y activa la quema de grasa.';
    }
    if (fastingHours < 14) {
      final double hoursLeft = 14 - fastingHours;
      return 'Faltan ${hoursLeft.toStringAsFixed(0)} horas para alcanzar '
             'el umbral de 14h donde inicia la cetosis leve. '
             'Mantente hidratado y resiste hasta lograrlo.';
    }
    if (result.metabolicScore < 0.55) {
      return 'Tu ayuno de hoy está bien, pero la consistencia semanal '
             'arrastra tu score. Mantener el protocolo 5 de 7 días '
             'activa adaptaciones metabólicas que duran semanas.';
    }
    return 'Tu ayuno activo es sólido. Para ir más lejos, '
           'termina tu última comida antes de las 18:00 '
           'para activar el bono eTRF de tu protocolo.';
  }

  static String _behaviorRecommendation(
    IMRv2Result result,
    double sleepHours,
    double exerciseMin,
  ) {
    // Prioridad 1: alerta circadiana (cena tardía)
    if (result.circadianAlignment < 0.7) {
      return 'Se detectó ingesta después de las 22:30. '
             'Evitar comer en ese horario activa el bloqueo intestinal circadiano '
             'y puede mejorar tu IMR de inmediato mañana.';
    }
    // Prioridad 2: sueño insuficiente
    if (sleepHours > 0 && (sleepHours < 7 || sleepHours > 9)) {
      return 'Dormiste ${sleepHours.toStringAsFixed(1)}h. '
             'El rango óptimo es 7-9 horas: en ese rango cortisol y grelina '
             'se regulan, haciendo que tu ayuno sea mucho más eficiente.';
    }
    // Prioridad 3: sin ejercicio
    if (exerciseMin < 20) {
      return '${exerciseMin.toStringAsFixed(0)} minutos de ejercicio registrados hoy. '
             'Con 30-45 minutos de resistencia o cardio puedes sumar '
             'hasta 7.5 puntos directos a tu IMR.';
    }
    return 'Tu comportamiento circadiano es bueno. '
           'Registrar tus comidas y mantener el horario de última ingesta '
           'antes de las 18:00 puede empujar este bloque al siguiente nivel.';
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final imrExplanationServiceProvider = Provider<IMRExplanationService>(
  (_) => const IMRExplanationService._(),
);
