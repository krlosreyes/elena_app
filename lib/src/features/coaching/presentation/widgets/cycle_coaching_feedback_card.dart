// SPEC-194 RF-194-05 — card del feedback de cierre: refleja si el usuario
// siguió la recomendación del ciclo que cerró. Additivo y se oculta solo.
// Dispara `coaching_feedback_shown` una vez por outcome (post-frame).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/features/coaching/application/coaching_providers.dart';

class CycleCoachingFeedbackCard extends ConsumerStatefulWidget {
  const CycleCoachingFeedbackCard({super.key});

  @override
  ConsumerState<CycleCoachingFeedbackCard> createState() =>
      _CycleCoachingFeedbackCardState();
}

class _CycleCoachingFeedbackCardState
    extends ConsumerState<CycleCoachingFeedbackCard> {
  String? _lastOutcome;

  @override
  Widget build(BuildContext context) {
    // SPEC-197 §revisión: el feedback de cierre es parte del loop de coaching
    // core. Visible para todos los usuarios; re-evaluar gating post-lanzamiento.
    final feedback = ref.watch(coachingClosureFeedbackProvider);
    if (feedback == null) return const SizedBox.shrink();

    final outcomeName = feedback.outcome.name;
    if (_lastOutcome != outcomeName) {
      _lastOutcome = outcomeName;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AnalyticsService.logEvent(
          AnalyticsEvents.coachingFeedbackShown,
          params: {AnalyticsParams.outcome: outcomeName},
        );
      });
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.secondary),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.eco_outlined, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(feedback.message, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
