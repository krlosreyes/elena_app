import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/selected_pillar.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/comidas_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/exercise_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/fasting_consciousness_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/hydration_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/sleep_pillar_card.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
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
///
/// STATE-01 (auditoría técnica 21-jul): antes recibía los 5 estados de
/// pilar completos por constructor (resueltos por el watch amplio de
/// DashboardScreen) aunque el `switch` de abajo SIEMPRE renderiza uno
/// solo — los otros 4 llegaban sin usarse en cada build. Ahora es
/// ConsumerWidget y solo lee, vía `ref.watch`, el provider del pilar
/// que el `switch` realmente va a pintar.
class DashboardSelectedPillarCard extends ConsumerWidget {
  const DashboardSelectedPillarCard({
    super.key,
    required this.selectedPillar,
    required this.onSelectPillar,
  });

  final SelectedPillar selectedPillar;
  final ValueChanged<SelectedPillar> onSelectPillar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (selectedPillar) {
      SelectedPillar.ayuno => FastingConsciousnessCard(
          state: ref.watch(fastingProvider),
        ),
      SelectedPillar.sueno => SleepPillarCard(
          state: ref.watch(sleepProvider),
        ),
      SelectedPillar.hidratacion => HydrationPillarCard(
          state: ref.watch(hydrationProvider),
        ),
      SelectedPillar.ejercicio => ExercisePillarCard(
          state: ref.watch(exerciseProvider),
        ),
      SelectedPillar.comidas => ComidasPillarCard(
          state: ref.watch(nutritionProvider),
          isFastingActive: ref.watch(
            fastingProvider.select((s) => s.isActive),
          ),
          onGoToFasting: () => onSelectPillar(SelectedPillar.ayuno),
        ),
    };
  }
}
