// SPEC-50.1: implementación concreta del HydrationRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/dashboard/data/mappers/hydration_log_mapper.dart';
import 'package:elena_app/src/features/dashboard/data/sources/firestore_hydration_v1_source.dart';
import 'package:elena_app/src/features/dashboard/data/sources/hydration_data_source.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_log.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_repository.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart'
    show kCycleWindowDuration;

class HydrationRepositoryImpl implements HydrationRepository {
  final HydrationDataSource _source;
  final HydrationLogMapper _mapper;

  HydrationRepositoryImpl({
    required HydrationDataSource source,
    HydrationLogMapper mapper = const HydrationLogMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Stream<List<HydrationLog>> watchToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DayBoundaryResolver.startOfDay(now);
    final endOfDay = DayBoundaryResolver.endOfDay(now);
    return _streamMapped(userId, startOfDay, endOfDay);
  }

  @override
  Stream<List<HydrationLog>> watchSince(String userId, DateTime since) {
    return _streamMapped(userId, since, since.add(kCycleWindowDuration));
  }

  Stream<List<HydrationLog>> _streamMapped(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _source
        .streamSince(userId: userId, startOfDay: start, endOfDay: end)
        .map((maps) => maps.map(_mapper.fromMap).toList());
  }

  @override
  Future<void> add(String userId, HydrationLog log) async {
    final data = _mapper.toMap(log);
    await _source.append(userId: userId, data: data);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────

/// SPEC-50.1: provider único del HydrationRepository.
final hydrationRepositoryProvider = Provider<HydrationRepository>((ref) {
  return HydrationRepositoryImpl(
    source: FirestoreHydrationV1Source(),
  );
});
