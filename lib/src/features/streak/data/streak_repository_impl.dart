// SPEC-50.3: implementación concreta del StreakRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/streak/data/mappers/streak_entry_mapper.dart';
import 'package:elena_app/src/features/streak/data/sources/firestore_streak_v1_source.dart';
import 'package:elena_app/src/features/streak/data/sources/streak_data_source.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/features/streak/domain/streak_repository.dart';

class StreakRepositoryImpl implements StreakRepository {
  final StreakDataSource _source;
  final StreakEntryMapper _mapper;

  StreakRepositoryImpl({
    required StreakDataSource source,
    StreakEntryMapper mapper = const StreakEntryMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Stream<List<StreakEntry>> watchHistory(String userId) {
    // SPEC-141: computeActiveDaysLast90 necesita 90 días de historial.
    // Con 30 días, adherenceTrend (input del IMR) quedaba subvalorado.
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final cutoffKey = _formatDateKey(cutoff);
    return _source
        .streamSince(userId: userId, cutoffDateKey: cutoffKey)
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
          .whereType<StreakEntry>()
          .toList();
    });
  }

  @override
  Future<void> save(String userId, StreakEntry entry) async {
    final data = _mapper.toMap(entry);
    await _source.persistMerged(
      userId: userId,
      dateKey: entry.date,
      data: data,
    );
  }

  /// SPEC-138: delega en la fuente única del día (ISO `YYYY-MM-DD`).
  static String _formatDateKey(DateTime d) => DayBoundaryResolver.dayKeyIso(d);
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepositoryImpl(
    source: FirestoreStreakV1Source(),
  );
});
