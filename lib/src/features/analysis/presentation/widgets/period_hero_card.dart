// SPEC-113 + SPEC-118: card "hero" del Análisis.
//
// Diseño rediseñado (SPEC-118 rev): ring de progreso para el IMR de
// HOY (a la izquierda) + grid compacto de stats secundarios a la
// derecha (promedio, mejor día, peor día). Aprovecha el ancho
// horizontal y comunica magnitud visualmente vía el arc del ring.
//
// El ring está inspirado en Apple Watch / Oura — el número del IMR
// vive en el centro, el arc se llena proporcional a la escala 0-100,
// y el color del arc indica la zona (rojo, naranja, ámbar, verde).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/domain/period_comparison.dart';

class PeriodHeroCard extends StatelessWidget {
  final PeriodComparison data;
  final String periodLabel;

  const PeriodHeroCard({
    super.key,
    required this.data,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final today = data.imrToday;
    final hasToday = today != null;
    final todayColor = _zoneColor(today ?? 0);

    final vs = data.todayVsAverage;
    Color vsColor = Colors.white.withValues(alpha: 0.50);
    IconData vsIcon = Icons.remove_rounded;
    String vsLabel = 'sin comparación';
    if (vs != null) {
      if (vs > 0) {
        vsColor = AppColors.metabolicGreen;
        vsIcon = Icons.arrow_upward_rounded;
        vsLabel = '+$vs vs tu promedio';
      } else if (vs < 0) {
        vsColor = const Color(0xFFEF4444);
        vsIcon = Icons.arrow_downward_rounded;
        vsLabel = '$vs vs tu promedio';
      } else {
        vsIcon = Icons.remove_rounded;
        vsLabel = 'igual a tu promedio';
      }
    } else if (!hasToday) {
      vsLabel = 'Sin datos de hoy aún';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        // Gradiente sutil que se inclina hacia el color de zona para
        // dar profundidad. Apenas perceptible — el ring sigue siendo
        // el ancla visual.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B),
            (hasToday ? todayColor : Colors.white).withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow + chip de delta a la derecha de la misma fila.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TU IMR · ${periodLabel.toUpperCase()}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              if (hasToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vsColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(vsIcon, color: vsColor, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        vsLabel,
                        style: TextStyle(
                          color: vsColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Fila principal: ring grande (HOY) + columna de stats.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ImrRing(
                  score: today,
                  zoneColor: todayColor,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatRow(
                        label: 'PROMEDIO',
                        value: '${data.imrAverage}',
                        valueColor: Colors.white.withValues(alpha: 0.92),
                        valueSize: 22,
                      ),
                      if (data.bestDayDate != null)
                        _StatRow(
                          label: 'MEJOR',
                          value: '${data.bestDayImr}',
                          valueColor: AppColors.metabolicGreen,
                          subtitle: _humanDate(data.bestDayDate!),
                          valueSize: 17,
                        )
                      else
                        const SizedBox(height: 0),
                      if (data.worstDayDate != null)
                        _StatRow(
                          label: 'PEOR',
                          value: '${data.worstDayImr}',
                          valueColor: const Color(0xFFFB923C),
                          subtitle: _humanDate(data.worstDayDate!),
                          valueSize: 17,
                        )
                      else
                        const SizedBox(height: 0),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (!hasToday) ...[
            const SizedBox(height: 14),
            Text(
              'Registra tu día para ver tu IMR de hoy.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Color de zona (consistente con header de Hoy y badge de Perfil).
  static Color _zoneColor(int score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 75) return const Color(0xFF22BB33);
    if (score >= 60) return const Color(0xFFFFD700);
    if (score >= 40) return const Color(0xFFFF8C00);
    return const Color(0xFFFF4444);
  }

  static String _humanDate(DateTime d) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring de IMR (gauge)
// ─────────────────────────────────────────────────────────────────────────────

class _ImrRing extends StatelessWidget {
  final int? score;
  final Color zoneColor;

  const _ImrRing({required this.score, required this.zoneColor});

  @override
  Widget build(BuildContext context) {
    const size = 110.0;
    final progress = (score ?? 0).clamp(0, 100) / 100;
    final inactive = score == null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(size),
            painter: _RingPainter(
              progress: progress,
              color:
                  inactive ? Colors.white.withValues(alpha: 0.30) : zoneColor,
              trackColor: Colors.white.withValues(alpha: 0.06),
              strokeWidth: 9,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                inactive ? '—' : '$score',
                style: TextStyle(
                  color: inactive
                      ? Colors.white.withValues(alpha: 0.40)
                      : zoneColor,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -1,
                  fontFeatures: const [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'HOY',
                style: TextStyle(
                  color: inactive
                      ? Colors.white.withValues(alpha: 0.40)
                      : zoneColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    // Track (fondo completo).
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Arc de progreso. Empieza arriba (-π/2) y avanza en sentido
    // horario hasta `progress * 2π`.
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────────────────────
// Fila de stat individual (label izquierda + valor derecha + subtitle opcional)
// ─────────────────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? subtitle;
  final double valueSize;

  const _StatRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.subtitle,
    this.valueSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: valueSize,
            fontWeight: FontWeight.w800,
            height: 1.0,
            fontFeatures: const [
              FontFeature.tabularFigures(),
            ],
          ),
        ),
      ],
    );
  }
}
