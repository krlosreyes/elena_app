// SPEC-199 Fase A (RF-199-04) — tarjeta de coaching INTERACTIVA.
//
// Reemplaza el texto pasivo por una pregunta con botones de un toque que
// ejecutan una acción real (registrar agua). El prompt lo decide el motor
// predictivo (RF-05) según contexto; si no hay prompt, la tarjeta no se dibuja.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/pending_action_queue.dart';
import 'package:elena_app/src/core/theme/app_icons.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/coaching/application/interactive_prompt_provider.dart';
import 'package:elena_app/src/features/coaching/domain/actionable_prompt.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';

class InteractiveCoachingCard extends ConsumerWidget {
  const InteractiveCoachingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(interactiveHydrationPromptProvider);
    if (prompt == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    const accent = AppColors.pillarHidratacion;

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
                Icon(AppIcons.hidratacion, color: accent, size: 22),
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
                            onPressed: () =>
                                _onOption(context, ref, prompt, option),
                            child: Text(option.label),
                          )
                        : TextButton(
                            onPressed: () =>
                                _onOption(context, ref, prompt, option),
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
    ActionablePrompt prompt,
    PromptOption option,
  ) {
    switch (option.action) {
      case PromptActionType.logWater:
        ref.read(hydrationProvider.notifier).addWater(kHydrationGlassLiters);
        // Ocultar el prompt de esta hora (ya quedó cumplido).
        ref.read(dismissedHydrationPromptProvider.notifier).state = prompt.id;
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
      case PromptActionType.snooze:
        ref.read(dismissedHydrationPromptProvider.notifier).state = prompt.id;
        AnalyticsService.logEvent(
          'coaching_prompt_answered',
          params: const {
            'type': 'hydration',
            'option': 'snooze',
            'surface': 'card',
          },
        );
        break;

      // SPEC-224: los prompts de ayuno/ejercicio/nutrición llegan por
      // notificación en Fase A; si la tarjeta los recibiera, los descartamos.
      case PromptActionType.closeFasting:
      case PromptActionType.logExercise:
      case PromptActionType.logMeal:
      // SPEC-232: check-in se maneja en su propia CheckInCard.
      case PromptActionType.checkInFeeling:
        ref.read(dismissedHydrationPromptProvider.notifier).state = prompt.id;
        AnalyticsService.logEvent(
          'coaching_prompt_answered',
          params: {
            'type': option.action.name,
            'option': 'card_tap',
            'surface': 'card',
          },
        );
        break;
    }
  }
}
