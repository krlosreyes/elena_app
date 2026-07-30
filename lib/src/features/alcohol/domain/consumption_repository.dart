// SPEC-261: contrato de persistencia de consumos de alcohol.
//
// Sigue el patrón de HydrationRepository (SPEC-50.1): múltiples registros
// por ciclo, id auto-generado por Firestore, stream anclado a la ventana
// del Día Metabólico (`watchSince`). La agregación (totales, UEA) es
// responsabilidad de la capa de aplicación, no del repositorio.

import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';

abstract class ConsumptionRepository {
  /// Stream de consumos en la ventana `[since, until?]`, anclada al ciclo
  /// metabólico abierto (Constitución §1: cero reloj). Si `until` es null
  /// el stream queda abierto y refleja registros nuevos en vivo.
  Stream<List<DrinkEvent>> watchSince(
    String userId,
    DateTime since, {
    DateTime? until,
  });

  /// Añade un consumo nuevo. Cada llamada crea una entrada (auto-id).
  Future<void> add(String userId, DrinkEvent event);

  /// Borra el consumo más reciente desde [since]. No-op si no hay ninguno.
  Future<void> removeLast(String userId, DateTime since);
}
