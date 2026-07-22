// SPEC-200 / SPEC-200.1: detalle del "Score del Día".
//
// Fuente: closedCycleScoreSeriesProvider — el score al momento del CIERRE
// del ciclo metabólico (MetabolicCycle.dailyScore), no el score en vivo.
//
// Rango: abre en Semana. Al salir restaura m1 para la pantalla Progreso.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_launcher.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/trend_comparison_computer.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/bar_chart_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/segmented_range_control.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/trend_comparison_card.dart';

class DailyScoreDetailScreen extends ConsumerStatefulWidget {
  const DailyScoreDetailScreen({super.key});

  @override
  ConsumerState<DailyScoreDetailScreen> createState() =>
      _DailyScoreDetailScreenState();
}

class _DailyScoreDetailScreenState
    extends ConsumerState<DailyScoreDetailScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analysisRangeProvider.notifier).state = AnalysisRange.w1;
    });
  }

  @override
  void dispose() {
    // BUGFIX (2026-06-14): la mutación de analysisRangeProvider propaga
    // sincronamente la invalidación de dailyScoreSeriesProvider al widget
    // mientras está en medio del teardown → "Cannot use ref after disposed".
    // try-catch defensivo: el valor se restaura correctamente en el caso
    // feliz; en el caso de error (ProviderScope teardown, hot-restart en
    // debug), el estado se resetea en el siguiente cold start sin impacto.
    try {
      ref.read(analysisRangeProvider.notifier).state = AnalysisRange.m1;
    } catch (_) {}
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analysisRangeProvider);
    // SPEC-197: detalle Score del Día.
    //
    // UX-PROGRESO (auditoría técnica 21-jul, P1): antes esto bloqueaba
    // TODO el detalle con un blur, incluso el gráfico de 7 días. Ahora
    // Free siempre ve la semana (rango w1, default al abrir esta
    // pantalla); el histórico más largo (`SegmentedRangeControl.locked`)
    // y la sección de Tendencia siguen requiriendo Premium/Trial.
    final isPremium = ref.watch(featureGateProvider).hasFullAccess;

    // UX-PROGRESO (hallazgo de auditoría propia, 22-jul): el reset a w1
    // en initState corre en addPostFrameCallback (a propósito — mutar
    // el provider de forma síncrona en initState puede disparar
    // "modify provider while widget tree is building"). Eso deja UN
    // frame donde `range` todavía puede ser el rango largo que el
    // usuario tenía seleccionado en la lista de Progreso, ANTES del
    // callback. Este guard corta ACÁ, antes de watchear los series
    // providers de abajo — así ese frame no dispara ninguna query con
    // un rango que Free no debería poder ver.
    if (!isPremium && range != AnalysisRange.w1) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.metabolicGreen,
          ),
        ),
      );
    }

    final mode = AggregationMode.forRange(range);
    // SPEC-219 rev2: fuente ÚNICA — ciclos cerrados con dailyScore.
    // Sin fallback a streak (scores distintos causaban flip-flop).
    final series = ref.watch(resolvedDailyScoreSeriesProvider);
    // Spinner mientras el stream de ciclos no haya emitido aún.
    final seriesAsync = ref.watch(closedCycleScoreSeriesProvider);
    final showSpinner = seriesAsync.isLoading && series.points.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkResponse(
                  onTap: () => context.pop(),
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Score del día',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 18),
              SegmentedRangeControl(
                locked: !isPremium,
                onLockedTap: () => openPaywall(
                  context, ref,
                  feature: GatedFeature.analyticsHistory,
                ),
              ),
              const SizedBox(height: 24),
              if (showSpinner)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                // UX-PROGRESO: el chart de la semana (w1) es siempre
                // visible, Free incluido.
                BarChartCard(
                  series: series,
                  accent: AppColors.metabolicGreen,
                  periodLabel: range.periodLabel,
                  headline: 'Score al cierre de cada día metabólico.',
                  aggregationMode: mode,
                  heroAggregation: HeroAggregation.avg,
                  heroUnit: '',
                  targetValue: 100,
                  targetLabel: 'Meta 100',
                  deltaIsBetterIf: 'up',
                ),
                const SizedBox(height: 24),
                if (isPremium)
                  _buildTrendSection(series, mode)
                else
                  _buildHistoryUpsellCard(context),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'Tu puntaje refleja cómo viviste cada día metabólico al '
                  'momento de cerrarlo — llega a 100 cuando cumples los 5 '
                  'pilares. Es distinto del IMR, que mide tu estado '
                  'metabólico de fondo y se mueve en semanas.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// UX-PROGRESO (21-jul, P1): reemplaza al antiguo blur de página
  /// completa (`_buildPremiumGateOverlay`). Se muestra una sola vez,
  /// debajo del chart de 7 días.
  Widget _buildHistoryUpsellCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppColors.metabolicGreen.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tendencia y análisis de evolución',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ya ves tu semana. Con Premium desbloqueas meses de histórico '
            'y comparativas de corto vs. largo plazo de tu Score del Día.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.metabolicGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => openPaywall(
                context, ref,
                feature: GatedFeature.analyticsHistory,
              ),
              child: const Text(
                'Desbloquear Premium',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(MetricSeries series, AggregationMode mode) {
    final trend = TrendComparisonComputer.compute(
      series: series,
      mode: mode,
      betterIf: 'up',
    );
    if (trend == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'Tendencia',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
        ),
        TrendComparisonCard(
          label: 'Score del día',
          unit: '',
          accent: AppColors.metabolicGreen,
          trend: trend,
          mode: mode,
        ),
      ],
    );
  }
}
