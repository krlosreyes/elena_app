// SPEC-256 RF-02 (v2): gráfico de barras diario de racha — reemplaza al
// heatmap estilo GitHub (v1), que Carlos calificó como "un asco, no
// comunica nada" incluso después de arreglar alineación/colores.
//
// Diagnóstico de por qué la v1 (heatmap) no funcionaba, más allá de sus
// bugs puntuales: el lenguaje visual del resto de Análisis es "barras +
// eje + línea de referencia" (ver `bar_chart_card.dart`, SPEC-163,
// usado en los 8 tiles de detalle de esta misma pantalla) — celdas
// pequeñas en grilla son un patrón AJENO a esta app, no algo que el
// usuario ya sepa leer acá. Un gráfico de barras con una línea de
// referencia en "3 pilares" es autoexplicativo: la barra cruza la línea
// o no la cruza, sin necesitar aprender un código de colores nuevo.
//
// Diseño: 30 barras (una por día), altura = pilares completados (0-5,
// escala fija — no depende de los datos del usuario, así "3" siempre
// está en el mismo lugar). Naranja = calificó para la racha, gris =
// registró pero no llegó al mínimo, sin barra = sin registro ese día.
// Punto ámbar sobre la barra = día perdonado por una reserva.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

class StreakBarChart extends StatelessWidget {
  final List<StreakEntry> history;
  final Set<String> protectedDates;

  const StreakBarChart({
    super.key,
    required this.history,
    required this.protectedDates,
  });

  static const int _days = 30;
  static const _qualifiedColor = Colors.orange; // mismo color que la flama del header
  static const _loggedColor = Color(0xFF64748B); // gris pizarra: "intentó, no calificó"
  static const _protectedColor = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final byDate = <String, StreakEntry>{};
    for (final e in history) {
      byDate[e.date] = e;
    }

    final today = DayBoundaryResolver.startOfDay(DateTime.now());
    final start = today.subtract(const Duration(days: _days - 1));
    final days = List.generate(_days, (i) => start.add(Duration(days: i)));
    final daysWithRecord = history.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÚLTIMOS 30 DÍAS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          if (daysWithRecord < 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Con unos días más empezarás a ver tu patrón acá.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: CustomPaint(
                size: Size.infinite,
                painter: _StreakBarsPainter(
                  days: days,
                  byDate: byDate,
                  protectedDates: protectedDates,
                  today: today,
                ),
              ),
            ),
          const SizedBox(height: 14),
          _legend(),
        ],
      ),
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _legendItem(color: _qualifiedColor, label: 'calificó'),
        _legendItem(color: _loggedColor, label: 'no llegó al mínimo'),
        _legendItem(color: null, icon: Icons.circle, iconColor: _protectedColor, label: 'protegido'),
      ],
    );
  }

  Widget _legendItem({
    Color? color,
    IconData? icon,
    Color? iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 10, color: iconColor)
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 10),
        ),
      ],
    );
  }
}

class _StreakBarsPainter extends CustomPainter {
  final List<DateTime> days;
  final Map<String, StreakEntry> byDate;
  final Set<String> protectedDates;
  final DateTime today;

  _StreakBarsPainter({
    required this.days,
    required this.byDate,
    required this.protectedDates,
    required this.today,
  });

  static const double _yAxisRightWidth = 20;
  static const double _xAxisHeight = 16;
  static const double _topPadding = 14; // espacio para el escudo sobre la barra
  static const double _barGap = 2.5;
  static const double _threshold = 3; // qualifiesForStreak: mínimo 3 pilares

  @override
  void paint(Canvas canvas, Size size) {
    final plotLeft = 0.0;
    final plotTop = _topPadding;
    final plotRight = size.width - _yAxisRightWidth;
    final plotBottom = size.height - _xAxisHeight;
    final plotHeight = plotBottom - plotTop;
    final plotWidth = plotRight - plotLeft;

    const yMax = 5.0; // escala fija: 0-5 pilares, siempre igual.
    const yMin = 0.0;

    // Línea de referencia en el mínimo de racha (3 pilares) — el
    // elemento clave: la barra la cruza o no la cruza.
    final thresholdY =
        plotBottom - (_threshold - yMin) / (yMax - yMin) * plotHeight;
    final refPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 4.0, gap = 3.0;
    double x = plotLeft;
    while (x < plotRight) {
      final end = (x + dash).clamp(0.0, plotRight).toDouble();
      canvas.drawLine(Offset(x, thresholdY), Offset(end, thresholdY), refPaint);
      x += dash + gap;
    }
    _drawLabel(
      canvas,
      'mín. 3',
      Offset(plotRight + 4, thresholdY - 5),
      Colors.white.withValues(alpha: 0.35),
    );

    // Barras.
    final n = days.length;
    final totalGap = _barGap * (n - 1);
    final barWidth = (plotWidth - totalGap) / n;

    for (int i = 0; i < n; i++) {
      final date = days[i];
      final key = DayBoundaryResolver.dayKeyIso(date);
      final entry = byDate[key];
      final isProtected = protectedDates.contains(key);
      final barX = plotLeft + i * (barWidth + _barGap);

      if (entry == null) {
        // Sin registro: solo un tick plano en la base, no una barra.
        final tickPaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, plotBottom - 2, barWidth, 2),
            const Radius.circular(1),
          ),
          tickPaint,
        );
        continue;
      }

      final pillars = entry.pillarsCompleted.toDouble().clamp(yMin, yMax).toDouble();
      final barHeight = pillars <= 0
          ? 2.0 // barra mínima visible aunque sea 0 pilares (día registrado)
          : (pillars - yMin) / (yMax - yMin) * plotHeight;
      final barY = plotBottom - barHeight;
      final fillColor = entry.qualifiesForStreak
          ? StreakBarChart._qualifiedColor
          : StreakBarChart._loggedColor;
      final barPaint = Paint()..color = fillColor;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      );
      canvas.drawRRect(rect, barPaint);

      if (isProtected) {
        final dotPaint = Paint()..color = StreakBarChart._protectedColor;
        canvas.drawCircle(
          Offset(barX + barWidth / 2, barY - 6),
          3.2,
          dotPaint,
        );
      }
    }

    // Eje X: 3 labels (inicio, mitad, hoy).
    _drawXLabel(canvas, days.first, 0, barWidth, plotBottom);
    _drawXLabel(canvas, days[n ~/ 2], n ~/ 2, barWidth, plotBottom);
    _drawXLabel(canvas, days.last, n - 1, barWidth, plotBottom, isToday: true);
  }

  void _drawXLabel(
    Canvas canvas,
    DateTime date,
    int index,
    double barWidth,
    double plotBottom, {
    bool isToday = false,
  }) {
    final xCenter = index * (barWidth + _barGap) + barWidth / 2;
    final text = isToday ? 'hoy' : '${date.day} ${_monthsShort[date.month - 1]}';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: isToday ? 0.55 : 0.35),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Evita que el primer/último label se corte fuera del área visible.
    final dx = (xCenter - tp.width / 2).clamp(0.0, double.infinity).toDouble();
    tp.paint(canvas, Offset(dx, plotBottom + 4));
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  @override
  bool shouldRepaint(covariant _StreakBarsPainter old) =>
      old.days != days || old.byDate != byDate || old.protectedDates != protectedDates;
}
