import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/adaptive/application/adaptive_engine.dart';
import 'package:elena_app/src/features/dashboard/application/ui_interaction_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

/// SPEC-72.2: el descarte ("Ahora no") consume `uiInteractionProvider`.
/// Persiste solo en la sesión actual; SPEC-58 invoca `resetDismissals()` cada
/// día para que la sugerencia reaparezca si la condición sigue activa.
class AdaptiveSuggestionCard extends ConsumerWidget {
  const AdaptiveSuggestionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(adaptiveProvider);
    final dismissed =
        ref.watch(uiInteractionProvider).isAdaptiveSuggestionDismissed;

    if (suggestion == null || dismissed) return const SizedBox.shrink();

    final isLevelUp = suggestion.type == SuggestionType.levelUp;
    final primaryColor =
        isLevelUp ? const Color(0xFF818CF8) : const Color(0xFFFBBF24);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLevelUp ? Icons.auto_graph_rounded : Icons.healing_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                suggestion.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestion.description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => ref
                      .read(uiInteractionProvider.notifier)
                      .dismissAdaptiveSuggestion(),
                  child: Text(
                    'Ahora no',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () =>
                      _showConfirmationDialog(context, ref, suggestion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLevelUp ? 'Subir de Nivel' : 'Simplificar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, WidgetRef ref, AdaptiveSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          suggestion.title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.description,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Deseas aplicar estos cambios a tu protocolo actual?',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(currentUserStreamProvider).valueOrNull;
              if (user != null) {
                // SPEC-50.5: UserProfileRepository (no UserRepository).
                final repo = ref.read(userProfileRepositoryProvider);

                await repo.saveProtocolAdjustment(user.id, {
                  'type': suggestion.type.name,
                  'title': suggestion.title,
                  'newProtocol': suggestion.newProtocol,
                  'newExerciseGoal': suggestion.newExerciseGoal,
                  'reason': suggestion.reason,
                  'applied': true,
                });

                await repo.applyProtocolAdjustment(
                  userId: user.id,
                  newFastingProtocol: suggestion.newProtocol,
                  newExerciseGoal: suggestion.newExerciseGoal,
                );

                AppLogger.info('[AdaptiveEngine] Protocolo actualizado');
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmar Cambio',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
