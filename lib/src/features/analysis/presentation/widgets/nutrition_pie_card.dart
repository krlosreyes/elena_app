// SPEC-168.5.4 (2026-06-03): pie chart de Nutrición A vs E.
//
// Reemplaza al BarChartCard de % por día en la pantalla principal de
// Análisis. Apple Health usa este patrón ("distribución") para que el
// usuario vea en un golpe la calidad agregada del período sin pelear
// con barras en escala lineal.
//
// La evolución temporal (barras diarias) se movió a Tendencias.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/nutrition_pie_data.dart';

class NutritionPieCard extends StatelessWidget {
  const NutritionPieCard({
    super.key,
    required this.data,
    required this.dateRange,
    required this.headline,
  });

  final NutritionPieData data;

  /// "14 may. al 4 jun. de 2026". Calculado por el caller con el helper
  /// existente.
  final String dateRange;

  /// Frase conversacional. Ej: "El 82 % de tus comidas fueron A-dominantes."
  final String headline;

  // Verde A-dominante (mismo metabolicGreen del proyecto).
  static const _colorA = Color(0xFF10B981);
  // Amarillo E-dominante (cálido, distinto del naranja del pilar).
  static const _colorE = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          if (data.isEmpty)
            _buildEmpty()
          else ...[
            _buildHero(),
            const SizedBox(height: 4),
            Text(
              dateRange,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 170,
                height: 170,
                child: CustomPaint(
                  painter: _PiePainter(
                    aPct: data.aPct / 100.0,
                    colorA: _colorA,
                    colorE: _colorE,
                  ),
                  child: Center(child: _buildCenterLabel()),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Sin registros de comidas en este rango.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'PROMEDIO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.white.withValues(alpha: 0.50),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterLabel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              data.aPct.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'A-dominante',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(
          color: _colorA,
          label: 'A-dominantes',
          count: data.aDominantCount,
          total: data.total,
        ),
        _legendItem(
          color: _colorE,
          label: 'E-dominantes',
          count: data.eDominantCount,
          total: data.total,
        ),
      ],
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required int count,
    required int total,
  }) {
    final pct = total == 0 ? 0 : (count * 100 / total).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count · $pct %',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.aPct,
    required this.colorA,
    required this.colorE,
  });

  /// 0.0–1.0. 0 = todo E; 1 = todo A.
  final double aPct;
  final Color colorA;
  final Color colorE;

  static const double _stroke = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - _stroke / 2;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawCircle(center, radius, track);

    // Caso "100 % A" o "100 % E": pintamos un círculo completo del color
    // correspondiente. drawArc con 2π puede fallar visualmente.
    if (aPct >= 1.0) {
      _drawRing(canvas, center, radius, colorA);
      return;
    }
    if (aPct <= 0.0) {
      _drawRing(canvas, center, radius, colorE);
      return;
    }

    // Mixto: dibujamos dos arcos. A empieza arriba (-π/2) y avanza horario.
    const startA = -math.pi / 2;
    final sweepA = 2 * math.pi * aPct;
    final sweepE = 2 * math.pi - sweepA;

    final paintA = Paint()
      ..color = colorA
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.butt;
    final paintE = Paint()
      ..color = colorE
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startA, sweepA, false, paintA);
    canvas.drawArc(rect, startA + sweepA, sweepE, false, paintE);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.aPct != aPct || old.colorA != colorA || old.colorE != colorE;
}
