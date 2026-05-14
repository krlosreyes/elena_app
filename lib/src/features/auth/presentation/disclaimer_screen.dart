// SPEC-76: pantalla read-only del disclaimer médico.
//
// Accesible desde Profile → tile "Condiciones médicas". Muestra las
// 5 contraindicaciones de IMR_BIBLIOGRAPHY.md §11, la fecha y versión
// en que el usuario aceptó, y un banner cuando la versión es vieja
// que ofrece re-aceptar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/domain/health_disclaimer.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class DisclaimerScreen extends ConsumerWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text(
          'CONDICIONES MÉDICAS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          final accepted = user?.healthDisclaimerAccepted ?? false;
          final acceptedAt = user?.healthDisclaimerAcceptedAt;
          final acceptedVersion = user?.healthDisclaimerVersion ?? 0;
          final reprompt = needsDisclaimerReprompt(
            accepted: accepted,
            acceptedVersion: acceptedVersion,
          );

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (reprompt) _UpdatedBanner(),
              if (reprompt) const SizedBox(height: 16),
              _AcceptanceStatusCard(
                accepted: accepted,
                acceptedAt: acceptedAt,
                acceptedVersion: acceptedVersion,
              ),
              const SizedBox(height: 24),
              Text(
                'POBLACIONES DE RIESGO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El IMR está diseñado para adultos sanos. Hay condiciones donde NO debes seguir sus recomendaciones sin supervisión médica.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              ...kHealthDisclaimerConditions.map(
                (c) => _DisclaimerConditionTile(condition: c),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Text(
                  kHealthDisclaimerClosingNote,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UpdatedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusWarn.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.statusWarn.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.update_rounded,
            color: AppColors.statusWarn,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Condiciones actualizadas',
                  style: TextStyle(
                    color: AppColors.statusWarn,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Volveremos a pedirte aceptación cuando abras la próxima sección.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.statusWarn,
            ),
            onPressed: () => context.go('/onboarding'),
          ),
        ],
      ),
    );
  }
}

class _AcceptanceStatusCard extends StatelessWidget {
  final bool accepted;
  final DateTime? acceptedAt;
  final int acceptedVersion;

  const _AcceptanceStatusCard({
    required this.accepted,
    required this.acceptedAt,
    required this.acceptedVersion,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = acceptedAt != null
        ? DateFormat('d MMM yyyy', 'es').format(acceptedAt!)
        : '—';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accepted
              ? AppColors.statusGood.withValues(alpha: 0.3)
              : AppColors.borderDefault,
        ),
      ),
      child: Row(
        children: [
          Icon(
            accepted
                ? Icons.check_circle_rounded
                : Icons.cancel_outlined,
            color: accepted ? AppColors.statusGood : AppColors.textMuted,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accepted ? 'Aceptado' : 'Pendiente de aceptación',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accepted
                        ? AppColors.statusGood
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  accepted
                      ? '$dateText · versión $acceptedVersion'
                      : 'Aún no has confirmado las condiciones.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerConditionTile extends StatelessWidget {
  final HealthDisclaimerCondition condition;

  const _DisclaimerConditionTile({required this.condition});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            condition.icon,
            color: AppColors.statusWarn,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  condition.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  condition.body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
