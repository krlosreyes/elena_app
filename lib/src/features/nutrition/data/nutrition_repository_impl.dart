// SPEC-63: implementación del NutritionRepository.
//
// Orquesta DataSource (acceso físico) + Mapper (traducción). Es la única
// pieza de la capa data que conoce el contrato del dominio. Cualquier
// consumidor de la app obtiene ESTA implementación a través del provider
// `nutritionRepositoryProvider` y depende solo del contrato abstracto.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/nutrition/data/mappers/nutrition_log_mapper.dart';
import 'package:elena_app/src/features/nutrition/data/sources/firestore_nutrition_v1_source.dart';
import 'package:elena_app/src/features/nutrition/data/sources/nutrition_data_source.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_repository.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  NutritionRepositoryImpl({
    required NutritionDataSource source,
    NutritionLogMapper mapper = const NutritionLogMapper(),
  })  : _source = source,
        _mapper = mapper;

  final NutritionDataSource _source;
  final NutritionLogMapper _mapper;

  @override
  Stream<List<NutritionLog>> watchTodayLogs(String userId) {
    // SPEC-138: la ventana del día la decide aquí (fuente única) y se pasa al
    // source, que queda agnóstico — igual que hidratación y ejercicio.
    final now = DateTime.now();
    final startOfDay = DayBoundaryResolver.startOfDay(now);
    final endOfDay = DayBoundaryResolver.endOfDay(now);
    return _streamMapped(userId, startOfDay, endOfDay);
  }

  @override
  Stream<List<NutritionLog>> watchSinceLogs(
    String userId,
    DateTime since, {
    DateTime? until,
  }) {
    // SPEC-178 (2026-06-04): sin cap fijo de 28h. Ver
    // exercise_repository_impl.watchSince para el rationale completo.
    // BUGFIX (2026-06-08): NO fijar el tope en `DateTime.now()` del momento
    // de suscripción — capturaba el "ahora" como tope superior y los logs
    // registrados después (en vivo) caían fuera de la ventana hasta reabrir.
    // Con `end = null` el source usa fin-de-día (o sin tope) y los registros
    // nuevos aparecen en tiempo real.
    final DateTime? end = until;
    return _streamMapped(userId, since, end);
  }

  Stream<List<NutritionLog>> _streamMapped(
    String userId,
    DateTime start,
    DateTime? end,
  ) {
    return _source
        .watchTodayLogs(userId, startOfDay: start, endOfDay: end)
        .map(
          // BUGFIX (2026-06-14): si fromMap lanza (timestamp corrupto,
          // label inválido, etc.), NO propagar el error al stream —
          // eso causa que onError lo silencie y el estado quede en 0
          // permanentemente. En cambio, saltamos el doc inválido y
          // seguimos procesando el resto del snapshot.
          (rows) => rows
              .expand((row) {
                try {
                  return [_mapper.fromMap(row.data, docId: row.docId)];
                } catch (e) {
                  AppLogger.warning(
                    'nutrition_history: doc ${row.docId} inválido, '
                    'ignorado: $e',
                  );
                  return const <NutritionLog>[];
                }
              })
              .toList(growable: false),
        );
  }

  @override
  Future<void> saveMeal(String userId, NutritionLog log) async {
    final data = _mapper.toMap(log); // valida invariantes antes de persistir
    await _source.saveLog(userId, log.id, data);
  }

  @override
  Future<void> removeLastMeal(String userId) async {
    final now = DateTime.now();
    final latest = await _source.latestTodayLog(
      userId,
      startOfDay: DayBoundaryResolver.startOfDay(now),
      endOfDay: DayBoundaryResolver.endOfDay(now),
    );
    if (latest == null) return;
    await _source.deleteLog(userId, latest.docId);
  }

  @override
  Future<void> deleteMealById(String userId, String mealId) async {
    await _source.deleteLog(userId, mealId);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────

/// DataSource activo. SPEC-49 (R3) intercambiará este provider por el
/// `_v2_source` sin tocar el resto del árbol.
final nutritionDataSourceProvider = Provider<NutritionDataSource>((ref) {
  return FirestoreNutritionV1Source(FirebaseFirestore.instance);
});

/// Repositorio que la capa application/presentation consume.
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepositoryImpl(
    source: ref.watch(nutritionDataSourceProvider),
  );
});
