// IMR POR PILARES — Gráfico de barras apiladas consciente del rango.
//
// Semana / Mes   → una barra por DÍA   (etiqueta: "L 9", "M 10" …)
// 3M / 6M        → una barra por SEMANA (etiqueta: "1/6")
// 1A             → una barra por MES    (etiqueta: "jun")
//
// Altura total = promedio IMR del período. Segmentos de color = proporción
// relativa del progreso de cada pilar dentro de esa barra.
//
// Colores de pilar:
//   Ayuno       → #10B981
//   Nutrición   → #F59E0B
//   Hidratación → #38BDF8
//   Ejercicio   → #14B8A6
//   Sueño       → #818CF8

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';

// ─── Modelo interno ────────────────────────────────────────────────────────

class _BarData {
  final DateTime date;  // para ordenar
  final String label;   // texto eje X
  final double fastingAvg;
  final double sleepAvg;
  final double hydrationAvg;
  final double exerciseAvg;
  final double nutritionAvg;
  final double imrAvg;

  const _BarData({
    required this.date,
    required this.label,
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
  final double Function(_BarData) progress;
  const _Pilar({required this.name, required this.color, required this.progress});
}

const List<_Pilar> _pilares = [
  _Pilar(name: 'Ayuno',       color: Color(0xFF10B981), progress: _fastingOf),
  _Pilar(name: 'Nutrición',   color: Color(0xFFF59E0B), progress: _nutritionOf),
  _Pilar(name: 'Hidratación', color: Color(0xFF38BDF8), progress: _hydrationOf),
  _Pilar(name: 'Ejercicio',   color: Color(0xFFEF4444), progress: _exerciseOf),
  _Pilar(name: 'Sueño',       color: Color(0xFF818CF8), progress: _sleepOf),
];

double _fastingOf(_BarData d) => d.fastingAvg;
double _nutritionOf(_BarData d) => d.nutritionAvg;
double _hydrationOf(_BarData d) => d.hydrationAvg;
double _exerciseOf(_BarData d) => d.exerciseAvg;
double _sleepOf(_BarData d) => d.sleepAvg;

// ─── Etiquetas ─────────────────────────────────────────────────────────────

const _weekdayAbbr = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];
const _monthAbbr = [
  '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _dayLabel(DateTime dt) => '${_weekdayAbbr[dt.weekday]} ${dt.day}';
String _weekLabel(DateTime monday) => '${monday.day}/${monday.month}';
String _monthLabel(DateTime dt) => _monthAbbr[dt.month];

// ─── Widget ────────────────────────────────────────────────────────────────

class ImrPillarBarChart extends StatelessWidget {
  final List<DailySummaryDoc> docs;
  final AggregationMode mode;

  const ImrPillarBarChart({
    super.key,
    required this.docs,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final bars = _buildBars(docs, mode);

    if (bars.isEmpty) return _emptyState();

    final avgImr = bars.map((b) => b.imrAvg).reduce((a, b) => a + b) / bars.length;

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
          _buildHeader(avgImr),
          const SizedBox(height: 20),
          _buildChart(bars),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(double avgImr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _chartTitle(mode),
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
      ],
    );
  }

  // ─── Chart ───────────────────────────────────────────────────────────────

  Widget _buildChart(List<_BarData> bars) {
    const double chartHeight = 180;
    const double barMaxHeight = chartHeight - 20;

    return SizedBox(
      height: chartHeight + 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildYAxis(chartHeight),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: bars.map((bar) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _buildBar(bar, barMaxHeight),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: bars.map((bar) {
                    return Expanded(
                      child: Text(
                        bar.label,
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

  Widget _buildBar(_BarData bar, double maxHeight) {
    final barHeight = (bar.imrAvg / 100) * maxHeight;
    final total = bar.totalPillarProgress;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          bar.imrAvg.round().toString(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: barHeight.clamp(4.0, maxHeight),
            child: total <= 0
                ? Container(color: Colors.white.withValues(alpha: 0.10))
                : Column(
                    children: _pilares.reversed.map((pilar) {
                      final proportion = pilar.progress(bar) / total;
                      return Expanded(
                        flex: (proportion * 1000).round().clamp(1, 1000),
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

  // ─── Helpers estáticos ───────────────────────────────────────────────────

  static String _chartTitle(AggregationMode mode) {
    switch (mode) {
      case AggregationMode.daily:
        return 'IMR POR DÍA';
      case AggregationMode.weekly:
        return 'IMR POR SEMANA';
      case AggregationMode.monthly:
        return 'IMR POR MES';
    }
  }

  static double _avg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static List<_BarData> _buildBars(
      List<DailySummaryDoc> docs, AggregationMode mode) {
    switch (mode) {
      case AggregationMode.daily:
        return _groupByDay(docs);
      case AggregationMode.weekly:
        return _groupByWeek(docs);
      case AggregationMode.monthly:
        return _groupByMonth(docs);
    }
  }

  // Una barra por día.
  static List<_BarData> _groupByDay(List<DailySummaryDoc> docs) {
    final Map<String, DailySummaryDoc> byDay = {};
    for (final doc in docs) {
      byDay[doc.date] = doc; // doc.date = "yyyy-MM-dd"
    }
    return byDay.entries.map((e) {
      final d = e.value;
      final dt = DateTime.parse(e.key);
      return _BarData(
        date: dt,
        label: _dayLabel(dt),
        fastingAvg: d.fastingProgress,
        sleepAvg: d.sleepProgress,
        hydrationAvg: d.hydrationProgress,
        exerciseAvg: d.exerciseProgress,
        nutritionAvg: d.mealsProgress,
        imrAvg: d.imrScore.toDouble(),
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // Una barra por semana ISO (lunes).
  static List<_BarData> _groupByWeek(List<DailySummaryDoc> docs) {
    final Map<String, List<DailySummaryDoc>> byWeek = {};
    for (final doc in docs) {
      final dt = DateTime.tryParse(doc.date);
      if (dt == null) continue;
      final monday = dt.subtract(Duration(days: dt.weekday - 1));
      final key =
          '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
      byWeek.putIfAbsent(key, () => []).add(doc);
    }
    return byWeek.entries.map((entry) {
      final weekDocs = entry.value;
      final monday = DateTime.parse(entry.key);
      return _BarData(
        date: monday,
        label: _weekLabel(monday),
        fastingAvg: _avg(weekDocs.map((d) => d.fastingProgress).toList()),
        sleepAvg: _avg(weekDocs.map((d) => d.sleepProgress).toList()),
        hydrationAvg: _avg(weekDocs.map((d) => d.hydrationProgress).toList()),
        exerciseAvg: _avg(weekDocs.map((d) => d.exerciseProgress).toList()),
        nutritionAvg: _avg(weekDocs.map((d) => d.mealsProgress).toList()),
        imrAvg: _avg(weekDocs.map((d) => d.imrScore.toDouble()).toList()),
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // Una barra por mes.
  static List<_BarData> _groupByMonth(List<DailySummaryDoc> docs) {
    final Map<String, List<DailySummaryDoc>> byMonth = {};
    for (final doc in docs) {
      final dt = DateTime.tryParse(doc.date);
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(doc);
    }
    return byMonth.entries.map((entry) {
      final monthDocs = entry.value;
      final dt = DateTime.parse('${entry.key}-01');
      return _BarData(
        date: dt,
        label: _monthLabel(dt),
        fastingAvg: _avg(monthDocs.map((d) => d.fastingProgress).toList()),
        sleepAvg: _avg(monthDocs.map((d) => d.sleepProgress).toList()),
        hydrationAvg: _avg(monthDocs.map((d) => d.hydrationProgress).toList()),
        exerciseAvg: _avg(monthDocs.map((d) => d.exerciseProgress).toList()),
        nutritionAvg: _avg(monthDocs.map((d) => d.mealsProgress).toList()),
        imrAvg: _avg(monthDocs.map((d) => d.imrScore.toDouble()).toList()),
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
