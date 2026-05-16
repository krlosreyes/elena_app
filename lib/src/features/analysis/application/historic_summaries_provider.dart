// SPEC-111: provider de histórico de DailySummaryDoc en un rango de
// fechas. SPEC-112/113 lo consumen para tendencia, heatmap, etc.
//
// PERF (post-SPEC-113): autoDispose. Al cambiar de período o salir de
// Análisis, los streams se cierran y liberan recursos. El cold-start
// al volver lo absorbe el caché offline de Firestore.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_repository_impl.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Argumento del provider — rango de fechas en formato `YYYY-MM-DD`
/// inclusive en ambos extremos.
class HistoricSummariesRange {
  final String fromIncl;
  final String toIncl;
  const HistoricSummariesRange({
    required this.fromIncl,
    required this.toIncl,
  });

  @override
  bool operator ==(Object other) =>
      other is HistoricSummariesRange &&
      other.fromIncl == fromIncl &&
      other.toIncl == toIncl;

  @override
  int get hashCode => Object.hash(fromIncl, toIncl);
}

/// Stream de los docs del rango. Emite `[]` si el usuario no está
/// autenticado o aún no hay docs en el rango.
final historicSummariesProvider = StreamProvider.family
    .autoDispose<List<DailySummaryDoc>, HistoricSummariesRange>((ref, range) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  final repo = ref.watch(dailySummaryRepositoryProvider);
  return repo.watchRange(
    userId: uid,
    fromIncl: range.fromIncl,
    toIncl: range.toIncl,
  );
});
