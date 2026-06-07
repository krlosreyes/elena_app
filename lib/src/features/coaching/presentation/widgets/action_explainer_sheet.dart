// SPEC-194 inc3 — "Saber más" de la acción de coaching: el por qué + la cita.
// Patrón consistente con los explainer sheets del proyecto (SPEC-140/149/169).

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';

class ActionExplainerSheet extends StatelessWidget {
  const ActionExplainerSheet({super.key, required this.action});

  final CoachingAction action;

  static Future<void> show(BuildContext context, CoachingAction action) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ActionExplainerSheet(action: action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(action.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(action.actionText, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Por qué', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(action.reason, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text(
              action.citation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
