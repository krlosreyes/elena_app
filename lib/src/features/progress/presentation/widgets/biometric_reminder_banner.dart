// Carlos (2026-07-13): "al llegar al dia 7 debemos recordarle al usuario
// que debe actualizar el registro de su peso y medidas". Banner en el
// Dashboard (mismo patrón que EngagementBanner/AdaptiveSuggestionCard):
// dismiss persistido por día calendárico en `uiInteractionProvider`,
// reaparece mañana si la condición sigue activa.
//
// Condición: `biometricReminderDueProvider` (progress_notifier.dart) —
// >= 7 días desde el último check-in registrado (onboarding cuenta como
// el primero). Recurrente: cada nuevo check-in reinicia el contador.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/application/ui_interaction_notifier.dart';
import 'package:elena_app/src/features/progress/application/progress_notifier.dart';
import 'package:elena_app/src/features/progress/presentation/biometric_checkin_sheet.dart';

class BiometricReminderBanner extends ConsumerWidget {
  const BiometricReminderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(biometricReminderDueProvider);
    final dismissed =
        ref.watch(uiInteractionProvider).isBiometricReminderDismissed;

    if (!due || dismissed) return const SizedBox.shrink();

    const accentColor = Color(0xFF34D399);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.monitor_weight_outlined,
              color: accentColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTUALIZA TU PESO Y MEDIDAS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pasó una semana desde tu último registro. Actualízalo '
                  'para que tu IMR y tu progreso reflejen tu estado real.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => ref
                          .read(uiInteractionProvider.notifier)
                          .dismissBiometricReminder(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Ahora no',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => showBiometricCheckInSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: AppColors.backgroundDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Medir ahora',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
