// PILLAR FEEDBACK CARD — Widget genérico de análisis por pilar.
//
// Misma estructura visual en todos los pilares para coherencia UX:
//   1. Header "ANÁLISIS DE PILAR"
//   2. 3 chips de métricas clave
//   3. Barra de progreso con marcador de objetivo
//   4. Bloque de diagnóstico con emoji + título + copy accionable
//
// Usado por: Ayuno, Hidratación, Ejercicio, Sueño, Nutrición.

import 'package:flutter/material.dart';

class PillarFeedbackCard extends StatelessWidget {
  const PillarFeedbackCard({
    super.key,
    required this.headerLabel,
    required this.chips,
    required this.progressFill,
    required this.progressColor,
    required this.progressLeft,
    required this.progressRight,
    this.markerFraction,
    this.markerLabel,
    required this.statusEmoji,
    required this.statusTitle,
    required this.statusColor,
    required this.statusBody,
  }) : assert(chips.length >= 1 && chips.length <= 3,
            'chips debe tener entre 1 y 3 elementos');

  /// Etiqueta del header, e.g. "ANÁLISIS DE AYUNO".
  final String headerLabel;

  /// 1–3 chips de métricas. Usar el record `(label, value, color)`.
  final List<({String label, String value, Color color})> chips;

  /// Relleno de la barra de progreso (0.0–1.0).
  final double progressFill;
  final Color progressColor;

  /// Etiquetas de los extremos del eje X.
  final String progressLeft;
  final String progressRight;

  /// Posición del marcador de objetivo (0.0–1.0). Null = sin marcador.
  final double? markerFraction;

  /// Texto debajo de la barra, e.g. "Objetivo: 16h".
  final String? markerLabel;

  /// Bloque de diagnóstico.
  final String statusEmoji;
  final String statusTitle;
  final Color statusColor;
  final String statusBody;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              headerLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chips de métricas
          Row(
            children: [
              for (int i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _MetricChip(
                  label: chips[i].label,
                  value: chips[i].value,
                  color: chips[i].color,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Barra de progreso
          Row(
            children: [
              Text(
                progressLeft,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressFill.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    // Marcador de objetivo
                    if (markerFraction != null)
                      Align(
                        alignment: Alignment(
                          (markerFraction!.clamp(0.0, 1.0) * 2 - 1),
                          0,
                        ),
                        child: Container(
                          width: 2,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white54,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                progressRight,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (markerLabel != null) ...[
            const SizedBox(height: 5),
            Text(
              '│ $markerLabel',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Diagnóstico
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusBody,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chip de métrica ─────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 8,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
