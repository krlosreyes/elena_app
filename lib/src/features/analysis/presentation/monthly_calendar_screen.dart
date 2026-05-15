// SPEC-112: vista calendario mensual del IMR.
//
// Muestra un grid 7×N con todos los días del mes seleccionado. Cada
// celda incluye el número del día y un mini-anillo coloreado según
// el IMR persistido. Día actual destacado, días futuros placeholder.
// Chevrons para navegar entre meses.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/monthly_summaries_provider.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/calendar_day_cell.dart';

class MonthlyCalendarScreen extends ConsumerStatefulWidget {
  const MonthlyCalendarScreen({super.key});

  @override
  ConsumerState<MonthlyCalendarScreen> createState() =>
      _MonthlyCalendarScreenState();
}

class _MonthlyCalendarScreenState
    extends ConsumerState<MonthlyCalendarScreen> {
  late MonthKey _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = MonthKey.now();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat("MMMM 'de' yyyy", 'es')
        .format(_currentMonth.firstDay());

    final docsAsync = ref.watch(monthlySummariesProvider(_currentMonth));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(_capitalize(monthLabel)),
            const SizedBox(height: 8),
            _buildWeekdayHeader(),
            const SizedBox(height: 4),
            Expanded(
              child: docsAsync.when(
                data: (docs) => _buildGrid(docs),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.metabolicGreen,
                  ),
                ),
                error: (e, st) => Center(
                  child: Text(
                    'No pudimos cargar el mes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String monthLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            onPressed: () =>
                setState(() => _currentMonth = _currentMonth.previous()),
            tooltip: 'Mes anterior',
          ),
          Expanded(
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 0.3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
            onPressed: () =>
                setState(() => _currentMonth = _currentMonth.next()),
            tooltip: 'Mes siguiente',
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: labels
            .map(
              (l) => Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGrid(List<DailySummaryDoc> docs) {
    // Map fecha → IMR para lookup O(1).
    final byDate = <String, int>{};
    for (final d in docs) {
      byDate[d.date] = d.imrScore;
    }

    final firstDay = _currentMonth.firstDay();
    // weekday: lunes=1 ... domingo=7. Padding = weekday-1.
    final padding = firstDay.weekday - 1;
    final daysInMonth = _currentMonth.daysInMonth();
    final today = DateTime.now();

    // Total de celdas en el grid: padding + días.
    final totalCells = padding + daysInMonth;
    // Redondear arriba a múltiplo de 7 para llenar la última fila.
    final paddedTotal = ((totalCells + 6) ~/ 7) * 7;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 2,
      ),
      itemCount: paddedTotal,
      itemBuilder: (context, index) {
        if (index < padding) return const SizedBox.shrink();
        final dayNum = index - padding + 1;
        if (dayNum > daysInMonth) return const SizedBox.shrink();

        final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
        final dateKey =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final imr = byDate[dateKey];

        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));

        return CalendarDayCell(
          dayNumber: dayNum,
          imrScore: imr,
          isToday: isToday,
          isFuture: isFuture,
        );
      },
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
