import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/engine/longitudinal_imr_provider.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_launcher.dart';
import 'package:elena_app/src/features/billing/presentation/premium_lock.dart';

/// GAP-2: card "IMR Longitudinal" visible en el Dashboard principal.
///
/// Free → atenuado con candado + "Desbloquear" que abre el paywall.
/// Premium → muestra IMR actual + zona + acceso directo a Análisis.
///
/// SPEC-119: extraído de `_buildImrLongitudinalCard` en
/// `dashboard_screen.dart` (ARCH-03). Lógica intacta.
///
/// PROD-IMR fix (21-jul, auditoría técnica): esta card leía
/// `displayedImrProvider` — el IMR DIARIO/comportamental que también
/// alimenta el ring "IMR / tu base" del Dashboard — en vez de
/// `longitudinalImrProvider` (`ScoreEngine.calculateLongitudinalIMR`,
/// core/engine/longitudinal_imr_provider.dart), que es el cálculo
/// longitudinal real y ya se persiste semanalmente vía
/// `WeeklyImrSnapshotService`. El resultado era que "IMR LONGITUDINAL"
/// mostraba el mismo número que el ring diario, y el motor longitudinal
/// real quedaba huérfano de presentación — la causa raíz confirmada de
/// la inconsistencia numérica (48/35.9/44) reportada en la auditoría UX
/// del 21-jul. Se corrige el binding; `longitudinalScore` es nullable
/// (null solo en el estado `empty()`, sin `lastMealTime`), de ahí el
/// fallback a `totalScore` (0 en ese mismo caso).
///
/// PERF-01: antes se hacía `ref.watch(featureGateProvider)` y
/// `ref.watch(longitudinalImrProvider)` observando los objetos completos.
/// Ambos widgets usan un único campo cada uno dentro de este método
/// (`analyticsHistoryAllowed`, `score`, `zone`), así que se cambiaron a
/// `.select()` para no reconstruir esta card ante cambios de otros
/// campos de FeatureGate/IMRv2Result que no afectan este render.
class ImrLongitudinalCard extends ConsumerWidget {
  const ImrLongitudinalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsHistoryAllowed = ref
        .watch(featureGateProvider.select((g) => g.analyticsHistoryAllowed));
    final imrScore = ref.watch(
        longitudinalImrProvider.select((s) => s.longitudinalScore ?? s.totalScore));
    final imrZone = ref.watch(longitudinalImrProvider.select((s) => s.zone));

    final content = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.metabolicGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'IMR LONGITUDINAL',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (analyticsHistoryAllowed)
                GestureDetector(
                  onTap: () => context.go('/analysis'),
                  child: Text(
                    'Ver detalle →',
                    style: TextStyle(
                      color: AppColors.metabolicGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ImrStatColumn(
                label: 'IMR Actual',
                value: imrScore.toString(),
                accent: AppColors.metabolicGreen,
              ),
              _ImrStatColumn(
                label: 'Zona',
                value: imrZone.isNotEmpty ? imrZone : '—',
                accent: Colors.white,
              ),
              _ImrStatColumn(
                label: 'Tendencia',
                value: '7 días',
                accent: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Tu IMR longitudinal refleja tu estado metabólico real. '
            'Sube con ciclos bien ejecutados, semana a semana.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.50),
              height: 1.45,
            ),
          ),
        ],
      ),
    );

    return PremiumLock(
      isLocked: !analyticsHistoryAllowed,
      label: 'IMR Longitudinal',
      onUpgrade: () => openPaywall(
        context,
        ref,
        feature: GatedFeature.analyticsHistory,
      ),
      child: content,
    );
  }
}

/// Columna de stat para el card IMR Longitudinal.
class _ImrStatColumn extends StatelessWidget {
  const _ImrStatColumn({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
