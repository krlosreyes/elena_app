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
// SPEC-141 (2026-06-05): import del dominio de streak para
// calculateLongitudinalIMR.
import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
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

  // SPEC-141 (2026-06-05): campos opcionales del IMR longitudinal.
  // Solo se pueblan cuando el resultado proviene de
  // `calculateLongitudinalIMR`. `calculateIMR` (diario) y
  // `calculateBaseline` (onboarding) los dejan null para no romper
  // consumidores legacy.
  //
  // - `longitudinalScore`: 0..100, agregado 40/35/15/10.
  // - `subscoreBehaviorTrend`: 0..1, promedio dailyQualityScore 30d.
  // - `subscoreAdherence`: 0..1, racha + active days 90.
  // - `subscoreCoherence`: 0..1, state.metabolicCoherence.
  // `subscoreStructure` no agregado — el campo existente
  // `structureScore` lo cubre.
  final int? longitudinalScore;
  final double? subscoreBehaviorTrend;
  final double? subscoreAdherence;
  final double? subscoreCoherence;

  // SPEC-229: true cuando el bloque Estructura usa datos de población
  // (NHANES/FFMI) porque waistCircumference o bodyFatPercentage son null.
  // El 50% del IMR puede ser genérico — la UI debe indicarlo al usuario
  // para incentivar la completitud de biometrías.
  final bool isPartialBiometrics;

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
    this.longitudinalScore,
    this.subscoreBehaviorTrend,
    this.subscoreAdherence,
    this.subscoreCoherence,
    this.isPartialBiometrics = false,
  });

  // ───────────────────────────────────────────────────────────────────
  // I-01 (auditoría 2026-07-27): igualdad estructural.
  //
  // Sin `==`, Riverpod comparaba por identidad. Como `imrProvider` crea un
  // IMRv2Result nuevo en cada emisión de `metabolicStateProvider` —y ese
  // cambia cada 10 s mientras hay un ayuno activo, porque `fastingHoursRaw`
  // avanza—, el provider notificaba SIEMPRE a todos sus consumidores.
  //
  // Coste medido sobre un ayuno de 16h: ~5.760 recomputaciones completas
  // del motor (sigmoides, exponenciales) y ~5.760 ciclos de rebuild del
  // árbol de consumidores, para mostrar un número que en 10 segundos no se
  // había movido. Con `==` estructural, Riverpod corta la notificación en
  // cuanto el resultado visible es idéntico.
  //
  // Se comparan solo los campos que forman el resultado; no hay campos
  // mutables ni colecciones, así que la igualdad es barata y total.
  // ───────────────────────────────────────────────────────────────────
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IMRv2Result &&
          runtimeType == other.runtimeType &&
          totalScore == other.totalScore &&
          structureScore == other.structureScore &&
          metabolicScore == other.metabolicScore &&
          behaviorScore == other.behaviorScore &&
          circadianAlignment == other.circadianAlignment &&
          zone == other.zone &&
          description == other.description &&
          imc == other.imc &&
          tmb == other.tmb &&
          metabolicAge == other.metabolicAge &&
          ica == other.ica &&
          ffmi == other.ffmi &&
          whtr == other.whtr &&
          longitudinalScore == other.longitudinalScore &&
          subscoreBehaviorTrend == other.subscoreBehaviorTrend &&
          subscoreAdherence == other.subscoreAdherence &&
          subscoreCoherence == other.subscoreCoherence &&
          isPartialBiometrics == other.isPartialBiometrics;

  @override
  int get hashCode => Object.hashAll([
        totalScore,
        structureScore,
        metabolicScore,
        behaviorScore,
        circadianAlignment,
        zone,
        description,
        imc,
        tmb,
        metabolicAge,
        ica,
        ffmi,
        whtr,
        longitudinalScore,
        subscoreBehaviorTrend,
        subscoreAdherence,
        subscoreCoherence,
        isPartialBiometrics,
      ]);

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
  // ─── SPEC-audit CODE-03 (2026-07-11): coeficientes nombrados ───────────
  //
  // Estas constantes NO cambian ningún valor numérico de las fórmulas
  // originales — solo les ponen nombre para hacerlas legibles/auditables.
  // Cuando dos fórmulas distintas coinciden en el mismo valor (p.ej. 0.5,
  // 0.35, 0.10, 0.15, 0.25), se declaran constantes SEPARADAS con nombres
  // distintos salvo que sea literalmente la MISMA fórmula duplicada (ver
  // caso Estructura abajo) — la coincidencia numérica es casual entre
  // fórmulas semánticamente distintas, y forzarlas a compartir constante
  // crearía un acoplamiento falso (cambiar una cambiaría la otra sin
  // que exista relación real entre ambas).

  // Bloque ESTRUCTURA (WHtR + FFMI). La fórmula se repite IDÉNTICA en
  // `calculateIMR` y `calculateBaseline` (ver comentario en
  // `calculateBaseline`: "recomputamos solo Estructura inline") — por eso
  // SÍ comparten las mismas constantes en ambos métodos.
  /// s1 neutro (ni bueno ni malo) cuando el usuario no tiene
  /// `waistCircumference` registrado.
  static const double _kStructureDefaultWhtrScore = 0.5;

  /// Umbral WHtR superior de la normalización (Browning 2010).
  /// SPEC-70: ref §2.3 — umbrales WHtR 0.45–0.60.
  static const double _kWhtrUpperThreshold = 0.60;

  /// Rango (0.60 - 0.45) usado para normalizar WHtR a [0, 1].
  static const double _kWhtrRange = 0.15;

  /// Peso de WHtR dentro del bloque Estructura.
  /// SPEC-70: ref §2.1, §2.2 — pesos 0.65 WHtR + 0.35 FFMI.
  static const double _kStructureWhtrWeight = 0.65;

  /// Peso de FFMI dentro del bloque Estructura.
  static const double _kStructureFfmiWeight = 0.35;

  // Bloque METABOLISMO (sigmoid de ayuno + bonus eTRF).
  /// Centro (horas de ayuno) de la sigmoid metabólica (Mattson 2017,
  /// Anton 2018). SPEC-70: ref §3.1.
  static const double _kFastingSigmoidCenterHours = 14.0;

  /// Ancho de la sigmoid metabólica.
  static const double _kFastingSigmoidWidthHours = 1.5;

  /// Centro (hora del día de la última comida) de la sigmoid eTRF.
  /// SPEC-70.2: ref IMR_BIBLIOGRAPHY.md §3.3.
  static const double _kEtrfSigmoidCenterHour = 17.0;

  /// Ancho de la sigmoid eTRF.
  static const double _kEtrfSigmoidWidthHours = 1.0;

  /// Amplitud del bonus eTRF (techo ≈1.15x, Sutton 2018).
  static const double _kEtrfBonusAmplitude = 0.15;

  /// Peso de la sigmoid de ayuno dentro del bloque Metabolismo.
  /// SPEC-70: ref §3.2 — pesos 0.70 sigmoid + 0.30 calidad semanal.
  static const double _kMetabolicSigmoidWeight = 0.70;

  /// Peso de `weeklyQualityScore` dentro del bloque Metabolismo.
  static const double _kMetabolicWeeklyQualityWeight = 0.30;

  // Bloque CONDUCTA Y CIRCADIANO.
  /// Penalización de `circadianScore` al comer tras el bloqueo intestinal
  /// (21:30, Lopez-Minguez 2018). SPEC-70.5.
  static const double _kCircadianLockPenaltyScore = 0.5;

  /// Bonus de `circadianScore` al comer antes de `profile.lastMealGoal`.
  static const double _kCircadianEarlyBonusScore = 1.1;

  /// Minutos de ejercicio que equivalen a 1.0 en `sExercise` (60min = 1.0).
  static const double _kExerciseMinutesNormalization = 60.0;

  /// Techo permitido de `sExercise` (permite "sobre-cumplimiento" hasta 1.2).
  static const double _kExerciseScoreUpperClamp = 1.2;

  /// Pesos del bloque Conducta (recalibrados SPEC-70.5). Suma = 1.0.
  /// Antes (SPEC-70): Circadiano 28% / Sueño 20% / Ejercicio 20% /
  /// Nutrición 12% / Hidratación 20%. Ahora: Circadiano 38% / Hidratación 10%.
  static const double _kBehaviorCircadianWeight = 0.38;
  static const double _kBehaviorSleepWeight = 0.20;
  static const double _kBehaviorExerciseWeight = 0.20;
  static const double _kBehaviorNutritionWeight = 0.12;
  static const double _kBehaviorHydrationWeight = 0.10;

  // Macro (Estructura/Metabolismo/Conducta). SPEC-70: ref §1 — 50/25/25.
  // `_kMacroStructureWeight` se reusa en `calculateBaseline` (mismo peso
  // macro de Estructura aplicado ahí solo, sin Metabolismo/Conducta).
  static const double _kMacroStructureWeight = 0.50;
  static const double _kMacroMetabolicWeight = 0.25;
  static const double _kMacroBehaviorWeight = 0.25;

  // IMR LONGITUDINAL (SPEC-141 §RF-141-01). Aunque `_kLongitudinalStructureWeight`
  // coincide en valor con otras constantes de otros bloques en algún punto,
  // son macro-pesos de una fórmula totalmente distinta (agregado 30d/90d),
  // así que se declaran aparte.
  static const double _kLongitudinalStructureWeight = 0.40;
  static const double _kLongitudinalBehaviorTrendWeight = 0.35;
  static const double _kLongitudinalAdherenceWeight = 0.15;
  static const double _kLongitudinalCoherenceWeight = 0.10;

  /// SPEC-92: fallback poblacional cuando `bodyFatPercentage` es null.
  /// Antes el UserModel tenía `@Default(20.0)` que disfrazaba la
  /// ausencia de datos como "20% confirmado". Ahora el campo puede ser
  /// null; este helper devuelve un valor que permite calcular un IMR
  /// pero el caller debería propagar `confidenceLevel: 'BAJA'` cuando
  /// se activa este fallback (no se pierde la señal — UserModel sigue
  /// teniendo `confidenceLevel` que el onboarding pinta correctamente).
  static double _effectiveBodyFatPct(UserModel user, bool isMale) {
    final stored = user.bodyFatPercentage;
    if (stored != null && stored > 0) return stored;
    // Fallback poblacional aproximado (NHANES, adultos sedentarios).
    return isMale ? 15.0 : 25.0;
  }

  /// SPEC-52: nueva firma. Recibe el MetabolicState completo en lugar de
  /// 6 parámetros sueltos. Si `state.lastMealTime` es null, retorna
  /// `IMRv2Result.empty()` (la lógica circadiana requiere ese DateTime).
  IMRv2Result calculateIMR(UserModel user, MetabolicState state) {
    final lastMealTime = state.lastMealTime;
    if (lastMealTime == null) return IMRv2Result.empty();

    final bool isMale =
        user.gender.toUpperCase() == 'M' || user.gender.toUpperCase() == 'MALE';

    // 1. ESTRUCTURA (50%) — SPEC-70: ref §1.1, §2
    double s1 = _kStructureDefaultWhtrScore;
    if (user.waistCircumference != null && user.waistCircumference! > 0) {
      final double whtr = user.waistCircumference! / user.height;
      // SPEC-70: ref §2.3 — umbrales WHtR 0.45–0.60 (Browning 2010).
      s1 = ((_kWhtrUpperThreshold - whtr) / _kWhtrRange).clamp(0.0, 1.0);
    }
    final double hMeter = user.height / 100;
    // SPEC-92: bodyFat nullable → fallback poblacional explícito.
    final double bodyFatPct = _effectiveBodyFatPct(user, isMale);
    final double leanMass = user.weight * (1 - (bodyFatPct / 100));
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
    final double structureBlock =
        (_kStructureWhtrWeight * s1) + (_kStructureFfmiWeight * s2);

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
    final double s4 = 1 /
        (1 +
            math.exp(-(fastingHours - _kFastingSigmoidCenterHours) /
                _kFastingSigmoidWidthHours));
    // SPEC-70.2: bonus eTRF como sigmoid suave (era salto binario en
    // hora=18). Sutton 2018 reporta efectos dosis-respuesta con ventanas
    // más tempranas, no umbral único. La curva se centra en 17:00 con
    // ancho 1.0h: bonus aproximado 1.13 a las 16:00, 1.075 a las 17:00,
    // 1.04 a las 18:00, 1.018 a las 19:00, ≈1.0 a partir de 21:00.
    // Asíntota superior 1.15 (preserva el techo del binario anterior).
    // SPEC-70: ref IMR_BIBLIOGRAPHY.md §3.3.
    final double mealHourFloat = lastMealTime.hour + lastMealTime.minute / 60.0;
    final double etrfSigmoid = 1.0 /
        (1.0 +
            math.exp(-(mealHourFloat - _kEtrfSigmoidCenterHour) /
                _kEtrfSigmoidWidthHours));
    final double etrfBonus = 1.0 + _kEtrfBonusAmplitude * (1.0 - etrfSigmoid);
    // SPEC-70: ref §3.2 — pesos 0.70 sigmoid + 0.30 calidad semanal.
    final double metabolicBlock = ((_kMetabolicSigmoidWeight * s4) +
            (_kMetabolicWeeklyQualityWeight * weeklySignal.clamp(0.0, 1.0))) *
        etrfBonus;

    // 3. CONDUCTA Y CIRCADIANO (25%)
    double circadianScore = 1.0;

    // SPEC-59: comparación lineal en minutos totales desde medianoche.
    final DateTime? goal = user.profile.lastMealGoal;
    final int mealMinutes = lastMealTime.hour * 60 + lastMealTime.minute;

    if (mealMinutes >= CircadianRules.intestinalLockMinutes) {
      // SPEC-70.5: penalización al 0.5 por bloqueo intestinal 21:30
      // (Lopez-Minguez 2018, melatonina-MTNR1B). Antes era 22:30,
      // movido tras revisión clínica externa.
      circadianScore = _kCircadianLockPenaltyScore;
    } else if (goal != null && lastMealTime.isBefore(goal)) {
      // Bonus eTRF por comer antes de la meta establecida.
      circadianScore = _kCircadianEarlyBonusScore;
    }

    // SPEC-53: el bloque Conducta ahora consume `state.sleepQuality`
    // (multidimensional desde SPEC-69) en lugar de la curva binaria
    // antigua `(sleepHours >=7 && <=9) ? 1.0 : 0.6`. Esto hace que un
    // usuario con 8h de sueño fragmentado (latencia alta + 4 despertares
    // + cena tarde) puntúe distinto de uno con 8h reparadoras. La curva
    // binaria asignaba el mismo 1.0 a ambos.
    final double sSleep = state.sleepQuality.clamp(0.0, 1.0);
    final double exerciseMin = state.exerciseMinutesRaw;
    final double sExercise = (exerciseMin / _kExerciseMinutesNormalization)
        .clamp(0.0, _kExerciseScoreUpperClamp);
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
    //
    // SPEC-237 BUG-A: circadianScore NO se clampea aquí — debe llegar sin
    // clamp al bloque para que el bonus eTRF (1.1) tenga efecto real.
    // El clamp global a 100 en `score` ya absorbe cualquier exceso.
    // Solo circadianAlignment (indicador UI 0-1) sigue clampado en el return.
    final double behaviorBlock = (_kBehaviorCircadianWeight * circadianScore) +
        (_kBehaviorSleepWeight * sSleep) +
        (_kBehaviorExerciseWeight * sExercise) +
        (_kBehaviorNutritionWeight * nutritionScore.clamp(0.0, 1.0)) +
        (_kBehaviorHydrationWeight * sHydration);

    // SPEC-70: ref §1 — macro 50/25/25 (Estructura/Metabolismo/Conducta).
    // ENGINEERING JUDGMENT del split exacto; estructura domina por
    // mayor estabilidad bibliográfica de su asociación con outcomes.
    final double raw = (_kMacroStructureWeight * structureBlock) +
        (_kMacroMetabolicWeight * metabolicBlock.clamp(0.0, 1.0)) +
        (_kMacroBehaviorWeight * behaviorBlock);
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

    // SPEC-229: detecta datos poblacionales en bloque Estructura (50% del IMR).
    final bool isPartial =
        (user.waistCircumference == null || user.waistCircumference! <= 0) ||
            (user.bodyFatPercentage == null || user.bodyFatPercentage! <= 0);

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
      // SPEC-237 BUG-B: whtr usa su propio cálculo explícito en lugar de
      // reutilizar `ica` como alias. Son matemáticamente equivalentes
      // (cintura/altura) pero mantener variables distintas hace el código
      // auto-documentado y evita confusión futura si las fórmulas divergen.
      whtr: (user.waistCircumference ?? 0) > 0
          ? user.waistCircumference! / user.height
          : 0.0,
      isPartialBiometrics: isPartial,
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
    double s1 = _kStructureDefaultWhtrScore;
    if (user.waistCircumference != null && user.waistCircumference! > 0) {
      final double whtr = user.waistCircumference! / user.height;
      s1 = ((_kWhtrUpperThreshold - whtr) / _kWhtrRange).clamp(0.0, 1.0);
    }
    final double hMeter = user.height / 100;
    // SPEC-92: bodyFat nullable → fallback poblacional explícito.
    final double bodyFatPct = _effectiveBodyFatPct(user, isMale);
    final double leanMass = user.weight * (1 - (bodyFatPct / 100));
    final double ffmi = leanMass / math.pow(hMeter, 2);
    final double baseFFMI = _baseFFMIForAge(isMale, user.age);
    final double rangeFFMI = isMale ? 6.0 : 5.0;
    final double s2 = ((ffmi - baseFFMI) / rangeFFMI).clamp(0.0, 1.0);
    final double structureBlock =
        (_kStructureWhtrWeight * s1) + (_kStructureFfmiWeight * s2);

    // Score baseline = solo el peso de Estructura (50%).
    final double raw = _kMacroStructureWeight * structureBlock;
    final int score = (raw * 100).round().clamp(0, 100);

    final double imc = user.weight / math.pow(hMeter, 2);
    final double ica = (user.waistCircumference ?? 0) > 0
        ? user.waistCircumference! / user.height
        : 0;
    final double tmb = (10 * user.weight) +
        (6.25 * user.height) -
        (5 * user.age) +
        (isMale ? 5 : -161);
    final int metabolicAge =
        _metabolicAgeFromStructure(user.age, structureBlock);

    // SPEC-229: baseline siempre es parcial (sin comportamiento Y posiblemente
    // sin biometrías reales). El 50% estructura ya usa defaults poblacionales.
    final bool baselineIsPartial =
        (user.waistCircumference == null || user.waistCircumference! <= 0) ||
            (user.bodyFatPercentage == null || user.bodyFatPercentage! <= 0);

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
      // SPEC-237 BUG-B: mismo fix que calculateIMR — whtr explícito.
      whtr: (user.waistCircumference ?? 0) > 0
          ? user.waistCircumference! / user.height
          : 0.0,
      isPartialBiometrics: baselineIsPartial,
    );
  }

  /// SPEC-141 §RF-141-01 (2026-06-05): IMR longitudinal compuesto.
  ///
  /// Combina composición corporal (40% — bloque Estructura existente)
  /// con adherencia sostenida (35% — `dailyQualityScore` promedio 30d),
  /// consistencia (15% — racha + presencia 90d) y coherencia metabólica
  /// (10% — `state.metabolicCoherence`).
  ///
  /// Reemplaza el rol identitario del IMR diario en el badge de Perfil
  /// cuando `kEnableLongitudinalImr = true` (SPEC-141 D, feature flag).
  /// El IMR diario (`calculateIMR`) se preserva sin cambios para la
  /// pantalla Análisis.
  ///
  /// Casos:
  /// - `history.length < 7` → renormalización: los pesos de los
  ///   componentes longitudinales se transfieren proporcionalmente a
  ///   Estructura. Un usuario que acaba de terminar onboarding obtiene
  ///   `score ≈ structureBlock × 100` (mismo techo que
  ///   `calculateBaseline`, no peor).
  /// - Si `state.lastMealTime` es null → retorna `IMRv2Result.empty()`
  ///   con `longitudinalScore: null` (mismo trato que `calculateIMR`).
  ///
  /// Validación clínica: SPEC-141 v1.1 APPROVED-DESIGN. Antes de habilitar
  /// el feature flag, el especialista que firmó SPEC-70.5 debe validar
  /// los 4 pesos macro.
  IMRv2Result calculateLongitudinalIMR(
    UserModel user,
    MetabolicState state,
    List<StreakEntry> history,
  ) {
    // Reusamos el cálculo completo del IMR diario para obtener
    // structureScore, imc, tmb, etc. — son los mismos derivados que el
    // sitio web Metamorfosis Real espera.
    final daily = calculateIMR(user, state);
    if (daily.totalScore == 0 && daily.zone == 'N/A') {
      // Sin lastMealTime → empty(). Mismo comportamiento que el legacy.
      return daily;
    }

    final structure = daily.structureScore.clamp(0.0, 1.0);
    final behaviorTrend = StreakEngine.computeMonthlyQualityScore(history);
    final adherenceTrend = StreakEngine.computeAdherenceTrend(history);
    final coherence = state.metabolicCoherence.clamp(0.0, 1.0);

    // SPEC-141 §RF-141-05: renormalización para usuarios con historial
    // corto. Los 60% de los pesos no-estructurales se transfieren a
    // Estructura cuando hay menos de 7 entradas calificadas.
    //
    // Conteo de "entradas válidas": entradas con magnitudes (no legacy
    // sin magnitudes). Esto es proxy de "días que ya generaron señal
    // suficiente para el promedio mensual".
    final qualifiedHistory = history.where((e) => e.hasMagnitudes).toList();
    final hasEnoughHistory = qualifiedHistory.length >= 7;

    final double raw;
    if (hasEnoughHistory) {
      raw = _kLongitudinalStructureWeight * structure +
          _kLongitudinalBehaviorTrendWeight * behaviorTrend +
          _kLongitudinalAdherenceWeight * adherenceTrend +
          _kLongitudinalCoherenceWeight * coherence;
    } else {
      // Renormalización: transfiere los 60% no-Estructura a Estructura.
      // Esto preserva el techo y semánticamente dice "aún no tengo señal
      // longitudinal suficiente, te puntúo solo por composición".
      raw = structure;
    }

    final longScore = (raw.clamp(0.0, 1.0) * 100).round().clamp(0, 100);

    return IMRv2Result(
      totalScore: daily.totalScore, // legacy daily preservado
      structureScore: daily.structureScore,
      metabolicScore: daily.metabolicScore,
      behaviorScore: daily.behaviorScore,
      circadianAlignment: daily.circadianAlignment,
      zone: _getZone(longScore),
      description: hasEnoughHistory
          ? _getDescription(longScore, daily.circadianAlignment)
          : 'Perfil estructural — sigue registrando para ver tendencia.',
      imc: daily.imc,
      tmb: daily.tmb,
      metabolicAge: daily.metabolicAge,
      ica: daily.ica,
      ffmi: daily.ffmi,
      whtr: daily.whtr,
      // SPEC-141: campos longitudinales poblados.
      longitudinalScore: longScore,
      subscoreBehaviorTrend: behaviorTrend,
      subscoreAdherence: adherenceTrend,
      subscoreCoherence: coherence,
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
    if (s < 60) {
      return 'Prioridad: Reducción de grasa visceral y ajuste de ritmos.';
    }
    return 'Estado metabólico funcional con margen de mejora.';
  }
}

final scoreEngineProvider = Provider<ScoreEngine>((ref) => ScoreEngine());
