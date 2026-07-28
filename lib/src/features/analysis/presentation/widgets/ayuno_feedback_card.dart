// AYUNO FEEDBACK CARD — Análisis del hábito de ayuno en el período.
//
// Muestra:
//   • Promedio de horas de ayuno
//   • Días que alcanzaron el objetivo (≥ protocolo del usuario)
//   • Clasificación: Excelente / En progreso / Oportunidad
//   • Copy motivacional accionable
//
// Input: MetricSeries del fastingHabitSeriesProvider (horas por punto).

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/metric_series.dart';

class AyunoFeedbackCard extends StatelessWidget {
  final MetricSeries series;

  /// Protocolo del usuario (horas de ayuno objetivo). Default 16.
  final double targetHours;

  const AyunoFeedbackCard({
    super.key,
    required this.series,
    this.targetHours = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final daysOnTarget = points.where((p) => p.value >= targetHours).length;
    final total = points.length;
    final pctOnTarget = total > 0 ? (daysOnTarget / total * 100).round() : 0;

    final _Status status;
    if (avg >= targetHours && pctOnTarget >= 70) {
      status = _Status.excellent;
    } else if (avg >= targetHours * 0.75) {
      status = _Status.progress;
    } else {
      status = _Status.opportunity;
    }

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
          // Encabezado
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ANÁLISIS DE AYUNO',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Métricas clave
          Row(
            children: [
              _MetricChip(
                label: 'PROMEDIO',
                value: '${avg.toStringAsFixed(1)}h',
                color: _colorFor(avg, targetHours),
              ),
              const SizedBox(width: 10),
              _MetricChip(
                label: 'EN OBJETIVO',
                value: '$daysOnTarget/$total días',
                color: _colorForPct(pctOnTarget),
              ),
              const SizedBox(width: 10),
              _MetricChip(
                label: 'CUMPLIMIENTO',
                value: '$pctOnTarget%',
                color: _colorForPct(pctOnTarget),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de progreso de cumplimiento
          Row(
            children: [
              Text(
                '0h',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (avg / (targetHours * 1.5)).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _colorFor(avg, targetHours),
                        ),
                      ),
                    ),
                    // Marcador de objetivo
                    Positioned(
                      left: (targetHours / (targetHours * 1.5)) *
                          (MediaQuery.of(context).size.width - 100),
                      top: 0,
                      bottom: 0,
                      child: Container(width: 1.5, color: Colors.white30),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(targetHours * 1.5).round()}h',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '│ Objetivo: ${targetHours.round()}h',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Diagnóstico + copy
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: status.color.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.title,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _feedbackCopy(
                          avg: avg,
                          pctOnTarget: pctOnTarget,
                          targetHours: targetHours,
                          status: status,
                        ),
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

  // ─── Helpers ──────────────────────────────────────────────────────

  static Color _colorFor(double avg, double target) {
    if (avg >= target) return const Color(0xFF10B981);
    if (avg >= target * 0.75) return const Color(0xFF38BDF8);
    return const Color(0xFFF59E0B);
  }

  static Color _colorForPct(int pct) {
    if (pct >= 70) return const Color(0xFF10B981);
    if (pct >= 40) return const Color(0xFF38BDF8);
    return const Color(0xFFF59E0B);
  }

  static String _feedbackCopy({
    required double avg,
    required int pctOnTarget,
    required double targetHours,
    required _Status status,
  }) {
    switch (status) {
      case _Status.excellent:
        return 'Excelente consistencia. Estás cumpliendo tu protocolo de '
            '${targetHours.round()}h en la mayoría de los días. '
            'Esto genera un déficit calórico sostenido y activa la '
            'autofagia metabólica.';
      case _Status.progress:
        return 'Vas en buen camino. Tu promedio de ${avg.toStringAsFixed(1)}h '
            'está cerca del objetivo. Cada hora adicional de ayuno '
            'amplifica los beneficios hormonales — intenta extender '
            '30 minutos más los días que puedas.';
      case _Status.opportunity:
        return 'Tu promedio de ${avg.toStringAsFixed(1)}h indica oportunidad '
            'de mejora. Apunta a ${targetHours.round()}h como mínimo '
            'para activar la cetosis y la regulación de insulina. '
            'Comienza cerrando la ventana de alimentación antes de las 8pm.';
    }
  }
}

// ─── Chips de métricas ────────────────────────────────────────────────────

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

// ─── Enum status ──────────────────────────────────────────────────────────

enum _Status { excellent, progress, opportunity }

extension _StatusX on _Status {
  Color get color {
    switch (this) {
      case _Status.excellent:
        return const Color(0xFF10B981);
      case _Status.progress:
        return const Color(0xFF38BDF8);
      case _Status.opportunity:
        return const Color(0xFFF59E0B);
    }
  }

  String get emoji {
    switch (this) {
      case _Status.excellent:
        return '🏆';
      case _Status.progress:
        return '📈';
      case _Status.opportunity:
        return '🎯';
    }
  }

  String get title {
    switch (this) {
      case _Status.excellent:
        return 'Excelente consistencia';
      case _Status.progress:
        return 'En progreso';
      case _Status.opportunity:
        return 'Oportunidad de mejora';
    }
  }
}
