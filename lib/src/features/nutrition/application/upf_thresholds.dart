// SPEC-138 §16.5: umbrales operacionales para el indicador UPF.
//
// Cada umbral lleva justificación científica trazable a la
// bibliografía en `docs/NUTRITION_BIBLIOGRAPHY.md §16.5`. Vivem en un
// solo archivo para revisión clínica unitaria — si el comité médico
// decide ajustarlos, hay UN punto de cambio.

class UpfThresholds {
  const UpfThresholds._();

  /// Umbral de alerta semanal (%): activa insight de coaching cuando
  /// el % UPF de los últimos 7 días supera este valor.
  ///
  /// Justificación (NUTRITION_BIBLIOGRAPHY.md §16.5):
  /// Hall 2019 documentó +508 kcal/día con dieta ~60% UPF. 40% es un
  /// punto razonable ANTES de aproximarse al rango de exceso calórico
  /// documentado — buffer protector, no umbral arbitrario.
  static const int weeklyAlertPercent = 40;

  /// Umbral de visualización permanente en Hoy (%): por debajo de este
  /// valor, no mostramos panel persistente para no saturar UI.
  ///
  /// Justificación: por debajo de 25% el patrón es ocasional
  /// (cheat-day-like) y no amerita atención visual continua.
  static const int hoyVisibilityPercent = 25;

  /// Mínimo de logs con datos NOVA en los últimos 7 días para activar
  /// el insight semanal. Con menos datos, el % resultaría ruidoso y
  /// poco accionable. Coherente con criterio de ola 3 ("aprender
  /// primero, opinar después").
  static const int weeklyMinLogsWithNova = 5;
}
