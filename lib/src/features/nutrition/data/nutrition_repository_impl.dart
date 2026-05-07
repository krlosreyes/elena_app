// SPEC-63: implementación del NutritionRepository.
//
// Orquesta DataSource (acceso físico) + Mapper (traducción). Es la única
// pieza de la capa data que conoce el contrato del dominio. Cualquier
// consumidor de la app obtiene ESTA implementación a través del provider
// `nutritionRepositoryProvider` y depende solo del contrato abstracto.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return _source.watchTodayLogs(userId).map(
          (rows) => rows
              .map((row) => _mapper.fromMap(row.data, docId: row.docId))
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
    final latest = await _source.latestTodayLog(userId);
    if (latest == null) return;
    await _source.deleteLog(userId, latest.docId);
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
