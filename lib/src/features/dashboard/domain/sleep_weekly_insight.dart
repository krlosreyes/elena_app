// SPEC-159: snapshot semanal del sueño + insight adaptativo.
//
// Pure Dart — sin Flutter ni Riverpod. Lo consume `SleepQualityCard`.

import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';

/// Tier del insight según el patrón semanal. Define el copy y el
/// color del bloque inferior del widget.
enum SleepInsightTier {
  empty,
  deprivation,   // duración < 6h promedio
  latencyHigh,   // latencia >30min en ≥3 noches
  fragmented,    // awakenings ≥3 en ≥2 noches
  lowQuality,    // calidad <3 con ≥3 ratings
  sustained,     // duración ≥7h && calidad ≥4
  neutral,       // intermedio
}

class SleepWeeklyInsight {
  /// Logs ordenados por wokeUp descendente (más reciente primero).
  final List<SleepLog> logs;

  /// Duración promedio en horas decimales. 0 si no hay logs.
  final double durationAvgHours;

  /// Calidad subjetiva promedio sobre los logs que la registraron.
  /// Null si NADIE registró calidad esta semana.
  final double? qualityAvg;

  /// Cuántos logs registraron calidad subjetiva.
  final int qualityRatingCount;

  /// Latencia promedio sobre los logs con latencia. Null si nadie.
  final double? latencyAvgMinutes;

  /// Cantidad de noches con latencia >30min.
  final int nightsWithHighLatency;

  /// Cantidad de noches con awakenings ≥3.
  final int nightsWithFragmentation;

  /// Tier del insight (algoritmo del computer).
  final SleepInsightTier tier;

  const SleepWeeklyInsight({
    required this.logs,
    required this.durationAvgHours,
    required this.qualityAvg,
    required this.qualityRatingCount,
    required this.latencyAvgMinutes,
    required this.nightsWithHighLatency,
    required this.nightsWithFragmentation,
    required this.tier,
  });

  factory SleepWeeklyInsight.empty() => const SleepWeeklyInsight(
        logs: [],
        durationAvgHours: 0,
        qualityAvg: null,
        qualityRatingCount: 0,
        latencyAvgMinutes: null,
        nightsWithHighLatency: 0,
        nightsWithFragmentation: 0,
        tier: SleepInsightTier.empty,
      );

  bool get isEmpty => logs.isEmpty;
}

/// Mensaje del coach por tier — headline + acción + cita.
class SleepCoachingMessage {
  final String headline;
  final String action;
  final String citation;

  const SleepCoachingMessage({
    required this.headline,
    required this.action,
    required this.citation,
  });

  /// Devuelve el mensaje correspondiente al tier o null para empty.
  /// La bibliografía es coherente con `CycleClosureCard` (SPEC-149)
  /// y `WeeklyCoachingCard` (SPEC-153) — Walker 2017 + AASM.
  static SleepCoachingMessage? forTier(SleepInsightTier tier) {
    switch (tier) {
      case SleepInsightTier.empty:
        return null;
      case SleepInsightTier.deprivation:
        return const SleepCoachingMessage(
          headline:
              'Tu duración promedio compromete tu reparación metabólica.',
          action:
              'Apuntá a 7h como mínimo no negociable. Adelantá tu hora de dormirte 30 min esta semana.',
          citation: 'Walker 2017 + AASM',
        );
      case SleepInsightTier.latencyHigh:
        return const SleepCoachingMessage(
          headline:
              'Tu latencia >30min sugiere cortisol elevado al acostarte.',
          action:
              'Cerrá pantallas 1h antes y bajá la luz progresivamente desde el atardecer.',
          citation: 'Walker 2017',
        );
      case SleepInsightTier.fragmented:
        return const SleepCoachingMessage(
          headline: 'Fragmentación nocturna recurrente esta semana.',
          action:
              'Reducí líquidos y luz 2h antes de dormir. Cerrá la última comida ≥3h antes.',
          citation: 'AASM + Lopez-Minguez 2018',
        );
      case SleepInsightTier.lowQuality:
        return const SleepCoachingMessage(
          headline: 'Tu calidad subjetiva está bajo el target.',
          action:
              'Probá temperatura ≤19°C y oscuridad total. Mantené el horario constante en fines de semana.',
          citation: 'Walker 2017',
        );
      case SleepInsightTier.sustained:
        return const SleepCoachingMessage(
          headline: 'Tu sueño está sólido esta semana.',
          action:
              'Mantené ritmo y horarios consistentes — la regularidad multiplica el beneficio metabólico.',
          citation: 'AASM',
        );
      case SleepInsightTier.neutral:
        return const SleepCoachingMessage(
          headline: 'Estás en rango pero hay margen.',
          action:
              'Probá una rutina pre-sueño de 30 min: estiramiento, libro, luz cálida.',
          citation: 'Walker 2017',
        );
    }
  }
}
