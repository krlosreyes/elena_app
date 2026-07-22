// 17-jul: filtro puro "sueño nocturno y de calidad".
//
// Carlos, tras el fix del anillo de sueño (ver SleepRepositoryImpl):
// "solo tenemos en cuenta el sueño nocturno y de calidad". Motivo
// concreto: `_resolveLatest` agrupaba registros por noche de atribución
// (punto medio de [fellAsleep, wokeUp]) y, sin manual, el automático con
// `wokeUp` más tardío ganaba — una siesta vespertina (ej. 2pm-3pm)
// comparte noche de atribución con el sueño de esa misma madrugada y
// SIEMPRE despierta más tarde en el reloj, así que le ganaba al sueño
// real. El mismo problema diluía el promedio semanal en
// `sleepHabitSeriesProvider` y `SleepWeeklyComputer` (TemporalAggregation
// .avg / promedio simple sobre TODOS los logs, sin distinguir siesta de
// sueño principal).
//
// Este clasificador es la única fuente de verdad de "qué cuenta como
// sueño principal" y se aplica en los 3 puntos donde se resuelve o
// agrega sueño para mostrar al usuario: el anillo del Dashboard (y por
// cascada, Score del día e IMR — ambos leen `sleep.lastLog`), el gráfico
// de Hábitos/Análisis, y el SleepQualityCard semanal.
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';

class SleepQualityClassifier {
  SleepQualityClassifier._();

  /// Hora local (0-23) desde la cual un inicio de sueño cuenta como
  /// nocturno. Antes de esta hora, si además es después de
  /// [nightEndHour], es horario diurno → siesta.
  static const int nightStartHour = 18; // 6pm

  /// Hora local (0-23) hasta la cual un inicio de sueño sigue contando
  /// como nocturno (cubre quienes se acuestan pasada la medianoche).
  static const int nightEndHour = 6; // 6am

  /// Duración mínima para no ser descartado como siesta o fragmento
  /// corto (p.ej. un stage de HealthKit no consolidado). 3h es
  /// deliberadamente bajo: no es un juicio clínico sobre "cuánto debe
  /// dormir alguien", solo el piso para distinguir la sesión principal
  /// de la noche de una siesta o de ruido de sincronización.
  static const Duration minQualityDuration = Duration(hours: 3);

  /// True si [log] inició durante la ventana nocturna
  /// ([nightStartHour]-24h o 0h-[nightEndHour], hora local).
  static bool isNocturnal(SleepLog log) {
    final hour = log.fellAsleep.toLocal().hour;
    return hour >= nightStartHour || hour < nightEndHour;
  }

  /// True si [log] dura al menos [minQualityDuration].
  static bool isQuality(SleepLog log) {
    return log.duration >= minQualityDuration;
  }

  /// True si [log] cuenta como sueño nocturno principal: nocturno Y de
  /// duración suficiente. Todo lo que no cumpla esto (siestas diurnas,
  /// cabeceos vespertinos cortos, fragmentos) queda fuera de anillo,
  /// score, IMR y agregados semanales.
  static bool isNocturnalQualitySleep(SleepLog log) {
    return isNocturnal(log) && isQuality(log);
  }
}
