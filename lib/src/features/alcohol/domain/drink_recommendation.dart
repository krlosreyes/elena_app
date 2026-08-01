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
  /// Servidas físicas REALES recomendadas (copas/vasos/tragos), NO UEA crudas.
  final int drinks;

  /// Presupuesto total en UEA (10 g) que representan esas servidas. Es lo que
  /// consume el tracking/impacto al IMR (que va en UEA), no la UI.
  final double budgetUnits;

  /// Minutos recomendados entre servida y servida.
  final int spacingMinutes;

  /// Vasos de agua sugeridos (regla 1:1 con las servidas).
  final int waterGlasses;

  /// Hora objetivo de dormir (derivada de la agenda de mañana).
  final DateTime bedtime;

  /// Hora del último trago (bedtime − margen de sueño).
  final DateTime lastCall;

  /// Recipiente sugerido para el tipo elegido (copa/vaso/trago).
  final String vessel;

  /// Etiqueta legible de la servida, ej. "copa de 150 ml".
  final String servingLabel;

  /// La ventana/tope apenas dan para una servida: plan mínimo.
  final bool tight;

  const DrinkRecommendation({
    required this.drinks,
    required this.budgetUnits,
    required this.spacingMinutes,
    required this.waterGlasses,
    required this.bedtime,
    required this.lastCall,
    required this.vessel,
    required this.servingLabel,
    required this.tight,
  });

  /// Tope duro de UEA para no salir de la zona social, pase lo que pase (freno
  /// para cuerpos grandes en noches largas). El tope REAL suele ser menor y
  /// sale de Widmark por peso+sexo (ver compute).
  static const int socialZoneCapUnits = 6;

  /// Alcoholemia tope de la zona social: 0,06 % = 0,6 g/L. Por encima ya no es
  /// "una copa social", es emborracharse.
  static const double socialZoneMaxBacGL = 0.6;

  /// Crédito máximo (UEA) que suma una noche larga por eliminación. Lo topamos
  /// para NO premiar el "llevamos 6 horas afuera, dale otra ronda".
  static const double maxWindowCreditUnits = 2.0;

  /// Piso realista entre servidas (min). Evita "un shot cada 20 min".
  static const int minSpacingPerServing = 45;

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
    final windowMin = lastCall.difference(startTime).inMinutes;

    // 2) Física de UNA servida real (una copa, un vaso, un trago).
    final gramsPerServing = AlcoholMath.gramsOfAlcohol(
      volumeMl: type.servingMl,
      abv: type.abv,
    );
    final ueaPerServing =
        gramsPerServing <= 0 ? 1.0 : AlcoholMath.standardUnits(gramsPerServing);

    // 3) Espaciado por UEA (igualar la eliminación; sube con carbonatación y
    //    levemente para mujeres) → luego escalado a la servida real.
    final rate = AlcoholMath.eliminationRatePerHour(weightKg); // g/h
    var spacingPerUnit = (10 / rate * 60).round(); // min por UEA
    if (type.carbonated) spacingPerUnit = (spacingPerUnit * 1.2).round();
    if (sex == WidmarkSex.female)
      spacingPerUnit = (spacingPerUnit * 1.1).round();
    if (spacingPerUnit < 45) spacingPerUnit = 45;
    if (spacingPerUnit > 90) spacingPerUnit = 90;
    var spacingPerServing = (spacingPerUnit * ueaPerServing).round();
    if (spacingPerServing < minSpacingPerServing) {
      spacingPerServing = minSpacingPerServing;
    }

    // 4) Tope de UEA PERSONALIZADO por Widmark (peso + sexo). Base = gramos que
    //    te dejan en el techo de la zona social al pico; + un crédito acotado
    //    por lo que eliminas durante la ventana; nunca más que el tope duro.
    final r = AlcoholMath.widmarkR(sex);
    final peakUnits =
        socialZoneMaxBacGL * r * weightKg / AlcoholMath.gramsPerStandardUnit;
    final windowHours = windowMin <= 0 ? 0.0 : windowMin / 60.0;
    final elimUnits =
        rate * windowHours / AlcoholMath.gramsPerStandardUnit; // UEA que aclara
    final creditUnits =
        elimUnits < maxWindowCreditUnits ? elimUnits : maxWindowCreditUnits;
    var budgetCapUnits = peakUnits + creditUnits;
    if (budgetCapUnits > socialZoneCapUnits) {
      budgetCapUnits = socialZoneCapUnits.toDouble();
    }

    // 5) Nº de SERVIDAS: lo que cabe en la ventana Y bajo el tope de UEA.
    final byWindow =
        windowMin <= 0 ? 0 : (windowMin / spacingPerServing).floor();
    final byBudget = (budgetCapUnits / ueaPerServing).floor();
    var servings = byWindow < byBudget ? byWindow : byBudget;
    if (servings < 0) servings = 0;

    return DrinkRecommendation(
      drinks: servings,
      budgetUnits: servings * ueaPerServing,
      spacingMinutes: spacingPerServing,
      waterGlasses: servings,
      bedtime: bedtime,
      lastCall: lastCall,
      vessel: type.vessel.label,
      servingLabel: '${type.vessel.label} de ${type.servingMl.round()} ml',
      tight: servings <= 1,
    );
  }
}
