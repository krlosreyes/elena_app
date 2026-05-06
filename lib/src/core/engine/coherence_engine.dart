// ─────────────────────────────────────────────────────────────────────────────
// SPEC-71: CoherenceEngine — Cálculo único de coherencia metabólica
// ─────────────────────────────────────────────────────────────────────────────
//
// Antes de SPEC-71 había doble penalización: MetabolicStateBuilder calculaba
// `metabolicCoherence` aplicando -0.20 por sueño insuficiente, -0.15 por
// deshidratación, etc. Después OrchestratorEngine restaba un -0.05 adicional
// por cada SyncViolation detectada (ej. "deshidratación en autofagia"), pero
// esas violaciones siempre coincidían con dimensiones que el builder ya
// había penalizado. Una deshidratación en autofagia se descontaba tres veces.
//
// Ahora CoherenceEngine es la fuente única. MetabolicStateBuilder delega aquí
// el valor de `metabolicCoherence`. OrchestratorEngine ya no recalcula con
// violaciones — solo usa state.metabolicCoherence directo. Las violaciones
// del orchestrator quedan como strings informativos para mostrar al usuario.
//
// Para R1, las penalizaciones replican exactamente las del antiguo
// `_calculateCoherence` para no introducir cambios numéricos. SPEC-70 (R2)
// re-calibrará pesos con base bibliográfica.
//
// SPEC-00: Dart puro — sin Flutter, sin Riverpod, sin DateTime.now().

/// Motor de coherencia metabólica. Función pura, fuente única.
class CoherenceEngine {
  CoherenceEngine._();

  /// Calcula la coherencia metabólica (0.0–1.0) a partir de los inputs
  /// directos de los pilares. No recibe el `MetabolicState` completo para
  /// que pueda invocarse desde el builder antes de que el state esté armado.
  ///
  /// Reglas (SPEC-71 R1, replicadas del antiguo _calculateCoherence):
  /// - Score base 1.0.
  /// - −0.20 si sueño < 6.5h (privación de descanso).
  /// - −0.15 si hidratación < 50% del goal (deshidratación significativa).
  /// - −0.15 si alineación circadiana < 0.7 (ingesta fuera de ventana).
  /// - −0.10 si ejercicio intenso (>0.8) con sueño pobre (<6h).
  /// - −0.10 si ayuno >16h con hidratación baja (<0.6).
  /// - Resultado clamp 0.0–1.0.
  static double calculate({
    required double sleepHours,
    required double hydrationLevel,
    required double circadianAlignment,
    required double exerciseLoad,
    required double fastingHours,
  }) {
    var score = 1.0;

    // Sueño insuficiente
    if (sleepHours < 6.5) score -= 0.20;

    // Deshidratación significativa
    if (hydrationLevel < 0.5) score -= 0.15;

    // Desalineación circadiana
    if (circadianAlignment < 0.7) score -= 0.15;

    // Ejercicio intenso con sueño pobre
    if (exerciseLoad > 0.8 && sleepHours < 6.0) score -= 0.10;

    // Ayuno prolongado con hidratación baja
    if (fastingHours > 16 && hydrationLevel < 0.6) score -= 0.10;

    return score.clamp(0.0, 1.0);
  }
}
