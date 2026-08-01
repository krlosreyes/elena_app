// SPEC-261.9: historial de "salidas" reconstruido desde los tragos.
//
// No hay un documento por sesión (el meta se sobrescribe en
// `alcohol_session/current`), pero cada trago persiste en `alcohol_history`.
// Acá agrupamos esos tragos por NOCHE para mostrar una historia y una
// tendencia. Todo es puro y determinístico (sin reloj propio ni I/O): recibe
// la lista de eventos y devuelve las salidas ordenadas.

import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';

/// Una "salida": los tragos de una misma noche, agregados.
class Outing {
  /// Medianoche de la FECHA de la noche a la que pertenecen los tragos.
  final DateTime night;
  final int drinkCount;
  final double totalGrams;

  const Outing({
    required this.night,
    required this.drinkCount,
    required this.totalGrams,
  });

  double get totalStandardUnits => totalGrams / 10.0;

  /// Etiqueta cualitativa NO moralizante, por UEA de la noche.
  String get intensityLabel {
    final u = totalStandardUnits;
    if (u <= 2) return 'Ligera';
    if (u <= 4) return 'Moderada';
    if (u <= 6) return 'Alta';
    return 'Muy alta';
  }
}

abstract final class OutingHistory {
  /// Hora que separa una noche de la siguiente: un trago antes de las 6 a. m.
  /// pertenece a la noche del día anterior (la fiesta que cruzó la medianoche).
  static const int nightBoundaryHour = 6;

  /// Fecha (medianoche) de la NOCHE a la que pertenece un instante.
  static DateTime nightOf(DateTime t, {int boundaryHour = nightBoundaryHour}) {
    final d = t.hour < boundaryHour ? t.subtract(const Duration(days: 1)) : t;
    return DateTime(d.year, d.month, d.day);
  }

  /// Agrupa tragos en salidas, de la más reciente a la más antigua.
  static List<Outing> fromDrinks(
    List<DrinkEvent> drinks, {
    int boundaryHour = nightBoundaryHour,
  }) {
    if (drinks.isEmpty) return const [];
    final byNight = <DateTime, List<DrinkEvent>>{};
    for (final d in drinks) {
      final n = nightOf(d.timestamp, boundaryHour: boundaryHour);
      (byNight[n] ??= <DrinkEvent>[]).add(d);
    }
    final outings = byNight.entries.map((e) {
      final grams = e.value.fold<double>(0, (s, d) => s + d.grams);
      return Outing(
        night: e.key,
        drinkCount: e.value.length,
        totalGrams: grams,
      );
    }).toList()
      ..sort((a, b) => b.night.compareTo(a.night));
    return outings;
  }

  /// Resumen de los últimos [days] días: nº de salidas y UEA totales.
  static ({int outings, double totalUnits}) summary(
    List<Outing> all, {
    required DateTime now,
    int days = 30,
  }) {
    final cutoff = now.subtract(Duration(days: days));
    final recent = all.where((o) => o.night.isAfter(cutoff));
    var count = 0;
    var units = 0.0;
    for (final o in recent) {
      count++;
      units += o.totalStandardUnits;
    }
    return (outings: count, totalUnits: units);
  }
}
