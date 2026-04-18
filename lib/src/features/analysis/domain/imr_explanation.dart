// SPEC-13: IMR Explicado al Usuario
// Modelos de datos que encapsulan la interpretación humana del IMR.
// Ninguno de estos modelos expone fórmulas matemáticas al exterior.

import 'package:flutter/material.dart';

// ─── Colores de zona (fuente única de verdad) ─────────────────────────────────

class IMRZoneColors {
  static Color forZone(String zone) {
    switch (zone) {
      case 'OPTIMIZADO':  return const Color(0xFF1ABC9C); // teal
      case 'EFICIENTE':   return const Color(0xFF27AE60); // green
      case 'FUNCIONAL':   return const Color(0xFFF39C12); // amber
      case 'INESTABLE':   return const Color(0xFFE67E22); // orange
      case 'DETERIORADO': return const Color(0xFFC0392B); // red
      default:            return const Color(0xFF64748B); // grey
    }
  }

  static String emojiForZone(String zone) {
    switch (zone) {
      case 'OPTIMIZADO':  return '🏆';
      case 'EFICIENTE':   return '✅';
      case 'FUNCIONAL':   return '⚡';
      case 'INESTABLE':   return '⚠️';
      case 'DETERIORADO': return '🔴';
      default:            return '📊';
    }
  }

  static String summaryForZone(String zone, int score) {
    switch (zone) {
      case 'OPTIMIZADO':
        return 'Tu metabolismo opera en su máximo potencial. '
               'Mantén la consistencia para sostener este estado.';
      case 'EFICIENTE':
        return 'Tu cuerpo quema grasa de manera eficiente y mantiene '
               'un equilibrio hormonal sólido. Estás cerca del tope.';
      case 'FUNCIONAL':
        return 'Tu metabolismo funciona bien pero tiene margen de mejora. '
               'Un ajuste en el pilar más débil puede elevar tu IMR significativamente.';
      case 'INESTABLE':
        return 'Tu metabolismo envía señales de alerta. '
               'Prioriza el pilar indicado para estabilizar el sistema.';
      case 'DETERIORADO':
        return 'Tu sistema metabólico necesita atención urgente. '
               'Comenzar con el ayuno consciente es el primer paso más impactante.';
      default:
        return 'Registra tus pilares para que Elena pueda calcular tu IMR.';
    }
  }
}

// ─── Detalle de cada bloque ───────────────────────────────────────────────────

class IMRBlockDetail {
  /// Nombre técnico interno del bloque.
  final String name;

  /// Nombre en lenguaje de pilares funcionales (SPEC-17).
  final String functionalName;

  /// Breve descripción de qué mide este bloque.
  final String description;

  /// Score del bloque en rango 0.0–1.0 (salida directa del ScoreEngine).
  final double rawScore;

  /// Puntos que este bloque aporta al IMR total (weight * rawScore * 100).
  final int pointsContributed;

  /// Peso del bloque en el IMR total (50, 25, 25).
  final int weightPercent;

  /// Icono representativo del bloque.
  final IconData icon;

  /// Color asociado al score del bloque.
  final Color color;

  /// Si este bloque es el que más limita el IMR del usuario.
  final bool isWeakest;

  const IMRBlockDetail({
    required this.name,
    required this.functionalName,
    required this.description,
    required this.rawScore,
    required this.pointsContributed,
    required this.weightPercent,
    required this.icon,
    required this.color,
    required this.isWeakest,
  });

  /// Score del bloque expresado como porcentaje (0–100).
  int get scorePercent => (rawScore * 100).round().clamp(0, 100);
}

// ─── Modelo de explicación completa ──────────────────────────────────────────

class IMRExplanation {
  /// Resumen del IMR en lenguaje llano. Máximo 2 oraciones.
  /// Sin terminología técnica, sin fórmulas.
  final String plainSummary;

  /// Los 3 bloques del IMR con su interpretación.
  final List<IMRBlockDetail> blocks;

  /// El bloque con menor rawScore (mayor oportunidad de mejora).
  final IMRBlockDetail weakestBlock;

  /// Acción concreta y específica para mejorar el bloque más débil.
  /// Escrita en segunda persona, lenguaje directo.
  final String actionableRecommendation;

  /// Color de zona derivado del score total.
  final Color zoneColor;

  /// Emoji representativo de la zona.
  final String zoneEmoji;

  const IMRExplanation({
    required this.plainSummary,
    required this.blocks,
    required this.weakestBlock,
    required this.actionableRecommendation,
    required this.zoneColor,
    required this.zoneEmoji,
  });
}
