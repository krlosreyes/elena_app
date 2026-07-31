// SPEC-261.1: enganche del costo del alcohol al Score del Día.
//
// DECISIÓN de arquitectura (no-regresión): NO tocamos el ScoreEngine
// canónico (IMRv2Result, leído también por el sitio web) ni el
// `displayDailyScoreProvider` (lo consume el evaluador del ciclo). En su
// lugar, este provider de PRESENTACIÓN compone el Score del Día ya
// calculado con el costo neto de la sesión de consumo.
//
// Propiedad clave: sin tragos, el costo neto es 0 y el score queda
// idéntico → cero cambio de comportamiento cuando no hay alcohol, y los
// tests existentes del score siguen en verde.
//
// Honestidad científica: el costo neto ya viene mitigado por las acciones
// de reducción de daño (hidratación, comida, espaciado, ayuno de
// recuperación) pero nunca baja a cero mientras haya consumo.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/alcohol/application/consumption_notifier.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_impact.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';

/// Aplica el costo neto del alcohol (en puntos) sobre un score base 0-100.
/// Redondea y acota a [0, 100]. Puro y testeable sin Riverpod.
int applyAlcoholPenalty(int baseScore, double netCostPoints) {
  final penalized = (baseScore - netCostPoints).round();
  return penalized.clamp(0, 100);
}

/// Score del Día de PRESENTACIÓN, con el costo del alcohol descontado.
/// Es el que el dashboard debe mostrar. Cuando no hay consumo, equivale
/// exactamente a `displayDailyScoreProvider`.
final dailyScoreWithConsumptionProvider = Provider<int>((ref) {
  final base = ref.watch(displayDailyScoreProvider);
  final session = ref.watch(consumptionProvider);
  final netCost = AlcoholImpact.netCostForSession(session);
  return applyAlcoholPenalty(base, netCost);
});

/// Puntos que el alcohol le está restando hoy al Score del Día (>= 0).
/// La UI lo usa para explicar de forma transparente por qué bajó el score.
final dailyAlcoholPenaltyProvider = Provider<int>((ref) {
  final session = ref.watch(consumptionProvider);
  return AlcoholImpact.netCostForSession(session).round();
});
