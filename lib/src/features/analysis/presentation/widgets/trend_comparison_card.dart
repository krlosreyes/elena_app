// SPEC-168.5 (2026-06-03): card de "Tendencias" estilo Apple Health.
//
// Layout:
//   Headline conversacional (17pt regular blanco 92%)
//   ── Visualización de 2 líneas horizontales (sin chart) ──
//   [80.21 kg ────────────────────────────]
//                                    [78.05 kg ───]
//   Promedio de 22 días       Promedio de 6 días
//
// La línea larga es sutil (blanco alpha 0.35) y ocupa el plot completo.
// La línea corta es destacada (accent del pilar) y ocupa solo el
// segmento final correspondiente a su ventana proporcional.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/trend_comparison.dart';

class TrendComparisonCard extends StatelessWidget {
  const TrendComparisonCard({
    super.key,
    required this.label,
    required this.unit,
    required this.accent,
    required this.trend,
    required this.mode,
  });

  /// Nombre del pilar / métrica en sentence case ("Peso", "IMR").
  final String label;

  /// Unidad para mostrar junto a los valores ("kg", "").
  final String unit;

  /// Color del pilar (línea corta destacada).
  final Color accent;

  /// Comparación calculada por TrendComparisonComputer.
  final TrendComparison trend;

  /// Modo temporal del rango activo. Decide si el copy dice "días",
  /// "semanas" o "meses".
  final AggregationMode mode;

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
            _headline(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 80,
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendPainter(
                trend: trend,
                accent: accent,
                unit: unit,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _windowLabel(trend.longWindow, mode),
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _windowLabel(trend.shortWindow, mode),
                style: TextStyle(
                  fontSize: 11.5,
                  color: accent.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// SPEC-168.5 §2.3: construye el headline conversacional según la
  /// métrica, la dirección deseable y la dirección del cambio.
  ///
  /// Casos:
  ///   - estable           → "Tu {label} se mantuvo estable en los últimos K {tu}"
  ///   - mejoró (Peso)     → "En promedio, bajaste de {label} en los últimos K {tu}"
  ///   - empeoró (Peso)    → "En promedio, subiste de {label} en los últimos K {tu}"
  ///   - mejoró (IMR/etc.) → "Tu {label} mejoró en los últimos K {tu}"
  ///   - empeoró (IMR/etc.)→ "Tu {label} cayó en los últimos K {tu}"
  String _headline() {
    final K = trend.shortWindow;
    final timeUnit = _timeUnit(K);
    if (trend.isStable) {
      return 'Tu ${label.toLowerCase()} se mantuvo estable en los últimos $K $timeUnit.';
    }
    // Peso (betterIf=down) tiene copy específico más natural.
    final isPeso = label.toLowerCase() == 'peso';
    if (isPeso) {
      final wentDown = trend.diff < 0;
      final verb = wentDown ? 'bajaste de' : 'subiste de';
      return 'En promedio, $verb peso en los últimos $K $timeUnit.';
    }
    // Resto: usa "mejoró" / "cayó" según direction vs betterIf.
    final verb = trend.isImprovement ? 'mejoró' : 'cayó';
    return 'Tu ${label.toLowerCase()} $verb en los últimos $K $timeUnit.';
  }

  String _timeUnit(int n) {
    switch (mode) {
      case AggregationMode.daily:
        return n == 1 ? 'día' : 'días';
      case AggregationMode.weekly:
        return n == 1 ? 'semana' : 'semanas';
      case AggregationMode.monthly:
        return n == 1 ? 'mes' : 'meses';
    }
  }

  String _windowLabel(int n, AggregationMode m) {
    switch (m) {
      case AggregationMode.daily:
        return n == 1 ? 'Promedio de 1 día' : 'Promedio de $n días';
      case AggregationMode.weekly:
        return n == 1 ? 'Promedio de 1 semana' : 'Promedio de $n semanas';
      case AggregationMode.monthly:
        return n == 1 ? 'Promedio de 1 mes' : 'Promedio de $n meses';
    }
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.trend,
    required this.accent,
    required this.unit,
  });

  final TrendComparison trend;
  final Color accent;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Plot ocupa horizontalmente toda la card. Vertical: 2 carriles —
    // largo arriba, corto abajo (offset). Diff visualizada por
    // separación vertical entre líneas.
    const longY = 12.0; // arriba
    const shortY = 56.0; // abajo
    const labelPadding = 6.0;

    // Línea larga (sutil, todo el ancho).
    final longPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final longStart = 0.0;
    final longEnd = w;
    canvas.drawLine(
      Offset(longStart, longY),
      Offset(longEnd, longY),
      longPaint,
    );

    // Etiqueta numérica de la línea larga (encima a la izquierda).
    final longLabel = _formatValue(trend.longAvg);
    final longTp = _textPainter(
      longLabel,
      fontSize: 13,
      color: Colors.white.withValues(alpha: 0.55),
      weight: FontWeight.w600,
    );
    longTp.paint(canvas, Offset(0, longY - longTp.height - labelPadding));

    // Línea corta — segmento final proporcional a su ventana.
    final shortFraction = trend.shortWindow / trend.longWindow;
    final shortStart = w * (1 - shortFraction);
    final shortEnd = w;

    final shortPaint = Paint()
      ..color = accent
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(shortStart, shortY),
      Offset(shortEnd, shortY),
      shortPaint,
    );

    // Etiqueta numérica de la línea corta (encima a la derecha).
    final shortLabel = _formatValue(trend.shortAvg);
    final shortTp = _textPainter(
      shortLabel,
      fontSize: 14,
      color: accent,
      weight: FontWeight.w700,
    );
    shortTp.paint(
      canvas,
      Offset(
        w - shortTp.width,
        shortY - shortTp.height - labelPadding,
      ),
    );

    // Línea conectora vertical sutil para anclar visualmente la
    // relación entre los dos promedios (en el lado izquierdo del
    // short segment).
    final connectorPaint = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(shortStart, longY),
      Offset(shortStart, shortY),
      connectorPaint,
    );
  }

  String _formatValue(double v) {
    String s;
    if (v.abs() >= 100) {
      s = v.toStringAsFixed(0);
    } else if (v == v.roundToDouble()) {
      s = v.toStringAsFixed(0);
    } else {
      s = v.toStringAsFixed(2);
    }
    return unit.isEmpty ? s : '$s $unit';
  }

  TextPainter _textPainter(
    String text, {
    required double fontSize,
    required Color color,
    required FontWeight weight,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    return tp;
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.trend != trend || old.accent != accent || old.unit != unit;
}
