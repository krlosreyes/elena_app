// SPEC-113 (rev. UX): visualización adaptativa del cumplimiento por
// pilar. Reemplaza el heatmap "puro" original — comunicaba mal con
// pocos días de data.
//
// Modos:
//   A) <3 días con data → "snapshot del último día": barras
//      horizontales con % numérico de cada pilar para el día más
//      reciente. Comunica en un vistazo aún con 1 día registrado.
//
//   B) ≥3 días con data → heatmap + columna de promedio del período
//      a la derecha. La columna PROM es el número que el usuario
//      lee primero; el heatmap aporta el patrón temporal.
//
// En ambos modos, "sin registro" se dibuja con borde punteado/hueco
// para distinguirlo claramente de "0% logrado".

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';

class PillarsHeatmap extends StatelessWidget {
  final List<DailySummaryDoc> docs;
  final int daysInPeriod;

  const PillarsHeatmap({
    super.key,
    required this.docs,
    required this.daysInPeriod,
  });

  static const _pillars = <_PillarRow>[
    _PillarRow('Ayuno', AppColors.metabolicGreen, pillarGetter: _getFasting),
    _PillarRow('Sueño', Color(0xFF818CF8), pillarGetter: _getSleep),
    _PillarRow('Hidrat.', Color(0xFF38BDF8), pillarGetter: _getHydration),
    _PillarRow('Ejerc.', Color(0xFF14B8A6), pillarGetter: _getExercise),
    _PillarRow('Comidas', Color(0xFFFB923C), pillarGetter: _getMeals),
  ];

  static double _getFasting(DailySummaryDoc d) => d.fastingProgress;
  static double _getSleep(DailySummaryDoc d) => d.sleepProgress;
  static double _getHydration(DailySummaryDoc d) => d.hydrationProgress;
  static double _getExercise(DailySummaryDoc d) => d.exerciseProgress;
  static double _getMeals(DailySummaryDoc d) => d.mealsProgress;

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  static const _monthsLong = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE',
  ];

  @override
  Widget build(BuildContext context) {
    // Modo adaptativo según cuántos días tienen registro.
    if (docs.length < 3) {
      return _SnapshotMode(
        docs: docs,
        pillars: _pillars,
        monthsShort: _monthsShort,
      );
    }
    return _HeatmapMode(
      docs: docs,
      daysInPeriod: daysInPeriod,
      pillars: _pillars,
      monthsLong: _monthsLong,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// MODO A — Snapshot (último día). Pocos datos.
// ─────────────────────────────────────────────────────────────────────

class _SnapshotMode extends StatelessWidget {
  final List<DailySummaryDoc> docs;
  final List<_PillarRow> pillars;
  final List<String> monthsShort;

  const _SnapshotMode({
    required this.docs,
    required this.pillars,
    required this.monthsShort,
  });

  @override
  Widget build(BuildContext context) {
    // Día más reciente con data.
    final sorted = [...docs]..sort((a, b) => b.date.compareTo(a.date));
    final last = sorted.isEmpty ? null : sorted.first;
    final lastDate = last != null ? _parseDate(last.date) : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TU DÍA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              if (lastDate != null)
                Text(
                  '${lastDate.day} ${monthsShort[lastDate.month - 1].toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (last == null)
            _emptyHint()
          else
            ...pillars.map(
              (p) => _PillarProgressBar(
                pillar: p,
                progress: p.pillarGetter(last),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            docs.length == 1
                ? 'Registra unos días más y verás tu patrón semanal aquí.'
                : 'Con un par de días más empezarás a ver tu patrón.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Aún no tienes registros en este período.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }

  static DateTime _parseDate(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }
}

class _PillarProgressBar extends StatelessWidget {
  final _PillarRow pillar;
  final double progress;
  const _PillarProgressBar({required this.pillar, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              pillar.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: pillar.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: pillar.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: pillar.color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// MODO B — Heatmap completo (≥3 días con data).
// ─────────────────────────────────────────────────────────────────────

class _HeatmapMode extends StatelessWidget {
  final List<DailySummaryDoc> docs;
  final int daysInPeriod;
  final List<_PillarRow> pillars;
  final List<String> monthsLong;

  const _HeatmapMode({
    required this.docs,
    required this.daysInPeriod,
    required this.pillars,
    required this.monthsLong,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = today.subtract(Duration(days: daysInPeriod - 1));

    final byDate = <String, DailySummaryDoc>{};
    for (final d in docs) {
      byDate[d.date] = d;
    }

    final cellSize = daysInPeriod <= 7
        ? 30.0
        : daysInPeriod <= 30
            ? 14.0
            : 7.0;

    // Promedio por pilar para los docs registrados (no para días sin
    // registro — esos no penalizan).
    final averages = <_PillarRow, int>{};
    for (final p in pillars) {
      if (docs.isEmpty) {
        averages[p] = 0;
        continue;
      }
      double sum = 0;
      for (final d in docs) {
        sum += p.pillarGetter(d).clamp(0.0, 1.0);
      }
      averages[p] = (sum / docs.length * 100).round();
    }

    final monthLabel = _monthHeader(rangeStart, today);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: título a la izquierda, mes a la derecha.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CUMPLIMIENTO POR PILAR',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                monthLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna fija: etiquetas de pilar.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: cellSize * 0.5),
                  ...pillars.map(
                    (p) => SizedBox(
                      height: cellSize + 4,
                      child: Center(
                        child: Text(
                          p.label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Grid scrollable de celdas.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: cellSize * 0.5,
                        child: _buildDayLabels(
                          daysInPeriod: daysInPeriod,
                          cellSize: cellSize,
                          rangeStart: rangeStart,
                        ),
                      ),
                      ...pillars.map(
                        (p) => _buildPillarRow(
                          pillar: p,
                          daysInPeriod: daysInPeriod,
                          rangeStart: rangeStart,
                          cellSize: cellSize,
                          byDate: byDate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Columna fija: % promedio del período.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    height: cellSize * 0.5,
                    child: Text(
                      'PROM',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  ...pillars.map(
                    (p) => SizedBox(
                      height: cellSize + 4,
                      child: Center(
                        child: Text(
                          '${averages[p] ?? 0}%',
                          style: TextStyle(
                            color: p.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontFeatures:
                                const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _legend(),
        ],
      ),
    );
  }

  String _monthHeader(DateTime rangeStart, DateTime today) {
    if (rangeStart.month == today.month && rangeStart.year == today.year) {
      return '${monthsLong[today.month - 1]} ${today.year}';
    }
    final startName = monthsLong[rangeStart.month - 1];
    final endName = monthsLong[today.month - 1];
    return '$startName–$endName ${today.year}';
  }

  Widget _buildDayLabels({
    required int daysInPeriod,
    required double cellSize,
    required DateTime rangeStart,
  }) {
    final step = daysInPeriod <= 7 ? 1 : 7;
    return Row(
      children: List.generate(daysInPeriod, (i) {
        final date = rangeStart.add(Duration(days: i));
        final showLabel = (i % step == 0);
        return SizedBox(
          width: cellSize + 2,
          child: showLabel
              ? Text(
                  '${date.day}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                )
              : const SizedBox.shrink(),
        );
      }),
    );
  }

  Widget _buildPillarRow({
    required _PillarRow pillar,
    required int daysInPeriod,
    required DateTime rangeStart,
    required double cellSize,
    required Map<String, DailySummaryDoc> byDate,
  }) {
    return SizedBox(
      height: cellSize + 4,
      child: Row(
        children: List.generate(daysInPeriod, (i) {
          final date = rangeStart.add(Duration(days: i));
          final key =
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final doc = byDate[key];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            child: _Cell(
              size: cellSize,
              base: pillar.color,
              progress: doc != null ? pillar.pillarGetter(doc) : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _legend() {
    return Row(
      children: [
        _legendItem(
          swatch: _CellSwatch.empty(color: pillars.first.color),
          label: 'sin registro',
        ),
        const SizedBox(width: 10),
        _legendItem(
          swatch: _CellSwatch.solid(
              color: pillars.first.color.withValues(alpha: 0.25)),
          label: 'bajo',
        ),
        const SizedBox(width: 10),
        _legendItem(
          swatch: _CellSwatch.solid(color: pillars.first.color),
          label: 'pleno',
        ),
      ],
    );
  }

  Widget _legendItem({required Widget swatch, required String label}) {
    return Row(
      children: [
        swatch,
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Celda del heatmap.
// ─────────────────────────────────────────────────────────────────────

class _Cell extends StatelessWidget {
  final double size;
  final Color base;

  /// `null` = sin registro ese día.
  /// `0.0..1.0` = % de cumplimiento.
  final double? progress;

  const _Cell({
    required this.size,
    required this.base,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      // Sin registro: borde discontinuo, fondo transparente.
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: Colors.white.withValues(alpha: 0.18),
            radius: size * 0.25,
          ),
        ),
      );
    }
    final p = progress!.clamp(0.0, 1.0);
    // Mapeo continuo: 0.0 → alpha 0.18, 1.0 → alpha 1.0.
    final alpha = 0.18 + 0.82 * p;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: base.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
    );
  }
}

class _CellSwatch extends StatelessWidget {
  final Color color;
  final bool isEmpty;
  const _CellSwatch.solid({required this.color}) : isEmpty = false;
  const _CellSwatch.empty({required this.color}) : isEmpty = true;

  @override
  Widget build(BuildContext context) {
    const sz = 10.0;
    if (isEmpty) {
      return SizedBox(
        width: sz,
        height: sz,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: Colors.white.withValues(alpha: 0.30),
            radius: 3,
          ),
        ),
      );
    }
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );

    // Path → metrics → dashes de 2-on / 2-off.
    final path = Path()..addRRect(rrect);
    const dash = 2.0;
    const gap = 2.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

// ─────────────────────────────────────────────────────────────────────
// Pilar row config.
// ─────────────────────────────────────────────────────────────────────

class _PillarRow {
  final String label;
  final Color color;
  final double Function(DailySummaryDoc) pillarGetter;
  const _PillarRow(this.label, this.color, {required this.pillarGetter});
}
