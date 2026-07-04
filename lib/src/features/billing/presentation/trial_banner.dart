// SPEC-240 — Banner de periodo de prueba.
//
// Visible durante los primeros 14 días para usuarios no-premium.
// Se oculta automáticamente cuando:
//   - El usuario suscribe (isPremium = true)
//   - El trial venció (daysRemaining = 0)
//
// Diseño: discreto pero visible. Urgencia creciente:
//   - días 1–7  : tono informativo (verde)
//   - días 8–11 : tono de aviso (amarillo)
//   - días 12–14: tono de urgencia (naranja)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_launcher.dart';

class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInTrial = ref.watch(isInTrialProvider);
    if (!isInTrial) return const SizedBox.shrink();

    final daysRemaining = ref.watch(trialDaysRemainingProvider);
    if (daysRemaining <= 0) return const SizedBox.shrink();

    final accent = _accentColor(daysRemaining);
    final label = _label(daysRemaining);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => openPaywall(context, ref, feature: GatedFeature.coaching),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.star_outline_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Suscribirme',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 16, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentColor(int daysRemaining) {
    if (daysRemaining <= 3) return const Color(0xFFFB923C); // naranja urgente
    if (daysRemaining <= 7) return const Color(0xFFFFD700); // amarillo aviso
    return AppColors.metabolicGreen;                         // verde informativo
  }

  static String _label(int daysRemaining) {
    if (daysRemaining == 1) {
      return 'Hoy es el último día de tu prueba gratuita. '
          'Suscríbete para conservar el acceso completo.';
    }
    if (daysRemaining <= 3) {
      return 'Tu prueba gratuita vence en $daysRemaining días. '
          'No pierdas el acceso completo.';
    }
    return 'Prueba gratuita — te quedan $daysRemaining días de acceso completo.';
  }
}
