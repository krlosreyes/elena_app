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

import 'package:elena_app/src/features/dashboard/domain/hydration_log.dart';

abstract class HydrationRepository {
  /// Stream con la lista de registros de hidratación del día actual.
  /// La ventana es `[medianoche local, ahora]`. Cada emisión es la lista
  /// completa para que el caller pueda computar suma, filtrar por tipo,
  /// o reconstruir el historial visible.
  Stream<List<HydrationLog>> watchToday(String userId);

  /// Añade un registro nuevo. No sobrescribe — cada llamada crea una
  /// entrada distinta en el storage (Firestore auto-id).
  Future<void> add(String userId, HydrationLog log);
}
