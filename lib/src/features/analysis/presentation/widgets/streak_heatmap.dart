// SPEC-256 RF-02: heatmap de racha estilo GitHub — 12 semanas, una celda
// por día. Muestra si el día calificó para la racha (StreakEntry.
// qualifiesForStreak), y marca con un pequeño escudo los días perdonados
// por una reserva (SPEC-255 RF-02, StreakEngine.computeProtectedDates).
//
// Complementa a StreakSummaryCard (el número) con el patrón: la cadena
// visible es parte del mecanismo motivacional, no solo un adorno (ver
// specs/SPEC-256-racha-en-progreso.md §2 — "don't break the chain",
// Cialdini consistency bias, loss aversion).
//
// REESCRITO (2026-07-13, feedback directo de Carlos: "esta gráfica es
// un asco, no comunica nada, es difícil de entender"). Causas raíz de
// la v1 y su fix:
//   1. Labels de día (L/X/V) y celdas vivían en dos Columns hermanas con
//      distinto ritmo vertical (la columna de celdas tenía una fila de
//      meses + gap que la columna de labels no tenía) → quedaban
//      visualmente desalineadas. Fix: una sola fila por día de semana,
//      label y celdas en el MISMO Row — imposible que se desalineen.
//   2. SingleChildScrollView + Expanded dejaba metros de fondo vacío a
//      la izquierda (12 semanas de 13px caben sobradas en el ancho de
//      una card — no hacía falta scroll). Fix: LayoutBuilder calcula el
//      tamaño de celda para llenar el ancho disponible, sin scroll.
//   3. Los labels de mes se cortaban ("ab" / "r") por muy poco ancho.
//      Fix: columna de mes = celda + gap completos, softWrap:false.
//   4. El degradado continuo de alpha para "registró pero no calificó"
//      se veía como un café/oliva sucio sobre el fondo oscuro — no como
//      "el mismo naranja pero más tenue". Fix: dos colores sólidos y
//      distintos (naranja = calificó, gris pizarra = registró sin
//      calificar) en vez de una mezcla continua.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

class StreakHeatmap extends StatelessWidget {
  final List<StreakEntry> history;
  final Set<String> protectedDates;

  const StreakHeatmap({
    super.key,
    required this.history,
    required this.protectedDates,
  });

  static const int _weeks = 12;
  static const int _totalDays = _weeks * 7;
  static const _qualifiedColor = Colors.orange; // mismo color que la flama del header
  static const _loggedColor = Color(0xFF64748B); // gris pizarra: "intentó, no calificó"
  static const _protectedColor = Color(0xFFF59E0B);
  static const _cellGap = 4.0;
  static const _labelColumnWidth = 16.0;
  static const _minCellSize = 12.0;
  static const _maxCellSize = 20.0;

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  static const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _labeledWeekdays = {0, 2, 4}; // Lun, Mié, Vie — igual que GitHub

  @override
  Widget build(BuildContext context) {
    final byDate = <String, StreakEntry>{};
    for (final e in history) {
      byDate[e.date] = e;
    }

    final today = DayBoundaryResolver.startOfDay(DateTime.now());
    // Alinear la última columna a la semana en curso (lunes-domingo) para
    // que el grid siempre termine "hoy", como el contribution graph de
    // GitHub.
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));
    final startOfGrid = endOfWeek.subtract(const Duration(days: _totalDays - 1));
    final todayKey = DayBoundaryResolver.dayKeyIso(today);

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
            'ÚLTIMAS 12 SEMANAS',
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
            LayoutBuilder(
              builder: (context, constraints) {
                final gridWidth =
                    constraints.maxWidth - _labelColumnWidth - _cellGap;
                final rawCell = (gridWidth - (_weeks - 1) * _cellGap) / _weeks;
                final cellSize =
                    rawCell.clamp(_minCellSize, _maxCellSize).toDouble();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthHeader(startOfGrid, cellSize),
                    const SizedBox(height: 4),
                    ...List.generate(
                      7,
                      (weekday) => _buildWeekdayRow(
                        weekday: weekday,
                        startOfGrid: startOfGrid,
                        cellSize: cellSize,
                        byDate: byDate,
                        today: today,
                        todayKey: todayKey,
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 14),
          _legend(),
        ],
      ),
    );
  }

  /// Fila de labels de mes, en la MISMA escala de columnas (cellSize +
  /// gap) que las filas de días — así queda alineada por construcción,
  /// sin depender de que dos widgets hermanos compartan ritmo vertical.
  Widget _buildMonthHeader(DateTime startOfGrid, double cellSize) {
    return Padding(
      padding: const EdgeInsets.only(left: _labelColumnWidth + _cellGap),
      child: Row(
        children: List.generate(_weeks, (week) {
          final date = startOfGrid.add(Duration(days: week * 7));
          final prevDate =
              week == 0 ? null : startOfGrid.add(Duration(days: (week - 1) * 7));
          final showLabel =
              week == 0 || (prevDate != null && prevDate.month != date.month);
          return SizedBox(
            width: cellSize + _cellGap,
            child: showLabel
                ? Text(
                    _monthsShort[date.month - 1],
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          );
        }),
      ),
    );
  }

  /// Una fila = un día de la semana. El label y las 12 celdas viven en
  /// el mismo Row, así que NUNCA pueden desalinearse verticalmente.
  Widget _buildWeekdayRow({
    required int weekday, // 0=Lun .. 6=Dom
    required DateTime startOfGrid,
    required double cellSize,
    required Map<String, StreakEntry> byDate,
    required DateTime today,
    required String todayKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _cellGap / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelColumnWidth,
            child: _labeledWeekdays.contains(weekday)
                ? Text(
                    _weekdayLabels[weekday],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: _cellGap),
          ...List.generate(_weeks, (week) {
            final date = startOfGrid.add(Duration(days: week * 7 + weekday));
            final key = DayBoundaryResolver.dayKeyIso(date);
            return Padding(
              padding: const EdgeInsets.only(right: _cellGap),
              child: _DayCell(
                entry: byDate[key],
                size: cellSize,
                isFuture: date.isAfter(today),
                isProtected: protectedDates.contains(key),
                isToday: key == todayKey,
              ),
            );
          }),
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
        _legendItem(
          swatch: _legendSwatch(color: _qualifiedColor.withValues(alpha: 0.18), isEmpty: true),
          label: 'sin registro',
        ),
        _legendItem(
          swatch: _legendSwatch(color: _loggedColor, isEmpty: false),
          label: 'registró, no calificó',
        ),
        _legendItem(
          swatch: _legendSwatch(color: _qualifiedColor, isEmpty: false),
          label: 'calificó',
        ),
        _legendItem(
          swatch: const Icon(Icons.circle, size: 10, color: _protectedColor),
          label: 'protegido',
        ),
      ],
    );
  }

  Widget _legendItem({required Widget swatch, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 10),
        ),
      ],
    );
  }

  Widget _legendSwatch({required Color color, required bool isEmpty}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isEmpty ? Colors.transparent : color,
        border: isEmpty ? Border.all(color: color, width: 1) : null,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final StreakEntry? entry;
  final double size;
  final bool isFuture;
  final bool isProtected;
  final bool isToday;

  const _DayCell({
    required this.entry,
    required this.size,
    required this.isFuture,
    required this.isProtected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    if (isFuture) {
      return SizedBox(width: size, height: size);
    }

    Color fill;
    Border? border;
    if (entry == null) {
      // Sin registro: hueco con borde sutil.
      fill = Colors.transparent;
      border = Border.all(
        color: Colors.white.withValues(alpha: 0.14),
        width: 1,
      );
    } else if (entry!.qualifiesForStreak) {
      fill = StreakHeatmap._qualifiedColor;
    } else {
      // Registró algo, pero no llegó al mínimo. Color SÓLIDO y distinto
      // (no una versión "apagada" del naranja) para que se lea como un
      // tercer estado claro, no como un naranja sucio.
      fill = StreakHeatmap._loggedColor;
    }

    if (isToday) {
      border = Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            border: border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        if (isProtected)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: StreakHeatmap._protectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
