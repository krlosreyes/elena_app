import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_launcher.dart';
import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';

/// Overlay de blur + CTA premium sobre el detalle de un pilar. Incluye
/// su propio botón ← para que el usuario pueda volver al overview sin
/// quedar atrapado detrás del blur.
///
/// SPEC-119: extraído de `_buildPremiumGateOverlay` + `_metricLabel`
/// en `analysis_pillar_detail_screen.dart` (ARCH-03). `widget.metric`
/// pasa a ser el parámetro `metric`; el resto del cuerpo es idéntico.
class AnalysisPremiumGateOverlay extends ConsumerWidget {
  const AnalysisPremiumGateOverlay({super.key, required this.metric});

  final ChartMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _metricLabel(metric);
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.50],
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    AppColors.backgroundDark.withValues(alpha: 0.92),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button propio del overlay (el original queda detrás del blur).
                    InkResponse(
                      onTap: () => context.pop(),
                      radius: 22,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 22,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: AppColors.metabolicGreen
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: AppColors.metabolicGreen,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Gráficas detalladas, tendencias y análisis de evolución disponibles con Elena Premium.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 14,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () => openPaywall(
                                    context, ref,
                                    feature: GatedFeature.analyticsHistory,
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.metabolicGreen,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Desbloquear Premium',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _metricLabel(ChartMetric metric) {
    switch (metric) {
      case ChartMetric.imr:
        return 'Detalle IMR';
      case ChartMetric.bodyFatPct:
        return 'Detalle Composición Corporal';
      case ChartMetric.fastingHours:
        return 'Detalle Ayuno';
      case ChartMetric.nutritionAPct:
        return 'Detalle Nutrición';
      case ChartMetric.hydrationLiters:
        return 'Detalle Hidratación';
      case ChartMetric.exerciseMin:
        return 'Detalle Ejercicio';
      case ChartMetric.sleepHours:
        return 'Detalle Sueño';
      case ChartMetric.weight:
        return 'Detalle Peso';
    }
  }
}
