// SPEC-160 Tab 1 — Resumen.
//
// Vista por defecto al abrir Análisis. 3 cards motivacionales:
// PeriodHeroCard (IMR del período) + WeeklyCoachingCard (pilar débil)
// + GoalsProgressDashboard (plan + progreso).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/daily_summary_provider.dart';
import 'package:elena_app/src/features/analysis/application/merge_with_live.dart';
import 'package:elena_app/src/features/analysis/application/period_comparison_provider.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_period.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/period_hero_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/period_selector.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/weekly_coaching_card.dart';
import 'package:elena_app/src/features/goals/presentation/goals_progress_dashboard.dart';

class AnalysisSummaryTab extends ConsumerStatefulWidget {
  const AnalysisSummaryTab({super.key});

  @override
  ConsumerState<AnalysisSummaryTab> createState() => _AnalysisSummaryTabState();
}

class _AnalysisSummaryTabState extends ConsumerState<AnalysisSummaryTab>
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
          dataAsync.when(
            loading: _buildLoadingHero,
            error: (_, __) => _buildErrorBox(),
            data: (d) {
              // mergedDocs por si en el futuro alguna card lo necesita.
              mergeWithLive(persisted: d.currentDocs, live: liveToday);
              return PeriodHeroCard(
                data: d.comparison,
                periodLabel: _period.label,
              );
            },
          ),
          const SizedBox(height: 14),
          const WeeklyCoachingCard(),
          const SizedBox(height: 14),
          const GoalsProgressDashboard(),
        ],
      ),
    );
  }

  Widget _buildLoadingHero() {
    return Container(
      height: 160,
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
        'No pudimos cargar tu resumen.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
    );
  }
}
