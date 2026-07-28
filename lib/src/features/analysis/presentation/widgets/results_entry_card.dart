// 17-jul: Progreso pasó de mostrar todo el contenido inline a un set de
// 4 cards colapsadas (Insignias, Tus Resultados, Tus Hábitos, Tu racha),
// mismo patrón que BadgesEntryCard (widgets/../badges/badges_entry_card.dart)
// — pantalla más limpia, el detalle vive en su propia pantalla al tap.
//
// Esta card resume "Tus Resultados" (Score del día, IMR, Composición
// corporal) y navega a ResultadosDetailScreen (/analysis/resultados).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/chart_hero_computer.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';

class ResultsEntryCard extends ConsumerWidget {
  const ResultsEntryCard({super.key});

  static const _color = AppColors.accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // resolvedDailyScoreSeriesProvider ya resuelve a MetricSeries directo
    // (no AsyncValue) — mismo patrón que _dailyScoreTile en analysis_screen.
    final scoreSeries = ref.watch(resolvedDailyScoreSeriesProvider);
    final score =
        ChartHeroComputer.aggregateValue(scoreSeries, HeroAggregation.last);

    // Fix P1 (validación de ejecución real, 23-jul-2026): esta card
    // mostraba "Score X · IMR Y" con el mismo peso visual, sin jerarquía,
    // lo que reforzaba la confusión de "¿cuál número miro?" reportada en
    // la validación de ejecución real. Score del día pasa a ser la única
    // métrica visible en este resumen colapsado; el IMR sigue disponible
    // — sin perderse — un tap más adentro, en ResultadosDetailScreen.
    final subtitle = score == null
        ? 'Aún sin registros'
        : 'Score del día: ${ChartHeroComputer.formatValue(score)}';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/analysis/resultados'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.bar_chart_rounded, color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tus Resultados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
