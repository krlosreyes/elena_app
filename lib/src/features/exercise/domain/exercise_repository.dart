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
  Stream<List<ExerciseLog>> watchToday(String userId);

  /// SPEC-149.2: stream filtrado por ventana [since, since + 28h].
  /// 28h coincide con kAbsoluteCycleLimit del MetabolicCycleResolver,
  /// el límite duro de duración de un ciclo metabólico.
  ///
  /// Usado por el notifier para anclar el conteo al Día Metabólico
  /// (cycle.startedAt) en lugar de a la medianoche calendárica.
  Stream<List<ExerciseLog>> watchSince(String userId, DateTime since);

  /// Persiste o sobrescribe un registro usando `log.id` como clave.
  Future<void> save(String userId, ExerciseLog log);
}
