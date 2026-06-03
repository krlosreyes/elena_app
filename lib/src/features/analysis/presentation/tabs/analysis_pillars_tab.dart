// SPEC-160 Tab 2 — Pilares.
//
// Deep dive por pilar con chip-selector interno. Solo una card visible
// a la vez según el chip activo. Estado local del chip se conserva
// vía AutomaticKeepAlive — cambiar de tab y volver mantiene el pilar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/body_composition_trend_chart.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/sleep_quality_card.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycles_history_card.dart';
import 'package:elena_app/src/features/nutrition/presentation/widgets/meals_ratio_card.dart';

enum _ActivePillar { fasting, nutrition, sleep, body }

extension on _ActivePillar {
  String get label {
    switch (this) {
      case _ActivePillar.fasting:
        return 'Ayuno';
      case _ActivePillar.nutrition:
        return 'Nutrición';
      case _ActivePillar.sleep:
        return 'Sueño';
      case _ActivePillar.body:
        return 'Cuerpo';
    }
  }

  Color get accent {
    switch (this) {
      case _ActivePillar.fasting:
        return AppColors.metabolicGreen;
      case _ActivePillar.nutrition:
        return const Color(0xFFFB923C);
      case _ActivePillar.sleep:
        return const Color(0xFF818CF8);
      case _ActivePillar.body:
        return const Color(0xFF60A5FA);
    }
  }
}

class AnalysisPillarsTab extends ConsumerStatefulWidget {
  const AnalysisPillarsTab({super.key});

  @override
  ConsumerState<AnalysisPillarsTab> createState() =>
      _AnalysisPillarsTabState();
}

class _AnalysisPillarsTabState extends ConsumerState<AnalysisPillarsTab>
    with AutomaticKeepAliveClientMixin {
  _ActivePillar _active = _ActivePillar.fasting;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildChipSelector(),
          const SizedBox(height: 16),
          _buildActiveCard(),
        ],
      ),
    );
  }

  Widget _buildChipSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _ActivePillar.values.map((p) {
          final isSelected = p == _active;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _active = p),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? p.accent.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? p.accent.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    color: isSelected ? p.accent : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveCard() {
    switch (_active) {
      case _ActivePillar.fasting:
        return const CyclesHistoryCard();
      case _ActivePillar.nutrition:
        return const MealsRatioCard();
      case _ActivePillar.sleep:
        return const SleepQualityCard();
      case _ActivePillar.body:
        return const BodyCompositionTrendChart();
    }
  }
}
