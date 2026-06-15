// SPEC-50.2: contrato de persistencia para registros de ejercicio.
//
// Sigue el patrón de SPEC-50 / SPEC-50.1.
//
// Stream expone `List<ExerciseLog>` (no la suma) para que el notifier
// pueda derivar lo que necesite — total de minutos, breakdown por
// tipo, agregaciones por intensidad, etc.

import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';

abstract class ExerciseRepository {
  /// Stream de los registros del día actual (medianoche local → ahora).
  ///
  /// SPEC-189 (2026-06-05): DEPRECADO. La "medianoche local" es reloj
  /// y viola §1 de METABOLIC_DAY_CONSTITUTION.md (cero reloj). Usar
  /// `watchSince(userId, cycle.startedAt)` del ciclo metabólico abierto.
  @Deprecated(
    'SPEC-189: usar watchSince(userId, cycle.startedAt). '
    'Ver METABOLIC_DAY_CONSTITUTION.md §1.',
  )
  Stream<List<ExerciseLog>> watchToday(String userId);

  /// SPEC-149.2: stream filtrado por ventana [since, since + 28h].
  /// 28h coincide con kAbsoluteCycleLimit del MetabolicCycleResolver,
  /// el límite duro de duración de un ciclo metabólico.
  ///
  /// Usado por el notifier para anclar el conteo al Día Metabólico
  /// (cycle.startedAt) en lugar de a la medianoche calendárica.
  ///
  /// SPEC-149.2.bugfix (2026-06-02): para análisis histórico (rangos
  /// 30d+) el cap de 28h rompe los gráficos. Si se pasa `until` se
  /// sobrescribe el cap. Default preserva semántica original.
  Stream<List<ExerciseLog>> watchSince(
    String userId,
    DateTime since, {
    DateTime? until,
  });

  /// Persiste o sobrescribe un registro usando `log.id` como clave.
  Future<void> save(String userId, ExerciseLog log);

  /// Borra el log más reciente en la ventana [since, ∞).
  /// No-op si no hay logs en la ventana.
  Future<void> removeLastSession(String userId, DateTime since);

  /// Borra un log por ID determinístico. No-op si no existe.
  /// Usado por HealthImportService para limpiar `hk_steps_{day}` cuando
  /// se detecta un workout real del mismo día (Bug 3 — double-counting).
  Future<void> deleteById(String userId, String logId);
}
