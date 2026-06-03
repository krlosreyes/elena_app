// SPEC-159: motor puro del SleepQualityCard.
//
// Dado los SleepLog de la semana, computa promedios y elige el tier
// del insight según prioridad de §2.4.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_weekly_insight.dart';

class SleepWeeklyComputer {
  SleepWeeklyComputer._();

  /// Umbral de duración considerada saludable. < kHealthyDurationMin →
  /// tier deprivation (mayor prioridad).
  static const double kHealthyDurationMin = 6.0;

  /// Duración target para "sólido". ≥ kSustainedDuration && calidad ≥
  /// kSustainedQuality → tier sustained.
  static const double kSustainedDuration = 7.0;
  static const double kSustainedQuality = 4.0;

  /// Calidad subjetiva considerada baja para el tier lowQuality.
  static const double kLowQualityThreshold = 3.0;

  /// Latencia en minutos que dispara el flag de noche "alta latencia".
  static const int kHighLatencyMinutes = 30;

  /// Noches con alta latencia necesarias para tier latencyHigh.
  static const int kHighLatencyNightsTrigger = 3;

  /// Awakenings ≥ este valor cuenta como noche fragmentada.
  static const int kFragmentationAwakeningsTrigger = 3;

  /// Noches fragmentadas necesarias para tier fragmented.
  static const int kFragmentedNightsTrigger = 2;

  /// Ratings mínimos para que la calidad promedio sea representativa.
  /// Por debajo de esto, ignoramos tier lowQuality.
  static const int kMinQualityRatingsForTier = 3;

  /// Construye el insight desde los logs entregados por el repository.
  /// Los logs vienen ordenados descendentes — los preservamos así para
  /// que el widget renderice del más reciente al más antiguo.
  static SleepWeeklyInsight compute(List<SleepLog> logs) {
    if (logs.isEmpty) {
      return SleepWeeklyInsight.empty();
    }

    // Duración promedio.
    double sumHours = 0;
    for (final l in logs) {
      sumHours += l.wokeUp.difference(l.fellAsleep).inMinutes / 60.0;
    }
    final durationAvg = sumHours / logs.length;

    // Calidad promedio (solo sobre logs con calidad).
    double sumQuality = 0;
    int qualityCount = 0;
    for (final l in logs) {
      if (l.subjectiveQuality != null) {
        sumQuality += l.subjectiveQuality!;
        qualityCount++;
      }
    }
    final qualityAvg = qualityCount == 0 ? null : sumQuality / qualityCount;

    // Latencia.
    double sumLatency = 0;
    int latencyCount = 0;
    int nightsHighLatency = 0;
    for (final l in logs) {
      if (l.sleepLatencyMinutes != null) {
        sumLatency += l.sleepLatencyMinutes!;
        latencyCount++;
        if (l.sleepLatencyMinutes! > kHighLatencyMinutes) {
          nightsHighLatency++;
        }
      }
    }
    final latencyAvg = latencyCount == 0 ? null : sumLatency / latencyCount;

    // Fragmentación.
    int nightsFragmented = 0;
    for (final l in logs) {
      if (l.nightAwakenings != null &&
          l.nightAwakenings! >= kFragmentationAwakeningsTrigger) {
        nightsFragmented++;
      }
    }

    final tier = _pickTier(
      durationAvg: durationAvg,
      qualityAvg: qualityAvg,
      qualityCount: qualityCount,
      nightsHighLatency: nightsHighLatency,
      nightsFragmented: nightsFragmented,
    );

    return SleepWeeklyInsight(
      logs: logs,
      durationAvgHours: durationAvg,
      qualityAvg: qualityAvg,
      qualityRatingCount: qualityCount,
      latencyAvgMinutes: latencyAvg,
      nightsWithHighLatency: nightsHighLatency,
      nightsWithFragmentation: nightsFragmented,
      tier: tier,
    );
  }

  /// Algoritmo de SPEC-159 §2.4: 5 ramas en orden de prioridad +
  /// sustained + neutral default.
  static SleepInsightTier _pickTier({
    required double durationAvg,
    required double? qualityAvg,
    required int qualityCount,
    required int nightsHighLatency,
    required int nightsFragmented,
  }) {
    // 1. Privación crónica (mayor prioridad — riesgo metabólico).
    if (durationAvg < kHealthyDurationMin) {
      return SleepInsightTier.deprivation;
    }

    // 2. Latencia elevada.
    if (nightsHighLatency >= kHighLatencyNightsTrigger) {
      return SleepInsightTier.latencyHigh;
    }

    // 3. Fragmentación.
    if (nightsFragmented >= kFragmentedNightsTrigger) {
      return SleepInsightTier.fragmented;
    }

    // 4. Calidad baja (solo si hay ≥3 ratings — evita decir "baja
    //    calidad" cuando el usuario apenas registró 1 valoración).
    if (qualityAvg != null &&
        qualityCount >= kMinQualityRatingsForTier &&
        qualityAvg < kLowQualityThreshold) {
      return SleepInsightTier.lowQuality;
    }

    // 5. Sostenido — duración alta + calidad alta.
    if (durationAvg >= kSustainedDuration &&
        qualityAvg != null &&
        qualityAvg >= kSustainedQuality) {
      return SleepInsightTier.sustained;
    }

    // 6. Default neutral.
    return SleepInsightTier.neutral;
  }
}
