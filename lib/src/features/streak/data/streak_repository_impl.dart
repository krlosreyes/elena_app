// SPEC-50.3: implementación concreta del StreakRepository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
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

  static String _formatDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  return StreakRepositoryImpl(
    source: FirestoreStreakV1Source(),
  );
});
