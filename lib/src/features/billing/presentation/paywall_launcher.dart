// SPEC-197 — punto único para "abrir el paywall" desde cualquier muro de
// gating. Hoy es un placeholder: registra la telemetría de conversión y
// muestra un aviso. SPEC-198 reemplazará el cuerpo para abrir PaywallScreen,
// sin tocar los callsites (todos llaman `openPaywall`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';

/// Identificadores de feature para la telemetría `feature_gate_blocked`.
class GatedFeature {
  GatedFeature._();
  static const String coaching = 'coaching';
  static const String cycleFeedback = 'cycle_feedback';
  static const String analyticsHistory = 'analytics_history';
  static const String autoSync = 'auto_sync';
}

/// Abre el flujo de upgrade. [feature] alimenta la telemetría (qué muro
/// convirtió). SPEC-198 cambiará el cuerpo por `PaywallScreen.show(context)`.
void openPaywall(
  BuildContext context,
  WidgetRef ref, {
  required String feature,
}) {
  AnalyticsService.logEvent(
    AnalyticsEvents.featureGateBlocked,
    params: {AnalyticsParams.feature: feature},
  );

  // Placeholder hasta SPEC-198 (paywall real).
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Función Premium — el paywall llega en SPEC-198.'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
