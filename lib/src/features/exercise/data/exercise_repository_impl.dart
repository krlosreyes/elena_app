// SPEC-50.2: implementación concreta del ExerciseRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/exercise/data/mappers/exercise_log_mapper.dart';
import 'package:elena_app/src/features/exercise/data/sources/exercise_data_source.dart';
import 'package:elena_app/src/features/exercise/data/sources/firestore_exercise_v1_source.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_repository.dart';

/// SPEC-149.2: ventana máxima cubierta por watchSince. Coincide con
/// kAbsoluteCycleLimit del MetabolicCycleResolver (el cierre forzado de
/// ciclo a las 28h sin signals). Exposto para tests.
const Duration kCycleWindowDuration = Duration(hours: 28);

class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseDataSource _source;
  final ExerciseLogMapper _mapper;

  ExerciseRepositoryImpl({
    required ExerciseDataSource source,
    ExerciseLogMapper mapper = const ExerciseLogMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Stream<List<ExerciseLog>> watchToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DayBoundaryResolver.startOfDay(now);
    final endOfDay = DayBoundaryResolver.endOfDay(now);
    return _streamMapped(userId, startOfDay, endOfDay);
  }

  @override
  Stream<List<ExerciseLog>> watchSince(
    String userId,
    DateTime since, {
    DateTime? until,
  }) {
    // SPEC-178 (2026-06-04): sin cap fijo de 28h. El cap original
    // (`since.add(kCycleWindowDuration)`) hacía que ciclos largos
    // (protocolo "Ninguno" > 28h, o ayuno OMAD prolongado) cortaran
    // logs FUTUROS dentro del propio ciclo abierto. Ahora el upper
    // bound es siempre `now` cuando until no se especifica.
    final end = until ?? DateTime.now();
    return _streamMapped(userId, since, end);
  }

  Stream<List<ExerciseLog>> _streamMapped(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _source
        .streamSince(userId: userId, startOfDay: start, endOfDay: end)
        .map((maps) {
      return maps
          .map((m) {
            try {
              return _mapper.fromMap(m);
            } catch (_) {
              // Doc corrupto: lo saltamos para no caer toda la app.
              return null;
            }
          })
          .whereType<ExerciseLog>()
          .toList();
    });
  }

  @override
  Future<void> save(String userId, ExerciseLog log) async {
    final data = _mapper.toMap(log);
    await _source.persist(userId: userId, docId: log.id, data: data);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepositoryImpl(
    source: FirestoreExerciseV1Source(),
  );
});
