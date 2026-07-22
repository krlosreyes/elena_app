// SPEC-199 Fase A → SPEC-233: tarjeta de coaching INTERACTIVA multi-pilar.
//
// Renderiza el prompt del pilar más relevante del momento, decidido por el
// InteractivePromptOrchestrator. El color, icono y acciones se adaptan al
// pilar. Reemplaza la versión hardcodeada de solo-hidratación.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/pending_action_queue.dart';
import 'package:elena_app/src/core/theme/app_icons.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/coaching/application/interactive_prompt_orchestrator.dart';
import 'package:elena_app/src/features/coaching/application/interactive_prompt_provider.dart';
import 'package:elena_app/src/features/coaching/domain/actionable_prompt.dart';
import 'package:elena_app/src/features/coaching/presentation/sleep_routine_screen.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';

class InteractiveCoachingCard extends ConsumerWidget {
  const InteractiveCoachingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pillarPrompt = ref.watch(interactivePromptProvider);
    if (pillarPrompt == null) return const SizedBox.shrink();

    // Check-ins se renderizan en su propia CheckInCard (SPEC-232).
    if (pillarPrompt.pillar == PromptPillar.checkIn) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final accent = _colorForPillar(pillarPrompt.pillar);
    final icon = _iconForPillar(pillarPrompt.pillar);
    final prompt = pillarPrompt.prompt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prompt.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(prompt.message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final option in prompt.options)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: option.isPrimary
                        ? FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                            ),
                            onPressed: () => _onOption(
                                context, ref, pillarPrompt, option),
                            child: Text(option.label),
                          )
                        : TextButton(
                            onPressed: () => _onOption(
                                context, ref, pillarPrompt, option),
                            child: Text(option.label),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onOption(
    BuildContext context,
    WidgetRef ref,
    PillarPrompt pillarPrompt,
    PromptOption option,
  ) {
    final prompt = pillarPrompt.prompt;
    final pillar = pillarPrompt.pillar;

    switch (option.action) {
      // ── Hidratación ──────────────────────────────────────────────────────
      case PromptActionType.logWater:
        ref.read(hydrationProvider.notifier).addWater(kHydrationGlassLiters);
        _dismiss(ref, prompt.id, pillar);
        AnalyticsService.logEvent(
          'coaching_prompt_answered',
          params: const {
            'type': 'hydration',
            'option': 'yes',
            'surface': 'card',
          },
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vaso registrado 💧'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;

      // ── Ayuno ────────────────────────────────────────────────────────────
      case PromptActionType.closeFasting:
        ref
            .read(fastingProvider.notifier)
            .confirmManualFastingEnd(DateTime.now());
        _dismiss(ref, prompt.id, pillar);
        AnalyticsService.logEvent(
          'coaching_prompt_answered',
          params: const {
            'type': 'fasting',
            'option': 'close',
            'surface': 'card',
          },
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ayuno cerrado. ¡Buen trabajo!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;

      // ── Ejercicio ────────────────────────────────────────────────────────
      case PromptActionType.logExercise:
        // Registrar sesión default (30 min caminata) con 1 toque.
        try {
          ref.read(exerciseProvider.notifier).registerExercise(
                minutes: kExercisePromptMinutes,
                activityType: 'Actividad moderada',
                timestamp: DateTime.now(),
              );
        } catch (_) {
          // Validación fallida: descartar sin romper UX.
        }
        _dismiss(ref, prompt.id, pillar);
        AnalyticsService.logEvent(
          'coaching_prompt_answered',
          params: const {
            'type': 'exercise',
            'option': 'log',
            'surface': 'card',
          },
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ejercicio registrado 💪'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;

      // ── Nutrición ────────────────────────────────────────────────────────
      case PromptActionType.logMeal:
        try {
          ref.read(nutritionProvider.notifier).logMeal(
                label: 'Comida',
                mealTime: DateTime.now(),
                forceLog: true,
              );
        } catch (_) {
          // Validación fallida.
        }
        _dismiss(ref, prompt.id, pillar);
        AnalyticsService.logEvent(
          'coaching_prompt_answered',
          params: const {
            'type': 'nutrition',
            'option': 'log',
            'surface': 'card',
          },
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comida registrada 🍽️'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;

      // ── Sueño — rutina nocturna (SPEC-234) ──────────────────────────────
      case PromptActionType.startSleepRoutine:
        _dismiss(ref, prompt.id, pillar);
        AnalyticsService.logEvent(
          'coaching_prompt_answered',
          params: const {
            'type': 'sleep',
            'option': 'start_routine',
            'surface': 'card',
          },
        );
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SleepRoutineScreen(),
            ),
          );
        }
        break;

      // ── Snooze / dismiss ─────────────────────────────────────────────────
      case PromptActionType.snooze:
        _dismiss(ref, prompt.id, pillar);
        AnalyticsService.logEvent(
          'coaching_prompt_answered',
          params: {
            'type': pillar.name,
            'option': 'snooze',
            'surface': 'card',
          },
        );
        break;

      // SPEC-232: check-in se maneja en CheckInCard, no aquí.
      case PromptActionType.checkInFeeling:
        break;
    }
  }

  /// Dismiss: oculta el prompt actual y actualiza el conteo anti-fatiga.
  void _dismiss(WidgetRef ref, String promptId, PromptPillar pillar) {
    ref.read(dismissedHydrationPromptProvider.notifier).state = promptId;
    // Anti-fatiga: incrementar conteo de dismisses.
    final counts =
        Map<String, int>.from(ref.read(dismissCountTodayProvider));
    counts[promptId] = (counts[promptId] ?? 0) + 1;
    ref.read(dismissCountTodayProvider.notifier).state = counts;
  }

  static Color _colorForPillar(PromptPillar pillar) => switch (pillar) {
        PromptPillar.hydration => AppColors.pillarHidratacion,
        PromptPillar.fasting => AppColors.pillarAyuno,
        PromptPillar.exercise => AppColors.pillarEjercicio,
        PromptPillar.nutrition => AppColors.pillarNutricion,
        PromptPillar.sleep => AppColors.pillarSueno,
        PromptPillar.checkIn => AppColors.pillarAyuno,
      };

  static IconData _iconForPillar(PromptPillar pillar) => switch (pillar) {
        PromptPillar.hydration => AppIcons.hidratacion,
        PromptPillar.fasting => AppIcons.ayuno,
        PromptPillar.exercise => Icons.directions_run_rounded,
        PromptPillar.nutrition => Icons.restaurant_rounded,
        PromptPillar.sleep => Icons.bedtime_rounded,
        PromptPillar.checkIn => Icons.timer_rounded,
      };
}
