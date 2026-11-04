// Rediseño Hoy (2026-11-04): anillo del día metabólico.
//
// El anillo ES el día: un arco de ayuno (meta del protocolo) seguido de un
// arco de ventana de comida. Un punto marca dónde vas. Así el usuario ve de
// un vistazo en qué parte de su día está, sin leer nada.
//
//   ─ ayuno cumplido   → color de etapa (ámbar → verde)
//   ─ ayuno pendiente  → blanco tenue
//   ─ ventana          → teal tenue; la parte transcurrida, teal fuerte
//
// Pintor puro: recibe horas y colores; no lee providers ni el reloj.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class MetabolicDayRing extends StatelessWidget {
  const MetabolicDayRing({
    super.key,
    required this.fastHours,
    required this.windowHours,
    required this.elapsedHours,
    required this.fastColor,
    required this.windowColor,
    required this.child,
    this.size = 260,
    this.stroke = 16,
    this.semanticLabel,
  });

  /// Meta de ayuno (h).
  final double fastHours;

  /// Duración de la ventana de comida (h).
  final double windowHours;

  /// Horas transcurridas desde que empezó el ayuno (puede superar la meta).
  final double elapsedHours;

  final Color fastColor;
  final Color windowColor;
  final Widget child;
  final double size;
  final double stroke;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: MetabolicDayRingPainter(
            fastHours: fastHours,
            windowHours: windowHours,
            elapsedHours: elapsedHours,
            fastColor: fastColor,
            windowColor: windowColor,
            stroke: stroke,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class MetabolicDayRingPainter extends CustomPainter {
  MetabolicDayRingPainter({
    required this.fastHours,
    required this.windowHours,
    required this.elapsedHours,
    required this.fastColor,
    required this.windowColor,
    required this.stroke,
  });

  final double fastHours;
  final double windowHours;
  final double elapsedHours;
  final Color fastColor;
  final Color windowColor;
  final double stroke;

  /// Fracción del anillo (0..1) que corresponde a [hours] del día.
  static double fractionFor({
    required double hours,
    required double fastHours,
    required double windowHours,
  }) {
    final total = fastHours + windowHours;
    if (total <= 0) return 0;
    return (hours / total).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final total = fastHours + windowHours;
    if (total <= 0) return;
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    const full = 2 * math.pi;
    // Pequeño hueco entre tramos para que se lean como fases.
    final gap = (stroke * 0.9) / radius;

    Paint p(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = c;

    void arc(double from, double to, Color c) {
      final sweep = to - from;
      if (sweep <= 0.0001) return;
      canvas.drawArc(rect, start + from * full, sweep * full, false, p(c));
    }

    final fastFrac = fastHours / total;
    final gapFrac = gap / full;
    final elapsed = elapsedHours.clamp(0.0, total);
    final pos = elapsed / total;

    // Pista base.
    canvas.drawCircle(center, radius,
        p(Colors.white.withValues(alpha: 0.05))..strokeCap = StrokeCap.butt);

    // Ayuno: cumplido + pendiente.
    final fastDone = math.min(pos, fastFrac);
    arc(fastDone + (fastDone > 0 ? gapFrac : 0), fastFrac - gapFrac,
        Colors.white.withValues(alpha: 0.12));
    arc(0, fastDone, fastColor);

    // Ventana: tenue + transcurrida.
    final winStart = fastFrac + gapFrac;
    arc(winStart, 1 - gapFrac, windowColor.withValues(alpha: 0.22));
    if (pos > fastFrac) {
      arc(winStart, math.max(winStart, pos), windowColor);
    }

    // Marcador "estás aquí".
    final angle = start + pos * full;
    final m = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    final markerColor = pos > fastFrac ? windowColor : fastColor;
    canvas.drawCircle(m, stroke * 0.72, Paint()..color = const Color(0xFF020617));
    canvas.drawCircle(
      m,
      stroke * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = markerColor,
    );
  }

  @override
  bool shouldRepaint(MetabolicDayRingPainter old) =>
      old.elapsedHours != elapsedHours ||
      old.fastHours != fastHours ||
      old.windowHours != windowHours ||
      old.fastColor != fastColor ||
      old.windowColor != windowColor ||
      old.stroke != stroke;
}
