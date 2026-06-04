// SPEC-168.5.4 (2026-06-03): provider del pie chart de Nutrición.
//
// Cuenta comidas A-dominantes y E-dominantes en el rango activo del
// Análisis. Se alimenta del mismo stream que el provider de la serie
// (`nutritionRepository.watchSinceLogs`) — no agrega queries nuevos.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/domain/nutrition_pie_data.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';

final _kEpoch = DateTime(2000);

DateTime _todayLocal() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

final nutritionPieDataProvider =
    StreamProvider.autoDispose<NutritionPieData>((ref) async* {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    yield NutritionPieData.empty;
    return;
  }
  final rangeStart = ref.watch(analysisRangeStartProvider) ?? _kEpoch;
  final until = _todayLocal().add(const Duration(days: 1));
  await for (final logs in ref
      .watch(nutritionRepositoryProvider)
      .watchSinceLogs(account.uid, rangeStart, until: until)) {
    var aCount = 0;
    var eCount = 0;
    for (final log in logs) {
      if (log.ratio.isADominant) {
        aCount++;
      } else {
        eCount++;
      }
    }
    yield NutritionPieData(aDominantCount: aCount, eDominantCount: eCount);
  }
});
