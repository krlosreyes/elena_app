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
            // Propuesta "racha protagonista" (2026-07-15, P5): el chart ya
            // tenía los datos pero no era interactivo — tocar una barra
            // ahora abre el desglose de ese día específico (los 5 pilares
            // y por qué calificó o no), en vez de dejar que el usuario
            // adivine el significado de un color.
            LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                onTapUp: (details) => _handleDayTap(
                  context: context,
                  localDx: details.localPosition.dx,
                  width: constraints.maxWidth,
                  days: days,
                  byDate: byDate,
                  protectedDates: protectedDates,
                ),
                child: SizedBox(
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

  /// P5: traduce la posición X del tap al día correspondiente. La
  /// geometría (barGap, yAxisRightWidth) DEBE coincidir con
  /// `_StreakBarsPainter` (mismo archivo) — están duplicadas acá en vez
  /// de compartidas porque `_StreakBarsPainter` es privada y esto evita
  /// acoplar el gesture-handling al ciclo de vida del painter.
  static void _handleDayTap({
    required BuildContext context,
    required double localDx,
    required double width,
    required List<DateTime> days,
    required Map<String, StreakEntry> byDate,
    required Set<String> protectedDates,
  }) {
    const barGap = 2.5; // debe coincidir con _StreakBarsPainter._barGap
    const yAxisRightWidth = 20.0; // debe coincidir con _StreakBarsPainter._yAxisRightWidth
    final n = days.length;
    if (n == 0) return;
    final plotRight = width - yAxisRightWidth;
    final totalGap = barGap * (n - 1);
    final barWidth = (plotRight - totalGap) / n;
    if (barWidth <= 0) return;

    final idx = (localDx / (barWidth + barGap)).floor().clamp(0, n - 1);
    final date = days[idx];
    final key = DayBoundaryResolver.dayKeyIso(date);
    final entry = byDate[key];
    final isProtected = protectedDates.contains(key);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(
        date: date,
        entry: entry,
        isProtected: isProtected,
      ),
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

/// P5 (2026-07-15): bottom sheet con el desglose de un día específico del
/// histórico — qué pilares se completaron y por qué el día calificó o no
/// para la racha. Usa `StreakEntry.missReason` (misma fuente que el
/// widget de HOY en Dashboard y el mensaje de racha rota) para que la
/// explicación nunca contradiga a las otras dos.
class _DayDetailSheet extends StatelessWidget {
  final DateTime date;
  final StreakEntry? entry;
  final bool isProtected;

  const _DayDetailSheet({
    required this.date,
    required this.entry,
    required this.isProtected,
  });

  static const _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final qualifies = entry?.qualifiesForStreak ?? false;
    final label = '${date.day} de ${_months[date.month - 1]}';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _statusChip(qualifies: qualifies, isProtected: isProtected, hasEntry: entry != null),
          const SizedBox(height: 18),
          if (entry == null)
            Text(
              'No hay registro para este día.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            )
          else ...[
            _pillarRow('Ayuno', entry.fastingCompleted),
            _pillarRow('Sueño', entry.sleepCompleted),
            _pillarRow('Hidratación', entry.hydrationCompleted),
            _pillarRow('Ejercicio', entry.exerciseLogged),
            _pillarRow('Nutrición', entry.nutritionLogged),
            const SizedBox(height: 14),
            Text(
              _whyText(qualifies: qualifies, isProtected: isProtected, entry: entry),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip({
    required bool qualifies,
    required bool isProtected,
    required bool hasEntry,
  }) {
    if (!hasEntry) return _chip('Sin registro', const Color(0xFF64748B));
    if (isProtected) return _chip('Protegido por una reserva', const Color(0xFFF59E0B));
    return qualifies
        ? _chip('Calificó para la racha', Colors.orange)
        : _chip('No llegó al mínimo', const Color(0xFF64748B));
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _pillarRow(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: completed
                ? const Color(0xFF34D399)
                : Colors.white.withValues(alpha: 0.30),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: completed ? Colors.white : Colors.white.withValues(alpha: 0.45),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _whyText({
    required bool qualifies,
    required bool isProtected,
    required StreakEntry entry,
  }) {
    if (isProtected) {
      return 'Este día no llegó al mínimo, pero una reserva lo protegió '
          'automáticamente — tu racha siguió sin interrupción.';
    }
    if (qualifies) {
      return 'Completó al menos 3 pilares, incluyendo ayuno o sueño '
          '(o 4 o más en total) — cuenta para la racha.';
    }
    final reason = entry.missReason;
    if (reason == null) return '';
    if (reason.isAnchorIssue) {
      return 'Completó 3 pilares, pero sin ayuno ni sueño — los que más '
          'cuentan para la racha.';
    }
    final n = reason.missingPillarsCount!;
    return n == 1
        ? 'Le faltó 1 pilar para llegar al mínimo de 3.'
        : 'Le faltaron $n pilares para llegar al mínimo de 3.';
  }
}
