// Calidad de comida percibida (2026-11-07).
//
// El registro de comidas se simplifica a UNA barra: el usuario desliza de
// "Chatarra" a "Saludable", pasando por "Aceptable", según su percepción
// de lo que comió. Se guarda como `NutritionLog.quality` ∈ [0, 1].
//
// Puntaje del pilar Comida (0–1):
//
//   Cada comida aporta su calidad. Tu protocolo define cuántas comidas
//   caben en tu ventana (MealTargetService: 16:8 → 2, OMAD → 1, …).
//
//   puntaje = (Σ calidad de las primeras N comidas − 0,15 × extras) / N
//
//   - N = comidas del protocolo. Si comes menos de N, los huecos valen 0:
//     el puntaje sube a medida que registras, como el agua. Comer lo que
//     pide el protocolo protege la proteína del día y la masa magra.
//   - Extras = comidas por encima de N. Si el protocolo permite snack, el
//     primer extra no resta si fue al menos "Aceptable". Cada pico de
//     insulina extra frena el objetivo metabólico.
//   - Se ordenan por hora: las N primeras son "las comidas", el resto son
//     extras (sin importar cuál fue mejor).

import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

enum MealQualityZone { chatarra, aceptable, saludable }

class MealQuality {
  const MealQuality._();

  /// Valor inicial de la barra: centro (Aceptable).
  static const double initial = 0.5;

  /// Resta por cada comida extra fuera de lo que pide el protocolo.
  static const double extraPenalty = 0.15;

  static MealQualityZone zoneOf(double q) {
    if (q < 1 / 3) return MealQualityZone.chatarra;
    if (q < 2 / 3) return MealQualityZone.aceptable;
    return MealQualityZone.saludable;
  }

  static String labelOf(double q) => switch (zoneOf(q)) {
        MealQualityZone.chatarra => 'Chatarra',
        MealQualityZone.aceptable => 'Aceptable',
        MealQualityZone.saludable => 'Saludable',
      };

  /// Frase corta que acompaña la barra mientras el usuario desliza.
  static String hintOf(double q) => switch (zoneOf(q)) {
        MealQualityZone.chatarra =>
          'Ultraprocesados, fritos, harinas o azúcar como protagonistas.',
        MealQualityZone.aceptable =>
          'Comida casera con algo de harina, procesado o porciones grandes.',
        MealQualityZone.saludable =>
          'Proteína, verduras y comida real. Poca harina y nada de azúcar.',
      };

  /// Equivalencia con el sistema anterior (A:E) para las piezas que aún
  /// leen `ratio` (analítica, histórico).
  static MealRatio ratioFor(double q) {
    if (q >= 0.9) return MealRatio.allA;
    if (q >= 0.67) return MealRatio.a3e1;
    if (q >= 0.45) return MealRatio.a2e1;
    if (q >= 0.2) return MealRatio.a1e1;
    return MealRatio.allE;
  }

  /// Puntaje del pilar Comida para las comidas del día metabólico.
  ///
  /// Solo cuenta logs con `quality`. Devuelve null si no hay ninguno (el
  /// llamador usa entonces el cálculo anterior, para días viejos).
  static double? dayScore(
    List<NutritionLog> logs, {
    required int targetMeals,
    bool allowsSnack = false,
  }) {
    final rated = logs.where((l) => l.quality != null).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (rated.isEmpty) return null;
    final n = targetMeals.clamp(1, 6);
    final main = rated.take(n);
    final extras = rated.skip(n).toList();
    var sum = main.fold<double>(0, (s, l) => s + l.quality!);
    var penalized = extras.length;
    if (allowsSnack && extras.isNotEmpty && extras.first.quality! >= 1 / 3) {
      penalized -= 1;
    }
    sum -= extraPenalty * penalized;
    return (sum / n).clamp(0.0, 1.0);
  }
}
