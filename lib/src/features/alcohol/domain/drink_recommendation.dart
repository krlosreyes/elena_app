// SPEC-261.4: motor de recomendación personalizado (cálculo puro).
//
// A partir del tipo de trago, el peso/sexo, la hora de inicio y la agenda de
// mañana, arma un plan concreto: cuántos tragos, cada cuánto, cuánta agua, en
// qué recipiente, y las horas de último trago y de dormir. El objetivo es
// mantener al usuario en la "zona social" (BAC ~0,04–0,06) y proteger su
// sueño, minimizando borrachera y daño metabólico.
//
// Todo es determinístico y sin I/O ni reloj propio: 100% testeable.

import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_math.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_type.dart';

class DrinkRecommendation {
  /// Tragos (UEA) recomendados para la ventana disponible.
  final int drinks;

  /// Minutos recomendados entre trago y trago.
  final int spacingMinutes;

  /// Vasos de agua sugeridos (regla 1:1).
  final int waterGlasses;

  /// Hora objetivo de dormir (derivada de la agenda de mañana).
  final DateTime bedtime;

  /// Hora del último trago (bedtime − margen de sueño).
  final DateTime lastCall;

  /// Recipiente sugerido para el tipo elegido.
  final String vessel;

  /// La ventana es muy corta (típico de noche laboral): plan mínimo.
  final bool tight;

  const DrinkRecommendation({
    required this.drinks,
    required this.spacingMinutes,
    required this.waterGlasses,
    required this.bedtime,
    required this.lastCall,
    required this.vessel,
    required this.tight,
  });

  /// Tope de UEA para no salir de la zona social, aunque el tiempo diera más.
  static const int socialZoneCapUnits = 6;

  /// Tope de madrugada para noche de descanso. NO usamos el reloj circadiano
  /// habitual (haría la ventana negativa cuando la salida es temprano): quien
  /// sale a las 20:00 no se acuesta a su hora fisiológica. Damos una ventana
  /// realista hasta ~02:00 (o su hábito si trasnocha más aún).
  static const int restNightCapHour = 2;
  static const int restNightCapMinute = 0;

  /// Próxima vez que caen `hour:minute` DESPUÉS de `base` (hoy o mañana).
  static DateTime _nextOccurrenceAfter(DateTime base, int hour, int minute) {
    var t = DateTime(base.year, base.month, base.day, hour, minute);
    if (!t.isAfter(base)) t = t.add(const Duration(days: 1));
    return t;
  }

  static DrinkRecommendation compute({
    required DrinkTypeOption type,
    required double weightKg,
    required WidmarkSex sex,
    required DateTime startTime,
    required bool worksTomorrow,
    DateTime? wakeTime,
    required DateTime habitualBedtime,
    double sleepNeedHours = 7.5,
    Duration lastCallMargin = const Duration(hours: 3),
  }) {
    // 1) Hora de dormir según la agenda de mañana.
    DateTime bedtime;
    if (worksTomorrow && wakeTime != null) {
      // Noche laboral: protegemos el sueño → dormir = levantarse − necesidad.
      bedtime =
          wakeTime.subtract(Duration(minutes: (sleepNeedHours * 60).round()));
      if (!bedtime.isAfter(startTime)) {
        bedtime = bedtime.add(const Duration(days: 1));
      }
    } else {
      // Noche de descanso: tope realista de madrugada, o su hábito si
      // trasnocha aún más. NUNCA la hora circadiana temprano (colapsaría la
      // ventana y daría "0 tragos / último trago antes de salir").
      final habitualOnNight = _nextOccurrenceAfter(
        startTime,
        habitualBedtime.hour,
        habitualBedtime.minute,
      );
      final capOnNight = _nextOccurrenceAfter(
        startTime,
        restNightCapHour,
        restNightCapMinute,
      );
      bedtime =
          habitualOnNight.isAfter(capOnNight) ? habitualOnNight : capOnNight;
    }
    final lastCall = bedtime.subtract(lastCallMargin);

    // 2) Espaciado: parte de igualar la eliminación, y sube con carbonatación
    //    y (levemente) para mujeres, que alcanzan mayor BAC por gramo.
    final rate = AlcoholMath.eliminationRatePerHour(weightKg); // g/h
    var spacing = (10 / rate * 60).round(); // min por UEA
    if (type.carbonated) spacing = (spacing * 1.2).round();
    if (sex == WidmarkSex.female) spacing = (spacing * 1.1).round();
    if (spacing < 45) spacing = 45;
    if (spacing > 90) spacing = 90;

    // 3) Nº de tragos: lo que cabe en la ventana, con tope de zona social.
    final windowMin = lastCall.difference(startTime).inMinutes;
    var drinks = windowMin <= 0 ? 0 : (windowMin / spacing).floor();
    if (drinks < 0) drinks = 0;
    if (drinks > socialZoneCapUnits) drinks = socialZoneCapUnits;

    return DrinkRecommendation(
      drinks: drinks,
      spacingMinutes: spacing,
      waterGlasses: drinks,
      bedtime: bedtime,
      lastCall: lastCall,
      vessel: type.vessel.label,
      tight: drinks <= 1,
    );
  }
}
