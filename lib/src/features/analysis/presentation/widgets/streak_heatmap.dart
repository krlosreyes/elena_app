// SPEC-256 RF-02: heatmap de racha estilo GitHub — 12 semanas, una celda
// por día. Muestra si el día calificó para la racha (StreakEntry.
// qualifiesForStreak), y marca con un pequeño escudo los días perdonados
// por una reserva (SPEC-255 RF-02, StreakEngine.computeProtectedDates).
//
// Complementa a StreakSummaryCard (el número) con el patrón: la cadena
// visible es parte del mecanismo motivacional, no solo un adorno (ver
// specs/SPEC-256-racha-en-progreso.md §2 — "don't break the chain",
// Cialdini consistency bias, loss aversion).

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
  static const _accent = Colors.orange; // mismo color que la flama del header
  static const _cellSize = 13.0;
  static const _cellGap = 3.0;

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  static const _weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna fija de etiquetas de día (solo L/X/V para no saturar).
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    children: List.generate(7, (i) {
                      final show = i == 0 || i == 2 || i == 4;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: _cellGap / 2,
                        ),
                        child: SizedBox(
                          height: _cellSize,
                          width: 14,
                          child: show
                              ? Text(
                                  _weekdayLabels[i],
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // arranca mostrando la semana actual
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthLabels(startOfGrid),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(_weeks, (week) {
                            return Padding(
                              padding: const EdgeInsets.only(right: _cellGap),
                              child: Column(
                                children: List.generate(7, (weekday) {
                                  final date = startOfGrid.add(
                                    Duration(days: week * 7 + weekday),
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: _cellGap / 2,
                                    ),
                                    child: _DayCell(
                                      entry: byDate[DayBoundaryResolver.dayKeyIso(date)],
                                      isFuture: date.isAfter(today),
                                      isProtected: protectedDates
                                          .contains(DayBoundaryResolver.dayKeyIso(date)),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          _legend(),
        ],
      ),
    );
  }

  Widget _buildMonthLabels(DateTime startOfGrid) {
    return Row(
      children: List.generate(_weeks, (week) {
        final date = startOfGrid.add(Duration(days: week * 7));
        // Mostrar el mes solo en la primera semana que cae en ese mes.
        final prevDate = week == 0 ? null : startOfGrid.add(Duration(days: (week - 1) * 7));
        final showLabel = week == 0 || (prevDate != null && prevDate.month != date.month);
        return Padding(
          padding: const EdgeInsets.only(right: _cellGap),
          child: SizedBox(
            width: _cellSize,
            child: showLabel
                ? Text(
                    _monthsShort[date.month - 1],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _legend() {
    return Row(
      children: [
        _legendSwatch(color: _accent.withValues(alpha: 0.18), isEmpty: true),
        const SizedBox(width: 6),
        Text(
          'sin registro',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 10),
        ),
        const SizedBox(width: 14),
        _legendSwatch(color: _accent, isEmpty: false),
        const SizedBox(width: 6),
        Text(
          'calificó',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 10),
        ),
        const SizedBox(width: 14),
        const Icon(Icons.shield_rounded, size: 11, color: Color(0xFFF59E0B)),
        const SizedBox(width: 4),
        Text(
          'protegido',
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
  final bool isFuture;
  final bool isProtected;

  const _DayCell({
    required this.entry,
    required this.isFuture,
    required this.isProtected,
  });

  @override
  Widget build(BuildContext context) {
    const size = StreakHeatmap._cellSize;

    if (isFuture) {
      return const SizedBox(width: size, height: size);
    }

    Color fill;
    Border? border;
    if (entry == null) {
      // Sin registro: hueco con borde sutil.
      fill = Colors.transparent;
      border = Border.all(
        color: StreakHeatmap._accent.withValues(alpha: 0.18),
        width: 1,
      );
    } else if (entry!.qualifiesForStreak) {
      fill = StreakHeatmap._accent;
    } else {
      // Registró algo, pero no llegó al mínimo — celda tenue proporcional
      // a pilares completados (0-5), nunca 0 (para distinguirla de
      // "sin registro").
      final ratio = (entry!.pillarsCompleted / 5.0).clamp(0.0, 1.0);
      fill = StreakHeatmap._accent.withValues(alpha: 0.15 + 0.35 * ratio);
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
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        if (isProtected)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
