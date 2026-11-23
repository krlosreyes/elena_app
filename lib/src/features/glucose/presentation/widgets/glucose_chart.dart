// Módulo "Tu Glucosa" — gráfica histórica (rediseño 23-nov).
//
// Antes: una línea fucsia sobre una banda verde, sin ejes, con los puntos
// repartidos por índice (dos lecturas separadas por una semana quedaban
// pegadas) y sin decir qué significaba cada valor.
//
// Ahora la gráfica responde tres preguntas:
//   1. ¿Dónde cae cada lectura?  Bandas ADA rotuladas (bajo / en rango /
//      elevado / alto), cortes con su número en el eje y cada punto con el
//      color de su clasificación.
//   2. ¿Cuándo?  Eje de tiempo real (fecha de medición), ventana de 14, 30
//      o 90 días, y al tocar un punto se ve su valor, fecha y hora.
//   3. ¿Cómo voy?  Cuántas lecturas cayeron en rango, distribución por
//      zona y promedio del periodo.
//
// Todo número sale de GlucoseChartData (dominio, puro y testeado). Las
// bandas son los mismos cortes de GlucoseClassifier. Ayunas y 2 h después
// de comer se grafican por separado porque tienen rangos distintos;
// mezclarlos en una sola línea no tiene sentido clínico.
//
// CustomPainter propio: no hay librería de gráficas en pubspec.yaml.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_chart_data.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_classification.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:elena_app/src/features/science/presentation/widgets/sources_footer.dart';

const _lowColor = Color(0xFFEF4444);
const _elevatedColor = Color(0xFFFBBF24);
const _highColor = Color(0xFFF97316);
const _muted = Color(0xFF94A3B8);

/// Color de cada zona, el mismo en puntos, bandas y leyenda.
Color glucoseZoneColor(GlucoseClassification c) {
  switch (c) {
    case GlucoseClassification.bajo:
      return _lowColor;
    case GlucoseClassification.enRango:
      return AppColors.metabolicGreen;
    case GlucoseClassification.elevado:
      return _elevatedColor;
    case GlucoseClassification.alto:
      return _highColor;
    case GlucoseClassification.sinUmbral:
      return _muted;
  }
}

/// Etiqueta corta (la de GlucoseClassification.label para "alto" es una
/// frase completa, no cabe en un chip).
String glucoseZoneShortLabel(GlucoseClassification c) {
  switch (c) {
    case GlucoseClassification.bajo:
      return 'Bajo';
    case GlucoseClassification.enRango:
      return 'En rango';
    case GlucoseClassification.elevado:
      return 'Elevado';
    case GlucoseClassification.alto:
      return 'Alto';
    case GlucoseClassification.sinUmbral:
      return '';
  }
}

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];
const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

String _dayMonth(DateTime d) => '${d.day} ${_meses[d.month - 1]}';

String _hour(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'a. m.' : 'p. m.'}';
}

String _contextTab(GlucoseReadingContext c) =>
    c == GlucoseReadingContext.ayunas ? 'En ayunas' : '2 h después de comer';

class GlucoseChart extends StatefulWidget {
  const GlucoseChart({
    super.key,
    required this.readings,
    this.now,
    this.height = 200,
  });

  /// Lecturas de cualquier contexto y en cualquier orden.
  final List<GlucoseReading> readings;

  /// Fin de la ventana. Por defecto, ahora (se inyecta en tests).
  final DateTime? now;
  final double height;

  @override
  State<GlucoseChart> createState() => _GlucoseChartState();
}

class _GlucoseChartState extends State<GlucoseChart> {
  GlucoseReadingContext _context = GlucoseReadingContext.ayunas;
  int _window = 30;
  int? _selected;

  List<GlucoseReadingContext> get _available => [
        for (final c in kGlucoseChartContexts)
          if (widget.readings.any((r) => r.context == c)) c,
      ];

  @override
  void initState() {
    super.initState();
    final available = _available;
    if (available.isNotEmpty) _context = available.first;
  }

  @override
  void didUpdateWidget(covariant GlucoseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readings != widget.readings) {
      _selected = null;
      final available = _available;
      if (available.isNotEmpty && !available.contains(_context)) {
        _context = available.first;
      }
    }
  }

  void _select(Offset local, Size size, GlucoseChartData data) {
    if (data.isEmpty) return;
    final g = _ChartGeometry(data, size);
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < data.points.length; i++) {
      final d = (g.xFor(data.points[i].at) - local.dx).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    if (bestDist <= 28 && best != _selected) {
      setState(() => _selected = best);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readings.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Todavía no hay lecturas para graficar.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
      );
    }

    final available = _available;
    if (available.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Tus lecturas son de momentos sin rango de referencia (antes de '
          'comer, 1 hora después o antes de dormir). Registra una en ayunas '
          'o 2 horas después de comer para verla aquí.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
      );
    }

    final data = GlucoseChartData.build(
      readings: widget.readings,
      context: _context,
      windowDays: _window,
      now: widget.now ?? DateTime.now(),
    )!;
    final selected = (_selected != null && _selected! < data.count)
        ? _selected
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (available.length > 1) ...[
          Row(
            children: [
              for (final c in available) ...[
                _Pill(
                  label: _contextTab(c),
                  selected: c == _context,
                  onTap: () => setState(() {
                    _context = c;
                    _selected = null;
                  }),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            for (final w in kGlucoseChartWindows) ...[
              _Pill(
                label: '$w días',
                selected: w == _window,
                compact: true,
                onTap: () => setState(() {
                  _window = w;
                  _selected = null;
                }),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _Readout(data: data, index: selected ?? data.count - 1,
            isSelection: selected != null, windowDays: _window),
        const SizedBox(height: 10),
        Semantics(
          label: data.isEmpty
              ? 'Gráfica de glucosa sin lecturas en este periodo'
              : 'Gráfica de glucosa ${_contextTab(_context).toLowerCase()}: '
                  '${data.count} lecturas, ${data.inRangeCount} en rango',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, widget.height);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _select(d.localPosition, size, data),
                onHorizontalDragUpdate: (d) =>
                    _select(d.localPosition, size, data),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CustomPaint(
                    painter: _GlucoseChartPainter(
                      data: data,
                      selected: selected,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (!data.isEmpty) ...[
          const SizedBox(height: 16),
          _Distribution(data: data),
        ],
        const SizedBox(height: 14),
        _Reference(bands: data.bands, readingContext: _context),
      ],
    );
  }
}

// ─── Encabezado: lectura seleccionada o la última ──────────────────────

class _Readout extends StatelessWidget {
  const _Readout({
    required this.data,
    required this.index,
    required this.isSelection,
    required this.windowDays,
  });

  final GlucoseChartData data;
  final int index;
  final bool isSelection;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text(
        'Sin lecturas ${_contextTab(data.context).toLowerCase()} en los '
        'últimos $windowDays días.',
        style: const TextStyle(color: _muted, fontSize: 13),
      );
    }
    final p = data.points[index];
    final color = glucoseZoneColor(p.classification);
    final when = '${_dias[p.at.weekday - 1]} ${_dayMonth(p.at)} · ${_hour(p.at)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                text: '${p.valueMgDl}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
                children: const [
                  TextSpan(
                    text: ' mg/dL',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                glucoseZoneShortLabel(p.classification),
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          isSelection ? when : 'Última lectura · $when',
          style: const TextStyle(color: _muted, fontSize: 11.5),
        ),
        if (!isSelection && data.count > 1)
          Text(
            'Toca la gráfica para ver cada lectura.',
            style: TextStyle(
              color: _muted.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

// ─── Distribución por zona ─────────────────────────────────────────────

class _Distribution extends StatelessWidget {
  const _Distribution({required this.data});

  final GlucoseChartData data;

  static const _order = [
    GlucoseClassification.bajo,
    GlucoseClassification.enRango,
    GlucoseClassification.elevado,
    GlucoseClassification.alto,
  ];

  @override
  Widget build(BuildContext context) {
    final mean = data.mean!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${data.inRangeCount} de ${data.count} '
          '${data.count == 1 ? 'lectura' : 'lecturas'} en rango '
          '(${data.inRangePercent} %)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Promedio ${mean.round()} mg/dL · mínimo ${data.minValue} · '
          'máximo ${data.maxValue}',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final c in _order)
                  if (data.countOf(c) > 0)
                    Expanded(
                      flex: data.countOf(c),
                      child: Container(color: glucoseZoneColor(c)),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            for (final c in _order)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: glucoseZoneColor(c),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${glucoseZoneShortLabel(c)} ${data.countOf(c)}',
                    style: TextStyle(
                      color: data.countOf(c) > 0
                          ? const Color(0xFFCBD5E1)
                          : _muted.withValues(alpha: 0.6),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Qué significan los rangos y de dónde salen ────────────────────────

class _Reference extends StatelessWidget {
  const _Reference({required this.bands, required this.readingContext});

  final GlucoseReferenceBands bands;
  final GlucoseReadingContext readingContext;

  @override
  Widget build(BuildContext context) {
    final b = bands;
    final ranges = 'Bajo: menos de ${b.lowBelow} · En rango: '
        '${b.lowBelow}–${b.inRangeBelow - 1} · Elevado: '
        '${b.inRangeBelow}–${b.highFrom - 1} · Alto: ${b.highFrom} o más '
        '(mg/dL).';
    final note = readingContext == GlucoseReadingContext.postprandial2h
        ? ' Los cortes de 2 horas vienen de la prueba de tolerancia oral '
            '(75 g de glucosa); después de una comida real son una '
            'referencia, no un diagnóstico.'
        : ' Son los cortes de la prueba de laboratorio; un glucómetro de '
            'casa sirve para ver tendencia, no para diagnosticar.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$ranges$note',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 4),
        const CitationLink(
          'Rangos de referencia: ADA 2025',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.25 : 0.10),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _muted,
              fontSize: compact ? 12 : 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Geometría compartida por el painter y el toque ────────────────────

class _ChartGeometry {
  _ChartGeometry(this.data, this.size) {
    final b = data.bands;
    final lo = data.minValue == null || data.minValue! > b.lowBelow
        ? b.lowBelow
        : data.minValue!;
    final hi = data.maxValue == null || data.maxValue! < b.highFrom
        ? b.highFrom
        : data.maxValue!;
    yMin = (((lo - 10) / 10).floor() * 10).clamp(30, 400).toDouble();
    yMax = (((hi + 15) / 10).ceil() * 10).clamp(yMin + 10, 420).toDouble();
    plot = Rect.fromLTRB(32, 8, size.width - 6, size.height - 20);
  }

  final GlucoseChartData data;
  final Size size;
  late final double yMin;
  late final double yMax;
  late final Rect plot;

  double yFor(num v) =>
      plot.bottom - ((v - yMin) / (yMax - yMin)) * plot.height;

  double xFor(DateTime t) {
    final span = data.windowEnd.difference(data.windowStart).inMilliseconds;
    if (span <= 0) return plot.center.dx;
    final f = t.difference(data.windowStart).inMilliseconds / span;
    return plot.left + f.clamp(0.0, 1.0) * plot.width;
  }
}

class _GlucoseChartPainter extends CustomPainter {
  _GlucoseChartPainter({required this.data, required this.selected});

  final GlucoseChartData data;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final g = _ChartGeometry(data, size);
    final b = data.bands;
    final plot = g.plot;

    // 1. Bandas por zona.
    void band(double from, double to, Color color) {
      final top = g.yFor(to.clamp(g.yMin, g.yMax));
      final bottom = g.yFor(from.clamp(g.yMin, g.yMax));
      if (bottom - top <= 0) return;
      canvas.drawRect(
        Rect.fromLTRB(plot.left, top, plot.right, bottom),
        Paint()..color = color.withValues(alpha: 0.10),
      );
    }

    band(g.yMin, b.lowBelow.toDouble(), _lowColor);
    band(b.lowBelow.toDouble(), b.inRangeBelow.toDouble(),
        AppColors.metabolicGreen);
    band(b.inRangeBelow.toDouble(), b.highFrom.toDouble(), _elevatedColor);
    band(b.highFrom.toDouble(), g.yMax, _highColor);

    // 2. Nombre de cada zona, a la derecha, si cabe.
    void zoneLabel(double from, double to, String text, Color color) {
      final top = g.yFor(to.clamp(g.yMin, g.yMax));
      final bottom = g.yFor(from.clamp(g.yMin, g.yMax));
      if (bottom - top < 14) return;
      _text(canvas, text, Offset(plot.right - 4, (top + bottom) / 2),
          color: color.withValues(alpha: 0.85),
          size: 9.5,
          weight: FontWeight.w700,
          alignRight: true,
          centerY: true);
    }

    zoneLabel(g.yMin, b.lowBelow.toDouble(), 'Bajo', _lowColor);
    zoneLabel(b.lowBelow.toDouble(), b.inRangeBelow.toDouble(), 'En rango',
        AppColors.metabolicGreen);
    zoneLabel(b.inRangeBelow.toDouble(), b.highFrom.toDouble(), 'Elevado',
        _elevatedColor);
    zoneLabel(b.highFrom.toDouble(), g.yMax, 'Alto', _highColor);

    // 3. Cortes con su valor en el eje.
    for (final cut in [b.lowBelow, b.inRangeBelow, b.highFrom]) {
      final y = g.yFor(cut);
      _dashed(canvas, Offset(plot.left, y), Offset(plot.right, y),
          Colors.white.withValues(alpha: 0.18));
      _text(canvas, '$cut', Offset(plot.left - 6, y),
          color: _muted, size: 10, alignRight: true, centerY: true);
    }

    // 4. Fechas del eje de tiempo.
    final mid = data.windowStart.add(
        data.windowEnd.difference(data.windowStart) ~/ 2);
    final labelY = plot.bottom + 5;
    _text(canvas, _dayMonth(data.windowStart), Offset(plot.left, labelY),
        color: _muted, size: 10);
    _text(canvas, _dayMonth(mid), Offset(plot.center.dx, labelY),
        color: _muted, size: 10, centerX: true);
    _text(canvas, 'hoy', Offset(plot.right, labelY),
        color: _muted, size: 10, alignRight: true);

    if (data.isEmpty) return;

    // 5. Promedio del periodo.
    final mean = data.mean!;
    final yMean = g.yFor(mean);
    _dashed(canvas, Offset(plot.left, yMean), Offset(plot.right, yMean),
        const Color(0xFFE879F9).withValues(alpha: 0.55),
        dash: 3, gap: 3);
    _text(canvas, 'prom. ${mean.round()}', Offset(plot.left + 4, yMean - 2),
        color: const Color(0xFFE879F9), size: 9.5, weight: FontWeight.w700,
        bottomY: true);

    // 6. Línea entre lecturas.
    final pts = [
      for (final p in data.points) Offset(g.xFor(p.at), g.yFor(p.valueMgDl)),
    ];
    if (pts.length > 1) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 7. Guía vertical de la lectura tocada.
    if (selected != null) {
      final x = pts[selected!].dx;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..strokeWidth = 1);
    }

    // 8. Puntos con el color de su zona.
    final ring = Paint()..color = const Color(0xFF1E293B);
    for (var i = 0; i < pts.length; i++) {
      final isSel = i == selected;
      canvas.drawCircle(pts[i], isSel ? 8 : 5.5, ring);
      canvas.drawCircle(pts[i], isSel ? 6 : 4,
          Paint()..color = glucoseZoneColor(data.points[i].classification));
    }
  }

  static void _dashed(Canvas canvas, Offset a, Offset b, Color color,
      {double dash = 4, double gap = 4}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = a.dx;
    while (x < b.dx) {
      final end = (x + dash) < b.dx ? x + dash : b.dx;
      canvas.drawLine(Offset(x, a.dy), Offset(end, a.dy), paint);
      x += dash + gap;
    }
  }

  static void _text(
    Canvas canvas,
    String text,
    Offset at, {
    required Color color,
    double size = 10,
    FontWeight weight = FontWeight.w500,
    bool alignRight = false,
    bool centerX = false,
    bool centerY = false,
    bool bottomY = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = at.dx;
    if (alignRight) dx -= tp.width;
    if (centerX) dx -= tp.width / 2;
    var dy = at.dy;
    if (centerY) dy -= tp.height / 2;
    if (bottomY) dy -= tp.height;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _GlucoseChartPainter old) =>
      old.data != data || old.selected != selected;
}
