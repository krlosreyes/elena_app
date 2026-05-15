// SPEC-111: contrato de persistencia para los resúmenes diarios.
// La capa de aplicación (servicios y providers) consume esta
// abstracción, nunca Firestore directamente.

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';

abstract class DailySummaryRepository {
  /// Upsert del resumen del día indicado por `doc.date`. El docId se
  /// deriva del `date` interno (YYYYMMDD).
  Future<void> save(String userId, DailySummaryDoc doc);

  /// Lee el resumen de un día puntual. `dateKey` formato `YYYYMMDD`.
  Future<DailySummaryDoc?> getByDocId(String userId, String docId);

  /// Stream de resúmenes en el rango `[fromIncl, toIncl]`. Formato
  /// `YYYY-MM-DD` (con guiones, para comparación lexicográfica
  /// natural). Ordenados ascendente por fecha.
  Stream<List<DailySummaryDoc>> watchRange({
    required String userId,
    required String fromIncl,
    required String toIncl,
  });
}
