// SPEC-50.1: contrato de persistencia para registros de hidratación.
//
// Sigue el patrón establecido en SPEC-50 (SleepRepository) y SPEC-63
// (NutritionRepository).
//
// Diferencias notables vs Sleep:
//   - Múltiples registros por día (Sleep es uno por ciclo).
//   - Firestore auto-genera el id por `.add()` — el dominio no asigna id.
//   - Stream expone la lista de logs del día, NO la suma. La agregación
//     es responsabilidad de la capa de aplicación (notifier).

import 'package:elena_app/src/features/hydration/domain/hydration_log.dart';

abstract class HydrationRepository {
  /// Stream con la lista de registros de hidratación del día actual.
  /// La ventana es `[medianoche local, ahora]`. Cada emisión es la lista
  /// completa para que el caller pueda computar suma, filtrar por tipo,
  /// o reconstruir el historial visible.
  ///
  /// SPEC-189 (2026-06-05): DEPRECADO. La "medianoche local" es reloj
  /// y viola §1 de METABOLIC_DAY_CONSTITUTION.md (cero reloj). Usar
  /// `watchSince(userId, cycle.startedAt)` del ciclo metabólico abierto.
  @Deprecated(
    'SPEC-189: usar watchSince(userId, cycle.startedAt). '
    'Ver METABOLIC_DAY_CONSTITUTION.md §1.',
  )
  Stream<List<HydrationLog>> watchToday(String userId);

  /// SPEC-149.2: stream filtrado por ventana [since, since + 28h].
  /// Anclado al ciclo metabólico para que el conteo no se vea afectado
  /// por la medianoche calendárica.
  ///
  /// SPEC-149.2.bugfix (2026-06-02): si se pasa `until` se sobrescribe
  /// el cap de 28h. Necesario para análisis histórico de rangos largos.
  Stream<List<HydrationLog>> watchSince(
    String userId,
    DateTime since, {
    DateTime? until,
  });

  /// Añade un registro nuevo. No sobrescribe — cada llamada crea una
  /// entrada distinta en el storage (Firestore auto-id).
  Future<void> add(String userId, HydrationLog log);

  /// Borra el log más reciente del ciclo (desde [since] en adelante).
  /// No-op si no hay logs en la ventana.
  Future<void> removeLastLog(String userId, DateTime since);
}
