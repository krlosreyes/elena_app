// SPEC-160 + SPEC-161 — Tab 3 Tendencia.
//
// Outcomes longitudinales del producto:
//   - IMR (resultado integral de los 5 pilares).
//   - Composición corporal (peso, cintura, %grasa, WHTR, masa magra).
//
// Ambos son OUTCOMES que el usuario observa cambiar como consecuencia
// del trabajo en los 5 pilares — NO son pilares.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/daily_summary_provider.dart';
import 'package:elena_app/src/features/analysis/application/merge_with_live.dart';
import 'package:elena_app/src/features/analysis/application/period_comparison_provider.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_period.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/body_composition_trend_chart.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_trend_chart.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/period_selector.dart';

class AnalysisTrendTab extends ConsumerStatefulWidget {
  const AnalysisTrendTab({super.key});

  @override
  ConsumerState<AnalysisTrendTab> createState() => _AnalysisTrendTabState();
}

class _AnalysisTrendTabState extends ConsumerState<AnalysisTrendTab>
    with AutomaticKeepAliveClientMixin {
  AnalysisPeriod _period = AnalysisPeriod.week;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dataAsync = ref.watch(periodDataProvider(_period));
    final liveToday = ref.watch(dailySummaryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodSelector(
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),
          // Sección IMR.
          _buildSectionLabel('IMR'),
          const SizedBox(height: 8),
          dataAsync.when(
            loading: _buildLoadingChart,
            error: (_, __) => _buildErrorBox(),
            data: (d) {
              final merged = mergeWithLive(
                persisted: d.currentDocs,
                live: liveToday,
              );
              return ImrTrendChart(
                docs: merged,
                daysInPeriod: _period.days,
              );
            },
          ),
          const SizedBox(height: 20),
          // SPEC-161: composición corporal migrada acá desde Pilares.
          // Es OUTCOME, no pilar.
          _buildSectionLabel('COMPOSICIÓN CORPORAL'),
          const SizedBox(height: 8),
          const BodyCompositionTrendChart(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildLoadingChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.metabolicGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'No pudimos cargar tu tendencia.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
    );
  }
}
