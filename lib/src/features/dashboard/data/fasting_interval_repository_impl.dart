// SPEC-50.4: implementación concreta del FastingIntervalRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/data/mappers/fasting_interval_mapper.dart';
import 'package:elena_app/src/features/dashboard/data/sources/fasting_interval_data_source.dart';
import 'package:elena_app/src/features/dashboard/data/sources/firestore_fasting_interval_v1_source.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_interval_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart'
    show FastingInterval;

class FastingIntervalRepositoryImpl implements FastingIntervalRepository {
  final FastingIntervalDataSource _source;
  final FastingIntervalMapper _mapper;

  FastingIntervalRepositoryImpl({
    required FastingIntervalDataSource source,
    FastingIntervalMapper mapper = const FastingIntervalMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Stream<FastingInterval?> watchLatest(String userId) {
    return _source.streamLatest(userId).map((map) {
      if (map == null) return null;
      try {
        return _mapper.fromMap(map);
      } catch (_) {
        // Doc corrupto: emitimos null para que el siguiente snapshot
        // intente de nuevo en lugar de caer la app.
        return null;
      }
    });
  }

  @override
  Future<void> correctOpenIntervalStartTime({
    required String userId,
    required DateTime newStartTime,
  }) async {
    await _source.updateOpenIntervalStartTime(
      userId: userId,
      newStartTime: newStartTime,
    );
  }

  @override
  Future<void> transitionTo({
    required String userId,
    required bool isFasting,
    DateTime? startTime,
  }) async {
    final effectiveTime = startTime ?? DateTime.now();
    await _source.closeAllOpenAndCreate(
      userId: userId,
      closeAt: effectiveTime,
      buildNewData: (newDocId) {
        final newInterval = FastingInterval(
          id: newDocId,
          userId: userId,
          startTime: effectiveTime,
          isFasting: isFasting,
        );
        return _mapper.toMap(newInterval);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────

final fastingIntervalRepositoryProvider =
    Provider<FastingIntervalRepository>((ref) {
  return FastingIntervalRepositoryImpl(
    source: FirestoreFastingIntervalV1Source(),
  );
});
