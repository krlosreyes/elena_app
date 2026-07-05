// SPEC-240 — Banner de conversión trial → premium.
//
// Visible durante los primeros 14 días para usuarios no-premium.
// Se oculta automáticamente cuando:
//   - El usuario suscribe (isPremium = true)
//   - El trial venció (daysRemaining = 0)
//
// Estrategia: loss aversion escalonada. Nunca dice "gratis" después del día 7;
// siempre habla de lo que el usuario perderá, no de lo que ganará.
//
// Fases:
//   Días 8–14 (verde, slim)   : "lo tienes todo, N días más"
//   Días 4–7  (amarillo, slim): "N días para mantener tu racha"
//   Días 1–3  (naranja, alto) : menciona coaching + historial IMR + HK explícitos
//   Día 1     (naranja, alto) : llamado final, urgencia máxima

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
    final isUrgent = daysRemaining <= 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => openPaywall(context, ref, feature: GatedFeature.coaching),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: isUrgent ? 13 : 10,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isUrgent ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: isUrgent ? 0.50 : 0.35),
              width: isUrgent ? 1.5 : 1,
            ),
          ),
          child: isUrgent
              ? _buildUrgentLayout(accent, daysRemaining)
              : _buildSlimLayout(accent, daysRemaining),
        ),
      ),
    );
  }

  // ─── Días 8–14 y 4–7: banner compacto ──────────────────────────────────────

  Widget _buildSlimLayout(Color accent, int daysRemaining) {
    return Row(
      children: [
        Icon(
          daysRemaining <= 7
              ? Icons.timer_outlined
              : Icons.check_circle_outline_rounded,
          size: 16,
          color: accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _mainLabel(daysRemaining),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _ctaLabel(daysRemaining),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right_rounded, size: 16, color: accent),
      ],
    );
  }

  // ─── Días 1–3: banner expandido con subtítulo ───────────────────────────────

  Widget _buildUrgentLayout(Color accent, int daysRemaining) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.warning_amber_rounded, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _mainLabel(daysRemaining),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Perderás el coaching diario, tu historial de IMR '
                'y la sincronización con Apple Health.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              _UrgentCtaChip(accent: accent, label: _ctaLabel(daysRemaining)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Copy ───────────────────────────────────────────────────────────────────

  static Color _accentColor(int daysRemaining) {
    if (daysRemaining <= 3) return const Color(0xFFFB923C); // naranja urgente
    if (daysRemaining <= 7) return const Color(0xFFEAB308); // ámbar aviso
    return AppColors.metabolicGreen;                         // verde informativo
  }

  static String _mainLabel(int daysRemaining) {
    if (daysRemaining == 1) {
      return 'Hoy termina tu acceso completo a Elena';
    }
    if (daysRemaining <= 3) {
      return 'Solo te quedan $daysRemaining días — después perderás el acceso';
    }
    if (daysRemaining <= 7) {
      return '$daysRemaining días para asegurar tu racha y coaching';
    }
    return 'Tienes acceso completo a Elena — te quedan $daysRemaining días';
  }

  static String _ctaLabel(int daysRemaining) {
    if (daysRemaining <= 3) return 'Suscribirme ahora';
    if (daysRemaining <= 7) return 'Asegurar mi plan';
    return 'Elegir mi plan';
  }
}

// ─── Chip CTA para el layout urgente ────────────────────────────────────────

class _UrgentCtaChip extends StatelessWidget {
  const _UrgentCtaChip({required this.accent, required this.label});
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(width: 3),
          Icon(Icons.arrow_forward_rounded, size: 13, color: accent),
        ],
      ),
    );
  }
}
