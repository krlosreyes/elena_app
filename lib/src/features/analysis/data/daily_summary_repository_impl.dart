// SPEC-111: implementación concreta del DailySummaryRepository.
// Orquesta DataSource + Mapper. Ambos son inyectables para testing.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/data/mappers/daily_summary_mapper.dart';
import 'package:elena_app/src/features/analysis/data/sources/daily_summary_data_source.dart';
import 'package:elena_app/src/features/analysis/data/sources/firestore_daily_summary_v1_source.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary_repository.dart';

class DailySummaryRepositoryImpl implements DailySummaryRepository {
  final DailySummaryDataSource _source;
  final DailySummaryMapper _mapper;

  DailySummaryRepositoryImpl({
    required DailySummaryDataSource source,
    DailySummaryMapper mapper = const DailySummaryMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Future<void> save(String userId, DailySummaryDoc doc) async {
    // El docId es YYYYMMDD (sin guiones); el campo `date` interno
    // mantiene los guiones para legibilidad humana y queries.
    final dateNoSeparator = doc.date.replaceAll('-', '');
    final data = _mapper.toMap(doc);
    await _source.persist(
      userId: userId,
      docId: dateNoSeparator,
      data: data,
    );
  }

  @override
  Future<DailySummaryDoc?> getByDocId(String userId, String docId) async {
    final raw = await _source.readDoc(userId: userId, docId: docId);
    if (raw == null) return null;
    try {
      return _mapper.fromMap(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<DailySummaryDoc>> watchRange({
    required String userId,
    required String fromIncl,
    required String toIncl,
  }) {
    return _source
        .watchRange(
      userId: userId,
      fromIncl: fromIncl,
      toIncl: toIncl,
    )
        .map((maps) {
      return maps
          .map((m) {
            try {
              return _mapper.fromMap(m);
            } catch (_) {
              return null;
            }
          })
          .whereType<DailySummaryDoc>()
          .toList();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────

final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>((ref) {
  return DailySummaryRepositoryImpl(
    source: FirestoreDailySummaryV1Source(),
  );
});
