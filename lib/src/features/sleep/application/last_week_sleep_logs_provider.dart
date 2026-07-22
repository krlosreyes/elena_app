// SPEC-159: provider que alimenta el SleepQualityCard.
//
// Consume watchRecent(uid, limit: 7) del SleepRepository (extendido
// en SPEC-159) y delega el cálculo al SleepWeeklyComputer.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/sleep/application/sleep_weekly_computer.dart';
import 'package:elena_app/src/features/sleep/data/sleep_repository_impl.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_quality_classifier.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_weekly_insight.dart';

/// Cantidad de noches de la ventana semanal del card. Coherente con
/// el resto de cards de Análisis (7 días).
const int kSleepCardLimit = 7;

final lastWeekSleepLogsProvider =
    StreamProvider.autoDispose<SleepWeeklyInsight>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) {
    return Stream.value(SleepWeeklyInsight.empty());
  }
  // 17-jul (Carlos: "solo tenemos en cuenta el sueño nocturno y de
  // calidad"): mismo criterio que el anillo del Dashboard y el gráfico
  // de Hábitos — sin esto, una siesta se cuela en el promedio semanal
  // del card. Ver SleepQualityClassifier.
  return ref
      .watch(sleepRepositoryProvider)
      .watchRecent(account.uid, limit: kSleepCardLimit)
      .map((logs) =>
          logs.where(SleepQualityClassifier.isNocturnalQualitySleep).toList())
      .map(SleepWeeklyComputer.compute);
});
