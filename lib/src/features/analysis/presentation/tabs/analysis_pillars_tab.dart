// SPEC-160 + SPEC-161 — Tab 2 Pilares.
//
// SPEC-161: corrige la incoherencia de SPEC-160. Los 5 chips son los
// 5 pilares OFICIALES del producto (Ayuno, Nutrición, Hidratación,
// Ejercicio, Sueño). Composición corporal NO es pilar — es OUTCOME
// y vive en el tab Tendencia.
//
// Estado local del chip se conserva vía AutomaticKeepAlive.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/hydration_weekly_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/sleep_quality_card.dart';
import 'package:elena_app/src/features/exercise/presentation/widgets/exercise_weekly_card.dart';
// Propuesta módulo Ejercicio (2026-07-21): split semanal del plan
// fuerza+cardio generado por WeeklyExercisePlanEngine. Se renderiza
// arriba de ExerciseWeeklyCard; si el usuario no tiene plan (perfil de
// ejercicio incompleto), no pinta nada — cero regresión.
import 'package:elena_app/src/features/exercise/presentation/widgets/weekly_plan_split_card.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycles_history_card.dart';
import 'package:elena_app/src/features/nutrition/presentation/widgets/meals_ratio_card.dart';

/// Los 5 pilares OFICIALES del producto.
enum _ActivePillar { fasting, nutrition, hydration, exercise, sleep }

extension on _ActivePillar {
  String get label {
    switch (this) {
      case _ActivePillar.fasting:
        return 'Ayuno';
      case _ActivePillar.nutrition:
        return 'Nutrición';
      case _ActivePillar.hydration:
        return 'Hidratación';
      case _ActivePillar.exercise:
        return 'Ejercicio';
      case _ActivePillar.sleep:
        return 'Sueño';
    }
  }

  Color get accent {
    switch (this) {
      case _ActivePillar.fasting:
        return AppColors.metabolicGreen;
      case _ActivePillar.nutrition:
        return const Color(0xFFFB923C);
      case _ActivePillar.hydration:
        return const Color(0xFF38BDF8);
      case _ActivePillar.exercise:
        return const Color(0xFF14B8A6);
      case _ActivePillar.sleep:
        return const Color(0xFF818CF8);
    }
  }
}

class AnalysisPillarsTab extends ConsumerStatefulWidget {
  const AnalysisPillarsTab({super.key});

  @override
  ConsumerState<AnalysisPillarsTab> createState() => _AnalysisPillarsTabState();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      case _ActivePillar.hydration:
        return const HydrationWeeklyCard();
      case _ActivePillar.exercise:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WeeklyPlanSplitCard(),
            ExerciseWeeklyCard(),
          ],
        );
      case _ActivePillar.sleep:
        return const SleepQualityCard();
    }
  }
}
