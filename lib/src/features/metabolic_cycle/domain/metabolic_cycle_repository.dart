// SPEC-149 §RF-149-05: contrato de persistencia para MetabolicCycle.
//
// La interfaz vive en domain (Dart puro) para que el service pueda
// dependar de ella sin conocer Firestore. La implementación concreta
// vive en data/.

import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

abstract class MetabolicCycleRepository {
  /// Persiste un ciclo (apertura o cierre). El cycleId es la PK del doc
  /// en `users/{uid}/metabolic_cycles/{cycleId}`. Idempotente — escribir
  /// dos veces el mismo cycleId con el mismo contenido converge.
  Future<void> save(String userId, MetabolicCycle cycle);

  /// Stream del único ciclo abierto del usuario (closedAt == null).
  /// Emite null si no hay ninguno abierto. Si hay >1 abierto (data
  /// malformada), retorna el de startedAt más reciente.
  Stream<MetabolicCycle?> watchOpenCycle(String userId);

  /// Stream del último ciclo cerrado del usuario. Útil para el card de
  /// cierre del Dashboard. Emite null si no hay ningún cerrado.
  Stream<MetabolicCycle?> watchLastClosed(String userId);

  /// Stream de los últimos [limit] ciclos cerrados ordenados por
  /// closedAt descendente. Para la pantalla Análisis y SPEC-141
  /// (behaviorTrend30 sobre ciclos).
  Stream<List<MetabolicCycle>> watchRecentClosed(
    String userId, {
    int limit = 90,
  });

  /// One-shot fetch del ciclo abierto (sin stream). Útil para el
  /// service al bootstrap antes de suscribirse a streams.
  Future<MetabolicCycle?> fetchOpenCycle(String userId);
}
