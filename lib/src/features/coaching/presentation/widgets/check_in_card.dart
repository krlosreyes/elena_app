// SPEC-232: tarjeta de check-in emocional durante el ayuno.
//
// Aparece en el dashboard cuando hay un hito de check-in activo (4, 8, 12, 16h).
// El usuario toca un emoji y recibe coaching empático inmediato. Si reporta
// irritable 2x consecutivas, se sugiere cerrar el ayuno.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/coaching/application/check_in_provider.dart';
import 'package:elena_app/src/features/coaching/data/check_in_repository.dart';
import 'package:elena_app/src/features/coaching/domain/fasting_check_in.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class CheckInCard extends ConsumerStatefulWidget {
  const CheckInCard({super.key});

  @override
  ConsumerState<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends ConsumerState<CheckInCard> {
  CheckInCoachingResponse? _response;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final prompt = ref.watch(interactiveCheckInPromptProvider);
    if (prompt == null && !_answered) return const SizedBox.shrink();

    final theme = Theme.of(context);
    const accent = AppColors.pillarAyuno;

    // Post-respuesta: mostrar coaching empático.
    if (_answered && _response != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Elena dice',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _answered = false;
                      _response = null;
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_response!.message, style: theme.textTheme.bodyMedium),
              if (_response!.followUpAction != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    onPressed: () => _handleFollowUp(context, ref),
                    child: const Text('Cerrar ayuno'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Prompt activo: mostrar los 6 sentimientos como chips.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_rounded, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prompt!.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // Dismiss: "ahora no"
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    ref.read(dismissedCheckInPromptProvider.notifier).state =
                        prompt.id;
                    AnalyticsService.logEvent(
                      'coaching_prompt_answered',
                      params: const {
                        'type': 'check_in',
                        'option': 'dismiss',
                        'surface': 'card',
                      },
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(prompt.message, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FastingFeeling.values
                  .map((f) => _FeelingChip(
                        feeling: f,
                        onTap: () => _onFeeling(f),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _onFeeling(FastingFeeling feeling) {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null || user.id.isEmpty) return;

    final fastingState = ref.read(fastingProvider);
    final history = ref.read(checkInHistoryProvider).valueOrNull ?? [];

    // Guardar el check-in.
    saveCheckIn(
      userId: user.id,
      feeling: feeling,
      repo: ref.read(checkInRepositoryProvider),
      fastingStart: fastingState.startTime,
    );

    // Generar respuesta empática.
    final response = getCoachingResponse(feeling, history);

    // Dismiss el prompt actual y mostrar la respuesta.
    final prompt = ref.read(interactiveCheckInPromptProvider);
    if (prompt != null) {
      ref.read(dismissedCheckInPromptProvider.notifier).state = prompt.id;
    }

    setState(() {
      _answered = true;
      _response = response;
    });

    AnalyticsService.logEvent(
      'coaching_prompt_answered',
      params: {
        'type': 'check_in',
        'option': feeling.name,
        'surface': 'card',
      },
    );
  }

  void _handleFollowUp(BuildContext context, WidgetRef ref) {
    ref.read(fastingProvider.notifier).confirmManualFastingEnd(DateTime.now());
    setState(() {
      _answered = false;
      _response = null;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayuno cerrado. Tu salud es lo primero.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Chip individual para un sentimiento.
class _FeelingChip extends StatelessWidget {
  final FastingFeeling feeling;
  final VoidCallback onTap;

  const _FeelingChip({required this.feeling, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: feeling.isNegative
              ? Colors.orange.withValues(alpha: 0.1)
              : AppColors.pillarAyuno.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: feeling.isNegative
                ? Colors.orange.withValues(alpha: 0.3)
                : AppColors.pillarAyuno.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '${feeling.emoji} ${feeling.label}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
