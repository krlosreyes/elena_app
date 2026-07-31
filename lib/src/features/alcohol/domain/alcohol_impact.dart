// SPEC-261: impacto del alcohol en el Score/IMR (cálculo puro).
//
// Cuantifica de forma TRANSPARENTE y HONESTA el costo metabólico de una
// sesión de consumo y cuánto de ese costo mitiga el protocolo. Es lógica
// pura (sin I/O, sin reloj): se puede testear y mostrar en la UI sin tocar
// el ScoreEngine canónico.
//
// IMPORTANTE — no está cableado al IMR canónico todavía. El ScoreEngine
// (lib/src/core/engine/score_engine.dart) alimenta un contrato que también
// lee el sitio web (IMRv2Result), con invariantes fuertes y suite extensa.
// Enchufar este costo al IMR longitudinal debe ser un paso propio, con su
// SPEC y validación de no-regresión (mapear consumidores primero). Por eso
// aquí el impacto se expone como valor informativo, listo para ese enganche.

import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';

abstract final class AlcoholImpact {
  /// Gramos de alcohol que saturan el impacto al máximo. ~6 UEA (60 g) es
  /// una noche claramente excesiva; por encima el daño ya está en el techo.
  static const double saturationGrams = 60.0;

  /// Penalización máxima en puntos de score (0–100). Parámetro a calibrar.
  static const double maxPenaltyPoints = 25.0;

  /// Impacto crudo normalizado [0, 1] según los gramos totales, sin mitigar.
  static double rawImpact01(double totalGrams) {
    if (totalGrams <= 0) return 0;
    final r = totalGrams / saturationGrams;
    return r < 1.0 ? r : 1.0;
  }

  /// Costo bruto en puntos de score (0–[maxPenaltyPoints]).
  static double rawCostPoints(double totalGrams) =>
      rawImpact01(totalGrams) * maxPenaltyPoints;

  /// Costo neto tras aplicar el factor de mitigación de la sesión.
  ///
  /// Nunca llega a cero mientras haya consumo: por honestidad científica el
  /// alcohol siempre deja huella (la mitigación tiene tope < 1).
  static double netCostPoints(double totalGrams, double mitigationFactor) {
    final m = mitigationFactor.clamp(0.0, ConsumptionSession.maxMitigation);
    return rawCostPoints(totalGrams) * (1 - m);
  }

  /// Puntos de costo evitados gracias a las acciones de reducción de daño.
  static double mitigatedPoints(double totalGrams, double mitigationFactor) =>
      rawCostPoints(totalGrams) - netCostPoints(totalGrams, mitigationFactor);

  /// Atajo desde una sesión completa.
  static double netCostForSession(ConsumptionSession s) =>
      netCostPoints(s.totalGrams, s.mitigationFactor);

  /// Etiqueta cualitativa del impacto neto, para copy no moralizante.
  static String label(double netPoints) {
    if (netPoints <= 0) return 'Sin impacto';
    if (netPoints < 5) return 'Impacto bajo';
    if (netPoints < 12) return 'Impacto moderado';
    return 'Impacto alto';
  }
}
