// SPEC-50.2: implementación concreta del ExerciseRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/exercise/data/mappers/exercise_log_mapper.dart';
import 'package:elena_app/src/features/exercise/data/sources/exercise_data_source.dart';
import 'package:elena_app/src/features/exercise/data/sources/firestore_exercise_v1_source.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_repository.dart';

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
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _source
        .streamSince(userId: userId, startOfDay: startOfDay)
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
