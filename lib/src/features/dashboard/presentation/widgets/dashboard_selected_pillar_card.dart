import 'package:flutter/material.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/dashboard/domain/selected_pillar.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/comidas_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/exercise_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/fasting_consciousness_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/hydration_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/sleep_pillar_card.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';

/// Tarjeta de soporte del pilar seleccionado — SPEC-72.4.
/// El dispatcher elige cuál renderizar según el pilar activo.
/// Cada tarjeta tiene su propia paleta y CTAs específicas.
///
/// SPEC-119: extraído de `_buildSelectedPillarCard` en
/// `dashboard_screen.dart` (ARCH-03). El parámetro `user` del método
/// original no se usaba en el cuerpo (dead param) y se omitió aquí;
/// `ref` tampoco se usaba. `setState(_selectedPillar = ...)` se
/// reemplazó por el callback `onSelectPillar`.
class DashboardSelectedPillarCard extends StatelessWidget {
  const DashboardSelectedPillarCard({
    super.key,
    required this.selectedPillar,
    required this.fastingState,
    required this.sleep,
    required this.hydration,
    required this.exercise,
    required this.nutrition,
    required this.onSelectPillar,
  });

  final SelectedPillar selectedPillar;
  final FastingState fastingState;
  final SleepState sleep;
  final HydrationState hydration;
  final ExerciseState exercise;
  final NutritionState nutrition;
  final ValueChanged<SelectedPillar> onSelectPillar;

  @override
  Widget build(BuildContext context) {
    return switch (selectedPillar) {
      SelectedPillar.ayuno => FastingConsciousnessCard(state: fastingState),
      SelectedPillar.sueno => SleepPillarCard(state: sleep),
      SelectedPillar.hidratacion => HydrationPillarCard(state: hydration),
      SelectedPillar.ejercicio => ExercisePillarCard(state: exercise),
      SelectedPillar.comidas => ComidasPillarCard(
          state: nutrition,
          isFastingActive: fastingState.isActive,
          onGoToFasting: () => onSelectPillar(SelectedPillar.ayuno),
        ),
    };
  }
}
