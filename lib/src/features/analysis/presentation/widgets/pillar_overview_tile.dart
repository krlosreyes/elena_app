// SPEC-168.4 (2026-06-03): tile compacto de un pilar en la lista de
// Análisis. Reemplaza al card de chart completo en la home — el
// usuario ve el valor agregado del rango + sparkline mini, y entra al
// detalle con tap.
//
// Variante especial para Nutrición: en vez de sparkline lineal,
// mini-pie 32 px (coherente con SPEC-168.5.4 que ya usa pie para A vs E).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/sparkline_inline.dart';

class PillarOverviewTile extends StatelessWidget {
  const PillarOverviewTile({
    super.key,
    required this.metric,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
    required this.sparklineValues,
    this.aPctForPie,
  });

  /// ID estable para el routing al detalle.
  final ChartMetric metric;

  /// Ícono del pilar/métrica (AppIcons — set unificado, sin emojis).
  final IconData icon;

  /// Nombre del pilar ("Ayuno", "Peso", "Nutrición").
  final String label;

  /// Valor agregado del período formateado ("16.4", "76.4", "82").
  /// Vacío "" si no hay registros — se muestra estado vacío.
  final String value;

  /// Unidad ("h", "kg", "%", ""). Se concatena al valor.
  final String unit;

  /// Color del pilar (sparkline + acento).
  final Color accent;

  /// Datos para sparkline lineal. Vacío oculta el sparkline.
  final List<double> sparklineValues;

  /// SPEC-168.5.4: cuando el pilar es Nutrición, recibimos el % A de
  /// la distribución pie en lugar de sparkline. Si != null, dibujamos
  /// mini-pie en vez de línea.
  final double? aPctForPie;

  static const _colorA = Color(0xFF10B981);
  static const _colorE = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context) {
    final hasData = value.isNotEmpty;
    return InkWell(
      onTap: () => context.push('/analysis/pillar/${metric.name}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C0E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Ícono del pilar, teñido con su acento (set unificado AppIcons).
            SizedBox(
              width: 32,
              child: Center(
                child: Icon(icon, size: 22, color: accent),
              ),
            ),
            const SizedBox(width: 12),
            // Label + valor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  hasData
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (unit.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              Text(
                                unit,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Text(
                          'Aún sin registros',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ],
              ),
            ),
            // Sparkline o mini-pie
            SizedBox(
              width: 60,
              height: 32,
              child: aPctForPie != null
                  ? Center(child: _miniPie(aPctForPie!))
                  : (sparklineValues.length >= 2
                      ? SparklineInline(
                          values: sparklineValues,
                          color: accent,
                        )
                      : const SizedBox.shrink()),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.35),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Mini-pie 28 px para Nutrición. aPct en 0..100.
  Widget _miniPie(double aPct) {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _MiniPiePainter(
        aPctFraction: (aPct / 100.0).clamp(0.0, 1.0),
        colorA: _colorA,
        colorE: _colorE,
      ),
    );
  }
}

class _MiniPiePainter extends CustomPainter {
  _MiniPiePainter({
    required this.aPctFraction,
    required this.colorA,
    required this.colorE,
  });

  final double aPctFraction;
  final Color colorA;
  final Color colorE;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;
    final stroke = 5.0;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    if (aPctFraction >= 1.0) {
      final p = Paint()
        ..color = colorA
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawCircle(center, radius, p);
      return;
    }
    if (aPctFraction <= 0.0) {
      final p = Paint()
        ..color = colorE
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawCircle(center, radius, p);
      return;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startA = -1.5707963267948966; // -π/2
    final sweepA = 6.283185307179586 * aPctFraction; // 2π × frac
    final sweepE = 6.283185307179586 - sweepA;

    canvas.drawArc(
      rect,
      startA,
      sweepA,
      false,
      Paint()
        ..color = colorA
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      startA + sweepA,
      sweepE,
      false,
      Paint()
        ..color = colorE
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniPiePainter old) =>
      old.aPctFraction != aPctFraction ||
      old.colorA != colorA ||
      old.colorE != colorE;
}
