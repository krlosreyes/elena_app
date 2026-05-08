// SPEC-50.1: implementación concreta del HydrationRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/data/mappers/hydration_log_mapper.dart';
import 'package:elena_app/src/features/dashboard/data/sources/firestore_hydration_v1_source.dart';
import 'package:elena_app/src/features/dashboard/data/sources/hydration_data_source.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_log.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_repository.dart';

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
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _source
        .streamSince(userId: userId, startOfDay: startOfDay)
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
