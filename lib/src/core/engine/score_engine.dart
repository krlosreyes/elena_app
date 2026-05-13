// SPEC-52: ScoreEngine consume MetabolicState (firma unificada).
//
// Antes: calculateIMR recibia 6 parametros sueltos (UserModel + fastingHours
// + weeklyAdherence + exerciseMin + sleepHours + lastMealTime + nutritionScore)
// y cada callsite en UI ensamblaba esos parametros con defaults distintos
// (lastMealTime defaulteado a now, sleepHours a 7.0 vs 0.0, etc.).
//
// Ahora: calculateIMR recibe (UserModel, MetabolicState). Una sola fuente de
// verdad. Los defaults dispersos se eliminan: si no hay datos, MetabolicState
// es .empty() y el imrProvider devuelve un score cero sin invocar al engine.
//
// SPEC-82: IMRv2Result expone tambien campos derivados (imc, tmb,
// metabolicAge, ica, ffmi, whtr) que el shape canonico del sitio web
// Metamorfosis Real necesita leer en `imr.current`. Se introduce
// ScoreEngine.calculateBaseline para usuarios que terminaron onboarding
// pero aun no tienen data behavioral.

import 'dart:math' as math;

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IMRv2Result {
  final int totalScore;
  final double structureScore;
  final double metabolicScore;
  final double behaviorScore;
  final double circadianAlignment;
  final String zone;
  final String description;

  // SPEC-82: campos derivados que el sitio web Metamorfosis Real espera
  // leer en `imr.current`. Se calculan dentro de
  // `ScoreEngine.calculateIMR` / `calculateBaseline` con los inputs ya
  // disponibles (no requieren data adicional).
  final double imc;
  final double tmb;
  final int metabolicAge;
  final double ica;
  final double ffmi;
  final double whtr;

  const IMRv2Result({
    required this.totalScore,
    required this.structureScore,
    required this.metabolicScore,
    required this.behaviorScore,
    required this.circadianAlignment,
    required this.zone,
    required this.description,
    required this.imc,
    required this.tmb,
    required this.metabolicAge,
    required this.ica,
    required this.ffmi,
    required this.whtr,
  });

  /// Resultado vacío para cuando no hay datos suficientes (estado inicial,
  /// usuario aún cargando, etc.). SPEC-60: sin DateTime.now().
  /// SPEC-82: incluye los campos derivados en 0.
  factory IMRv2Result.empty() => const IMRv2Result(
        totalScore: 0,
        structureScore: 0,
        metabolicScore: 0,
        behaviorScore: 0,
        circadianAlignment: 0,
        zone: 'N/A',
        description: 'Cargando...',
        imc: 0,
        tmb: 0,
        metabolicAge: 0,
        ica: 0,
        ffmi: 0,
        whtr: 0,
      );
}

class ScoreEngine {
  /// SPEC-52: nueva firma. Recibe el MetabolicState completo en lugar de
  /// 6 parámetros sueltos. Si `state.lastMealTime` es null, retorna
  /// `IMRv2Result.empty()` (la lógica circadiana requiere ese DateTime).
  IMRv2Result calculateIMR(UserModel user, MetabolicState state) {
    final lastMealTime = state.lastMealTime;
    if (lastMealTime == null) return IMRv2Result.empty();

    final bool isMale =
        user.gender.toUpperCase() == 'M' || user.gender.toUpperCase() == 'MALE';

    // 1. ESTRUCTURA (50%) — SPEC-70: ref §1.1, §2
    double s1 = 0.5;
    if (user.waistCircumference != null && user.waistCircumference! > 0) {
      final double whtr = user.waistCircumference! / user.height;
      // SPEC-70: ref §2.3 — umbrales WHtR 0.45–0.60 (Browning 2010).
      s1 = ((0.60 - whtr) / 0.15).clamp(0.0, 1.0);
    }
    final double hMeter = user.height / 100;
    final double leanMass = user.weight * (1 - (user.bodyFatPercentage / 100));
    final double ffmi = leanMass / math.pow(hMeter, 2);
    // SPEC-70.3: baseline FFMI age-stratified. La masa magra disminuye
    // ~1 punto por década después de los 50 (Kyle UG et al. 2003). Sin
    // este ajuste, un adulto mayor con FFMI 16.5 puntuaba "estructura
    // adecuada" cuando bibliográficamente está en sarcopenia franca, y
    // un joven con el mismo FFMI quedaba sobreestimado en su grupo.
    final double baseFFMI = _baseFFMIForAge(isMale, user.age);
    final double rangeFFMI = isMale ? 6.0 : 5.0;
    final double s2 = ((ffmi - baseFFMI) / rangeFFMI).clamp(0.0, 1.0);
    // SPEC-70: ref §2.1, §2.2 — pesos 0.65 WHtR + 0.35 FFMI.
    final double structureBlock = (0.65 * s1) + (0.35 * s2);

    // 2. METABOLISMO (25%) — SPEC-70: ref §1.2, §3
    final double fastingHours = state.fastingHoursRaw;
    // SPEC-53: el bloque metabólico ahora consume `weeklyQualityScore`
    // (continuo, ponderado por magnitudes de SPEC-65) en lugar de
    // `weeklyAdherence` (binario "días que cruzaron umbral"). Esto hace
    // que un usuario con 7 días apenas calificados puntúe distinto de
    // uno con 7 días al tope, aunque ambos cuenten como "adheridos".
    final double weeklySignal = state.weeklyQualityScore;
    // SPEC-70: ref §3.1 — sigmoid centrada en 14h, ancho 1.5
    // (Mattson 2017, Anton 2018).
    final double s4 = 1 / (1 + math.exp(-(fastingHours - 14) / 1.5));
    // SPEC-70.2: bonus eTRF como sigmoid suave (era salto binario en
    // hora=18). Sutton 2018 reporta efectos dosis-respuesta con ventanas
    // más tempranas, no umbral único. La curva se centra en 17:00 con
    // ancho 1.0h: bonus aproximado 1.13 a las 16:00, 1.075 a las 17:00,
    // 1.04 a las 18:00, 1.018 a las 19:00, ≈1.0 a partir de 21:00.
    // Asíntota superior 1.15 (preserva el techo del binario anterior).
    // SPEC-70: ref IMR_BIBLIOGRAPHY.md §3.3.
    final double mealHourFloat =
        lastMealTime.hour + lastMealTime.minute / 60.0;
    final double etrfSigmoid =
        1.0 / (1.0 + math.exp(-(mealHourFloat - 17.0) / 1.0));
    final double etrfBonus = 1.0 + 0.15 * (1.0 - etrfSigmoid);
    // SPEC-70: ref §3.2 — pesos 0.70 sigmoid + 0.30 calidad semanal.
    final double metabolicBlock =
        ((0.70 * s4) + (0.30 * weeklySignal.clamp(0.0, 1.0))) * etrfBonus;

    // 3. CONDUCTA Y CIRCADIANO (25%)
    double circadianScore = 1.0;

    // SPEC-59: comparación lineal en minutos totales desde medianoche.
    final DateTime? goal = user.profile.lastMealGoal;
    final int mealMinutes = lastMealTime.hour * 60 + lastMealTime.minute;

    if (mealMinutes >= CircadianRules.intestinalLockMinutes) {
      // SPEC-70.5: penalización al 0.5 por bloqueo intestinal 21:30
      // (Lopez-Minguez 2018, melatonina-MTNR1B). Antes era 22:30,
      // movido tras revisión clínica externa.
      circadianScore = 0.5;
    } else if (goal != null && lastMealTime.isBefore(goal)) {
      // Bonus eTRF por comer antes de la meta establecida.
      circadianScore = 1.1;
    }

    // SPEC-53: el bloque Conducta ahora consume `state.sleepQuality`
    // (multidimensional desde SPEC-69) en lugar de la curva binaria
    // antigua `(sleepHours >=7 && <=9) ? 1.0 : 0.6`. Esto hace que un
    // usuario con 8h de sueño fragmentado (latencia alta + 4 despertares
    // + cena tarde) puntúe distinto de uno con 8h reparadoras. La curva
    // binaria asignaba el mismo 1.0 a ambos.
    final double sSleep = state.sleepQuality.clamp(0.0, 1.0);
    final double exerciseMin = state.exerciseMinutesRaw;
    final double sExercise = (exerciseMin / 60).clamp(0.0, 1.2);
    final double nutritionScore = state.nutritionScoreRaw;
    // SPEC-67: hidratación entra al bloque Conducta. El campo state.hydrationLevel
    // ya viene normalizado 0.0-1.0 desde MetabolicStateBuilder
    // (currentAmountLiters / dailyGoalLiters).
    final double sHydration = state.hydrationLevel.clamp(0.0, 1.0);

    // SPEC-70.5: pesos del bloque Conducta recalibrados tras revisión
    // clínica externa. La hidratación al 20% era excesiva frente al
    // impacto clínico real (la deshidratación leve afecta menos que
    // la desincronización circadiana). El 10% liberado se transfiere
    // al Circadiano, que el especialista identificó como "el eje
    // maestro que regula el hambre y la reparación metabólica".
    //
    // Antes (SPEC-70):  Circadiano 28% / Sueño 20% / Ejercicio 20% /
    //                   Nutrición 12% / Hidratación 20%.
    // Ahora (SPEC-70.5): Circadiano 38% / Sueño 20% / Ejercicio 20% /
    //                    Nutrición 12% / Hidratación 10%.
    //
    // Suma = 100%. Ver IMR_BIBLIOGRAPHY.md §4 actualizada.
    final double behaviorBlock = (0.38 * circadianScore.clamp(0.0, 1.0)) +
        (0.20 * sSleep) +
        (0.20 * sExercise) +
        (0.12 * nutritionScore.clamp(0.0, 1.0)) +
        (0.10 * sHydration);

    // SPEC-70: ref §1 — macro 50/25/25 (Estructura/Metabolismo/Conducta).
    // ENGINEERING JUDGMENT del split exacto; estructura domina por
    // mayor estabilidad bibliográfica de su asociación con outcomes.
    final double raw = (0.50 * structureBlock) +
        (0.25 * metabolicBlock.clamp(0.0, 1.0)) +
        (0.25 * behaviorBlock);
    final int score = (raw * 100).round().clamp(0, 100);

    // SPEC-82: campos derivados para el shape canónico del sitio web.
    final double imc = user.weight / math.pow(hMeter, 2);
    final double ica = (user.waistCircumference ?? 0) > 0
        ? user.waistCircumference! / user.height
        : 0;
    // Mifflin-St Jeor (kcal/día) — estándar clínico vigente.
    //   hombres: 10w + 6.25h - 5a + 5
    //   mujeres: 10w + 6.25h - 5a - 161
    final double tmb = (10 * user.weight) +
        (6.25 * user.height) -
        (5 * user.age) +
        (isMale ? 5 : -161);
    final int metabolicAge =
        _metabolicAgeFromStructure(user.age, structureBlock);

    return IMRv2Result(
      totalScore: score,
      structureScore: structureBlock,
      metabolicScore: metabolicBlock.clamp(0.0, 1.0),
      behaviorScore: behaviorBlock,
      circadianAlignment: circadianScore.clamp(0.0, 1.0),
      zone: _getZone(score),
      description: _getDescription(score, circadianScore),
      imc: imc,
      tmb: tmb,
      metabolicAge: metabolicAge,
      ica: ica,
      ffmi: ffmi,
      whtr: ica,
    );
  }

  /// SPEC-82: IMR baseline cuando el usuario aún no tiene data
  /// behavioral (acabó de finalizar el onboarding, no logueó comidas).
  ///
  /// Usa SÓLO el bloque Estructura (50% del peso total). Los bloques
  /// Metabolismo y Conducta quedan en 0. El score baseline es
  /// necesariamente bajo: estructura óptima = 50/100 máximo.
  ///
  /// Esto permite al sitio web Metamorfosis Real mostrar un score
  /// inicial inmediatamente tras el onboarding desde la app, en lugar
  /// de "Sin diagnóstico". En cuanto el usuario tenga un log de
  /// comida, `calculateIMR` recomputa con el modelo completo.
  static IMRv2Result calculateBaseline(UserModel user) {
    final bool isMale =
        user.gender.toUpperCase() == 'M' || user.gender.toUpperCase() == 'MALE';

    // Recomputamos solo Estructura inline. Si en el futuro se extrae a
    // un método privado compartido con `calculateIMR`, hacerlo en una
    // SPEC separada para no expandir el scope de SPEC-82.
    double s1 = 0.5;
    if (user.waistCircumference != null && user.waistCircumference! > 0) {
      final double whtr = user.waistCircumference! / user.height;
      s1 = ((0.60 - whtr) / 0.15).clamp(0.0, 1.0);
    }
    final double hMeter = user.height / 100;
    final double leanMass = user.weight * (1 - (user.bodyFatPercentage / 100));
    final double ffmi = leanMass / math.pow(hMeter, 2);
    final double baseFFMI = _baseFFMIForAge(isMale, user.age);
    final double rangeFFMI = isMale ? 6.0 : 5.0;
    final double s2 = ((ffmi - baseFFMI) / rangeFFMI).clamp(0.0, 1.0);
    final double structureBlock = (0.65 * s1) + (0.35 * s2);

    // Score baseline = solo el peso de Estructura (50%).
    final double raw = 0.50 * structureBlock;
    final int score = (raw * 100).round().clamp(0, 100);

    final double imc = user.weight / math.pow(hMeter, 2);
    final double ica = (user.waistCircumference ?? 0) > 0
        ? user.waistCircumference! / user.height
        : 0;
    final double tmb = (10 * user.weight) +
        (6.25 * user.height) -
        (5 * user.age) +
        (isMale ? 5 : -161);
    final int metabolicAge = _metabolicAgeFromStructure(user.age, structureBlock);

    return IMRv2Result(
      totalScore: score,
      structureScore: structureBlock,
      metabolicScore: 0,
      behaviorScore: 0,
      circadianAlignment: 0,
      zone: _getZone(score),
      description: 'Baseline calculado sin data comportamental.',
      imc: imc,
      tmb: tmb,
      metabolicAge: metabolicAge,
      ica: ica,
      ffmi: ffmi,
      whtr: ica,
    );
  }

  /// SPEC-82: edad metabólica derivada del bloque Estructura.
  ///
  /// Fórmula provisional. Si structureBlock = 1.0 (óptimo), edad
  /// metabólica = edad cronológica. Si structureBlock = 0.0,
  /// metabolicAge = age + 20 (clamp inferior: age - 10, superior:
  /// age + 25). Documentar en `IMR_BIBLIOGRAPHY.md` y refinar con
  /// data propia (SPEC futura).
  static int _metabolicAgeFromStructure(int age, double structureBlock) {
    final int delta = (20 * (1 - structureBlock)).round();
    return (age + delta).clamp(age - 10, age + 25);
  }

  /// SPEC-70.3: baseline FFMI ajustado por edad y género.
  ///
  /// Antes (SPEC-70 base): `isMale ? 16.0 : 14.0` constante. Eso
  /// sobreestimaba la salud estructural de adultos mayores (un FFMI
  /// 16.5 a los 70 años está en territorio de sarcopenia, no
  /// "adecuado") y subestimaba la de adultos jóvenes (16.5 a los 25
  /// es bottom-percentile real).
  ///
  /// Ahora: el baseline (percentil ~5 = umbral de sarcopenia) cae ~1
  /// punto por década después de los 50, replicando la pérdida natural
  /// de masa magra documentada en literatura.
  ///
  /// Referencia: Kyle UG, Genton L, Hans D, Karsegard L, Slosman DO,
  /// Pichard C. "Age, gender, and BMI-adjusted reference values for
  /// fat-free mass index by bioelectrical impedance analysis in 5225
  /// healthy subjects aged 15 to 98 years." Am J Clin Nutr 2003;77(2):323-9.
  ///
  /// El `rangeFFMI` se mantiene constante (6.0 hombres, 5.0 mujeres) —
  /// la varianza poblacional comprime levemente con la edad pero
  /// estratificarlo añade complejidad sin mover materialmente el score.
  /// SPEC-70.3.1 puede refinar si datos propios lo justifican.
  ///
  /// SPEC-70: ref IMR_BIBLIOGRAPHY.md §2.4 (actualizado).
  static double _baseFFMIForAge(bool isMale, int age) {
    final double peak = isMale ? 17.0 : 14.5;
    if (age < 50) return peak;
    if (age < 60) return peak - 0.5;
    if (age < 70) return peak - 1.0;
    return peak - 1.5;
  }

  // SPEC-82: hechos estáticos para que `calculateBaseline` (también
  // estático) los pueda invocar sin instanciar el engine.
  static String _getZone(int s) {
    if (s < 40) return 'DETERIORADO';
    if (s < 60) return 'INESTABLE';
    if (s < 75) return 'FUNCIONAL';
    if (s < 90) return 'EFICIENTE';
    return 'OPTIMIZADO';
  }

  static String _getDescription(int s, double circadian) {
    if (circadian < 0.7) {
      return 'Alerta: Ingesta nocturna detectada. Esto bloquea la reparación celular.';
    }
    if (s < 60) return 'Prioridad: Reducción de grasa visceral y ajuste de ritmos.';
    return 'Estado metabólico funcional con margen de mejora.';
  }
}

final scoreEngineProvider = Provider<ScoreEngine>((ref) => ScoreEngine());
