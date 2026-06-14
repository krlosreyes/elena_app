// IMR POR PILARES — Gráfico de barras apiladas semanales.
//
// Cada barra = una semana. El total de la barra = promedio IMR de esa semana.
// El color de cada segmento = pilar, proporcional a su progreso relativo.
//
// Los 5 pilares y sus colores:
//   Ayuno       → verde    #10B981
//   Nutrición   → ámbar    #F59E0B
//   Hidratación → azul     #38BDF8
//   Ejercicio   → teal     #14B8A6
//   Sueño       → índigo   #818CF8

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';

// ─── Modelo ────────────────────────────────────────────────────────────────

class ImrWeekData {
  final DateTime weekStart;
  final double fastingAvg;
  final double sleepAvg;
  final double hydrationAvg;
  final double exerciseAvg;
  final double nutritionAvg;
  final double imrAvg;

  const ImrWeekData({
    required this.weekStart,
    required this.fastingAvg,
    required this.sleepAvg,
    required this.hydrationAvg,
    required this.exerciseAvg,
    required this.nutritionAvg,
    required this.imrAvg,
  });

  double get totalPillarProgress =>
      fastingAvg + sleepAvg + hydrationAvg + exerciseAvg + nutritionAvg;
}

// ─── Pilares ───────────────────────────────────────────────────────────────

class _Pilar {
  final String name;
  final Color color;
  final String emoji;
  final double Function(ImrWeekData) progress;

  const _Pilar({
    required this.name,
    required this.color,
    required this.emoji,
    required this.progress,
  });
}

const List<_Pilar> _pilares = [
  _Pilar(
    name: 'Ayuno',
    color: Color(0xFF10B981),
    emoji: '⏱',
    progress: _fastingOf,
  ),
  _Pilar(
    name: 'Nutrición',
    color: Color(0xFFF59E0B),
    emoji: '🥗',
    progress: _nutritionOf,
  ),
  _Pilar(
    name: 'Hidratación',
    color: Color(0xFF38BDF8),
    emoji: '💧',
    progress: _hydrationOf,
  ),
  _Pilar(
    name: 'Ejercicio',
    color: Color(0xFF14B8A6),
    emoji: '🏃',
    progress: _exerciseOf,
  ),
  _Pilar(
    name: 'Sueño',
    color: Color(0xFF818CF8),
    emoji: '🌙',
    progress: _sleepOf,
  ),
];

double _fastingOf(ImrWeekData d) => d.fastingAvg;
double _nutritionOf(ImrWeekData d) => d.nutritionAvg;
double _hydrationOf(ImrWeekData d) => d.hydrationAvg;
double _exerciseOf(ImrWeekData d) => d.exerciseAvg;
double _sleepOf(ImrWeekData d) => d.sleepAvg;

// ─── Widget ────────────────────────────────────────────────────────────────

class ImrPillarBarChart extends StatelessWidget {
  final List<DailySummaryDoc> docs;

  const ImrPillarBarChart({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    final weeks = _groupByWeek(docs);

    if (weeks.isEmpty) {
      return _emptyState();
    }

    // Hero: promedio del período.
    final avgImr = weeks.isEmpty
        ? 0.0
        : weeks.map((w) => w.imrAvg).reduce((a, b) => a + b) / weeks.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(avgImr),
          const SizedBox(height: 20),
          // Chart
          _buildChart(weeks),
          const SizedBox(height: 16),
          // Leyenda
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader(double avgImr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMR POR SEMANA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    avgImr.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PROMEDIO',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<ImrWeekData> weeks) {
    const double chartHeight = 180;
    const double barMaxHeight = chartHeight - 20;

    return SizedBox(
      height: chartHeight + 24, // + espacio para labels X
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Eje Y
          _buildYAxis(chartHeight),
          const SizedBox(width: 8),
          // Barras
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeks.map((week) {
                      return Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 2.5),
                          child: _buildBar(week, barMaxHeight),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                // Labels X
                Row(
                  children: weeks.map((week) {
                    return Expanded(
                      child: Text(
                        _weekLabel(week.weekStart),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYAxis(double chartHeight) {
    return SizedBox(
      width: 28,
      height: chartHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [100, 75, 50, 25, 0].map((v) {
          return Text(
            '$v',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.30),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBar(ImrWeekData week, double maxHeight) {
    final barHeight = (week.imrAvg / 100) * maxHeight;
    final total = week.totalPillarProgress;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Label valor
        Text(
          week.imrAvg.round().toString(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        // Barra apilada
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: barHeight.clamp(4.0, maxHeight),
            child: total <= 0
                ? Container(color: Colors.white.withValues(alpha: 0.10))
                : Column(
                    children: _pilares.reversed.map((pilar) {
                      final proportion = pilar.progress(week) / total;
                      return Expanded(
                        flex: (proportion * 1000).round().clamp(0, 1000),
                        child: Container(color: pilar.color),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _pilares.map((p) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: p.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              p.name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Center(
        child: Text(
          'Sin datos para este período',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static String _isoWeekKey(DateTime dt) {
    // Lunes de esa semana ISO
    final monday = dt.subtract(Duration(days: dt.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  static DateTime _mondayOf(DateTime dt) {
    return dt.subtract(Duration(days: dt.weekday - 1));
  }

  static String _weekLabel(DateTime monday) {
    return '${monday.day}/${monday.month}';
  }

  static double _avg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static List<ImrWeekData> _groupByWeek(List<DailySummaryDoc> docs) {
    final Map<String, List<DailySummaryDoc>> byWeek = {};

    for (final doc in docs) {
      final dt = DateTime.tryParse(doc.date);
      if (dt == null) continue;
      final key = _isoWeekKey(dt);
      byWeek.putIfAbsent(key, () => []).add(doc);
    }

    final weeks = byWeek.entries.map((entry) {
      final weekDocs = entry.value;
      final monday = _mondayOf(DateTime.parse(entry.key));
      return ImrWeekData(
        weekStart: monday,
        fastingAvg: _avg(weekDocs.map((d) => d.fastingProgress).toList()),
        sleepAvg: _avg(weekDocs.map((d) => d.sleepProgress).toList()),
        hydrationAvg:
            _avg(weekDocs.map((d) => d.hydrationProgress).toList()),
        exerciseAvg: _avg(weekDocs.map((d) => d.exerciseProgress).toList()),
        nutritionAvg: _avg(weekDocs.map((d) => d.mealsProgress).toList()),
        imrAvg:
            _avg(weekDocs.map((d) => d.imrScore.toDouble()).toList()),
      );
    }).toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

    return weeks;
  }
}
