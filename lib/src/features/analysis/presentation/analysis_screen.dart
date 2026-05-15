// SPEC-113: pantalla Análisis rediseñada.
//
// PERF (post-SPEC-113): un solo watch sobre `periodDataProvider` que
// trae current + previous + comparison desde una sola query Firestore.
// 4 bloques visuales (hero, tendencia, heatmap, insights) comparten
// el mismo `.when()`.
//
// Estructura:
//   AppBar (acción: abrir vista calendario, SPEC-112)
//   - Selector temporal (Semana / Mes / 3 Meses)
//   - Hero card con IMR promedio + delta + mejor/peor día
//   - Tendencia (línea CustomPaint)
//   - Heatmap pilares × días
//   - Insights (3-4 cards)
//   - BottomNavigationBar

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/daily_summary_provider.dart';
import 'package:elena_app/src/features/analysis/application/insights_service.dart';
import 'package:elena_app/src/features/analysis/application/period_comparison_provider.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_period.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';
import 'package:elena_app/src/features/analysis/presentation/monthly_calendar_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_trend_chart.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/insight_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/period_hero_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/period_selector.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/pillars_heatmap.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  AnalysisPeriod _period = AnalysisPeriod.week;

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(periodDataProvider(_period));
    // SPEC-113.bugfix: el doc persistido de HOY tiene debounce de 30s.
    // Watcheamos el state LIVE y lo mezclamos para que la columna/
    // snapshot del día actual refleje cambios inmediatos (registrar
    // una comida, cerrar el ayuno, etc).
    final liveToday = ref.watch(dailySummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'ANÁLISIS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.4,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MonthlyCalendarScreen(),
                fullscreenDialog: true,
              ),
            ),
            tooltip: 'Ver mes',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PeriodSelector(
              selected: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
            const SizedBox(height: 16),
            dataAsync.when(
              loading: () => _loadingStack(),
              error: (e, st) => _errorBox(),
              data: (d) {
                final mergedDocs = _mergeWithLive(d.currentDocs, liveToday);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PeriodHeroCard(
                      data: d.comparison,
                      periodLabel: _period.label,
                    ),
                    const SizedBox(height: 14),
                    ImrTrendChart(
                      docs: mergedDocs,
                      daysInPeriod: _period.days,
                    ),
                    const SizedBox(height: 14),
                    PillarsHeatmap(
                      docs: mergedDocs,
                      daysInPeriod: _period.days,
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        'INSIGHTS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    ...InsightsService.generate(mergedDocs)
                        .map((i) => InsightCard(insight: i)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: AppColors.metabolicGreen,
        unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/analysis');
          if (index == 2) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  /// Skeleton stack: muestra los bloques en su forma final (alto
  /// aproximado y borderRadius) para evitar el "saltito" cuando llega
  /// la data. Un solo spinner central para no parpadear 4 veces.
  Widget _loadingStack() {
    Widget shimmer({required double height}) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                shimmer(height: 160),
                shimmer(height: 180),
                shimmer(height: 200),
                shimmer(height: 90),
              ],
            ),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.metabolicGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// SPEC-113.bugfix: reemplaza el doc persistido de HOY (que tiene
  /// debounce de 30s) por uno construido desde el state LIVE. Si no
  /// existía doc para hoy, lo agrega. Mantiene los docs anteriores
  /// intactos.
  List<DailySummaryDoc> _mergeWithLive(
    List<DailySummaryDoc> persisted,
    DailySummary live,
  ) {
    final now = DateTime.now();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final liveDoc = DailySummaryDoc(
      date: todayKey,
      imrScore: live.imrScore,
      fastingProgress: live.fastingProgress,
      sleepProgress: live.sleepProgress,
      hydrationProgress: live.hydrationProgress,
      exerciseProgress: live.exerciseProgress,
      mealsProgress: live.mealsProgress,
      updatedAt: now,
    );
    final result = <DailySummaryDoc>[];
    bool replaced = false;
    for (final d in persisted) {
      if (d.date == todayKey) {
        result.add(liveDoc);
        replaced = true;
      } else {
        result.add(d);
      }
    }
    if (!replaced) result.add(liveDoc);
    // El consumidor espera lista ordenada por fecha ascendente.
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Widget _errorBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'No pudimos cargar tu análisis.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
