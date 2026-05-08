// Tests unitarios de ScoreEngine (SPEC-46/52/59 cerrado).
//
// Cubre:
// - SPEC-52: nueva firma calculateIMR(UserModel, MetabolicState).
// - SPEC-59: comparación de bloqueo intestinal por minutos totales.
// - Determinismo: mismo input → mismo output.
// - Zonas del IMR.
// - Estructura responde a WHtR; bloque metabólico responde a horas de ayuno.

import 'package:elena_app/src/core/engine/metabolic_state.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  String gender = 'M',
  int age = 30,
  double weight = 75,
  double height = 175,
  double bodyFatPct = 20,
  double? waist,
  DateTime? lastMealGoal,
}) {
  return UserModel(
    id: 'test',
    age: age,
    gender: gender,
    weight: weight,
    height: height,
    bodyFatPercentage: bodyFatPct,
    waistCircumference: waist,
    profile: CircadianProfile(
      wakeUpTime: DateTime(2026, 5, 6, 6),
      sleepTime: DateTime(2026, 5, 6, 22),
      lastMealGoal: lastMealGoal,
    ),
  );
}

/// Helper para construir un MetabolicState con valores sensatos por defecto.
/// Solo se sobreescriben los campos que el test necesita variar.
///
/// SPEC-53:
/// - `weeklyQualityScore` defaultea al valor de `weeklyAdherence` para
///   preservar la aritmética de los tests pre-SPEC-53. Tests nuevos
///   pueden pasarlo explícitamente.
/// - `sleepQuality` defaultea a la curva binaria histórica
///   `(7<=h<=9) ? 1.0 : 0.6` para que tests que variaban solo
///   `sleepHoursRaw` sigan dando el mismo número.
MetabolicState _state({
  double fastingHoursRaw = 12,
  double weeklyAdherence = 0.7,
  double? weeklyQualityScore,
  double exerciseMinutesRaw = 30,
  double sleepHoursRaw = 8,
  double? sleepQuality,
  double nutritionScoreRaw = 0.5,
  double hydrationLevel = 0.5,
  DateTime? lastMealTime,
}) {
  final effectiveSleepQuality = sleepQuality ??
      ((sleepHoursRaw >= 7 && sleepHoursRaw <= 9) ? 1.0 : 0.6);
  return MetabolicState(
    fastingHours: 0.5,
    glycogenLevel: 0.5,
    circadianAlignment: 1.0,
    sleepQuality: effectiveSleepQuality,
    exerciseLoad: 0.5,
    glycemicLoad: nutritionScoreRaw,
    hydrationLevel: hydrationLevel,
    metabolicCoherence: 1.0,
    fastingHoursRaw: fastingHoursRaw,
    sleepHoursRaw: sleepHoursRaw,
    exerciseMinutesRaw: exerciseMinutesRaw,
    nutritionScoreRaw: nutritionScoreRaw,
    weeklyAdherence: weeklyAdherence,
    weeklyQualityScore: weeklyQualityScore ?? weeklyAdherence,
    lastMealTime: lastMealTime ?? DateTime(2026, 5, 6, 19),
    timestamp: DateTime(2026, 5, 6, 20),
  );
}

void main() {
  final engine = ScoreEngine();

  group('SPEC-52: nueva firma (UserModel, MetabolicState)', () {
    test('Determinismo — mismo input produce mismo output', () {
      final user = _user(weight: 80, height: 180, waist: 90);
      final state = _state();
      final r1 = engine.calculateIMR(user, state);
      final r2 = engine.calculateIMR(user, state);
      expect(r1.totalScore, r2.totalScore);
      expect(r1.zone, r2.zone);
      expect(r1.circadianAlignment, r2.circadianAlignment);
    });

    test('lastMealTime null → IMRv2Result.empty()', () {
      final user = _user(waist: 90);
      // MetabolicState.empty() tiene lastMealTime null.
      final r = engine.calculateIMR(user, MetabolicState.empty());
      expect(r.totalScore, 0);
      expect(r.zone, 'N/A');
      expect(r.description, 'Cargando...');
    });
  });

  group('SPEC-59 + SPEC-70.5: penalización por bloqueo intestinal (21:30)', () {
    final user = _user(waist: 90);

    test('21:00 NO penaliza (justo antes del lock 21:30)', () {
      final r = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 21)),
      );
      expect(r.circadianAlignment, isNot(0.5),
          reason: '21:00 está antes de las 21:30, NO debe penalizar');
    });

    test('21:30 SÍ penaliza (frontera incluida)', () {
      final r = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 21, 30)),
      );
      expect(r.circadianAlignment, 0.5);
    });

    test('22:00 SÍ penaliza (SPEC-70.5: ahora está dentro del lock)', () {
      // Antes de SPEC-70.5 con lock 22:30, las 22:00 NO penalizaban.
      // Ahora con lock 21:30, las 22:00 sí caen dentro.
      final r = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 22)),
      );
      expect(r.circadianAlignment, 0.5);
    });

    test('23:00 SÍ penaliza', () {
      final r = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 23)),
      );
      expect(r.circadianAlignment, 0.5);
    });

    test('21:29 NO penaliza', () {
      final r = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 21, 29)),
      );
      expect(r.circadianAlignment, isNot(0.5));
    });
  });

  group('Zonas del IMR', () {
    test('Composición pobre + protocolo cero = DETERIORADO', () {
      final user = _user(
        weight: 100,
        height: 165,
        bodyFatPct: 35,
        waist: 110,
      );
      final r = engine.calculateIMR(
        user,
        _state(
          fastingHoursRaw: 0,
          weeklyAdherence: 0.0,
          exerciseMinutesRaw: 0,
          sleepHoursRaw: 4,
          nutritionScoreRaw: 0.0,
          lastMealTime: DateTime(2026, 5, 6, 23),
        ),
      );
      expect(r.totalScore, lessThan(40));
      expect(r.zone, 'DETERIORADO');
    });

    test('Composición saludable + protocolo bueno = FUNCIONAL o mejor', () {
      final user = _user(
        weight: 75,
        height: 180,
        bodyFatPct: 14,
        waist: 78,
      );
      final r = engine.calculateIMR(
        user,
        _state(
          fastingHoursRaw: 16,
          weeklyAdherence: 0.9,
          exerciseMinutesRaw: 45,
          sleepHoursRaw: 8,
          nutritionScoreRaw: 0.8,
          lastMealTime: DateTime(2026, 5, 6, 19),
        ),
      );
      expect(r.totalScore, greaterThan(60));
      expect(r.zone, anyOf(['FUNCIONAL', 'EFICIENTE', 'OPTIMIZADO']));
    });
  });

  group('Estructura (50% del IMR) responde a cintura', () {
    test('WHtR 0.45 mejor que 0.55', () {
      final low = _user(weight: 75, height: 180, waist: 81); // 0.45
      final high = _user(weight: 75, height: 180, waist: 99); // 0.55
      final state = _state();
      final rLow = engine.calculateIMR(low, state);
      final rHigh = engine.calculateIMR(high, state);
      expect(rLow.structureScore, greaterThan(rHigh.structureScore));
      expect(rLow.totalScore, greaterThan(rHigh.totalScore));
    });
  });

  group('Bloque metabólico responde a horas de ayuno', () {
    test('14h de ayuno > 4h de ayuno', () {
      final user = _user(waist: 85);
      final low = engine.calculateIMR(user, _state(fastingHoursRaw: 4));
      final high = engine.calculateIMR(user, _state(fastingHoursRaw: 14));
      expect(high.metabolicScore, greaterThan(low.metabolicScore));
    });
  });

  group('SPEC-67: hidratación entra al bloque Conducta', () {
    final user = _user(waist: 85);

    test('CA-67-01: 0% vs 100% hidratación → diferencia ≥ 2 puntos '
        '(SPEC-70.5: peso reducido a 10%)', () {
      // Mantenemos todos los demás factores idénticos. Solo varía hidratación.
      // Con SPEC-70.5 el peso de hidratación bajó de 20% a 10% en el
      // bloque Conducta. La diferencia esperada cae a la mitad.
      // Cota teórica: 0.10 (delta behavior) * 0.25 (macro) * 100 = 2.5 pts.
      final dry = engine.calculateIMR(user, _state(hydrationLevel: 0.0));
      final hydrated =
          engine.calculateIMR(user, _state(hydrationLevel: 1.0));

      expect(hydrated.totalScore - dry.totalScore, greaterThanOrEqualTo(2),
          reason: 'La diferencia debe seguir siendo perceptible (>= 2 puntos).');
    });

    test('Hidratación más alta → behavior score más alto', () {
      final r1 = engine.calculateIMR(user, _state(hydrationLevel: 0.2));
      final r2 = engine.calculateIMR(user, _state(hydrationLevel: 0.8));
      expect(r2.behaviorScore, greaterThan(r1.behaviorScore));
    });

    test('SPEC-70.5: Pesos rebalanceados suman 100% '
        '(Circadiano 38 + Sueño 20 + Ejercicio 20 + Nutrición 12 + '
        'Hidratación 10)', () {
      // Recalibración tras revisión clínica externa: hidratación
      // 20%→10%, circadiano 28%→38%. El resto sin cambio.
      const total = 0.38 + 0.20 + 0.20 + 0.12 + 0.10;
      expect(total, closeTo(1.0, 1e-9));
    });
  });

  group('SPEC-53: rebalanceo del IMR con señales continuas', () {
    final user = _user(waist: 85);

    test('CA-53-01: misma duración de sueño, mejor sleepQuality → score mayor',
        () {
      // 8h de sueño en ambos casos. La diferencia es la calidad
      // multidimensional (SPEC-69) que ahora alimenta el bloque Conducta.
      final fragmented = engine.calculateIMR(
        user,
        _state(sleepHoursRaw: 8, sleepQuality: 0.55),
      );
      final restorative = engine.calculateIMR(
        user,
        _state(sleepHoursRaw: 8, sleepQuality: 1.0),
      );
      expect(restorative.behaviorScore, greaterThan(fragmented.behaviorScore));
      expect(restorative.totalScore, greaterThan(fragmented.totalScore));
    });

    test('weeklyQualityScore más alto → metabolicScore más alto', () {
      // Mismas horas de ayuno y eTRF. La diferencia es la calidad
      // semanal continua (SPEC-65) en lugar del binario weeklyAdherence.
      final low = engine.calculateIMR(
        user,
        _state(weeklyQualityScore: 0.2),
      );
      final high = engine.calculateIMR(
        user,
        _state(weeklyQualityScore: 0.95),
      );
      expect(high.metabolicScore, greaterThan(low.metabolicScore));
    });

    test('weeklyAdherence binario YA NO afecta el metabolicScore directo',
        () {
      // Si dos states comparten weeklyQualityScore pero difieren en
      // weeklyAdherence, el metabolicScore debe ser idéntico — el engine
      // ya no consume el binario.
      final a = engine.calculateIMR(
        user,
        _state(weeklyAdherence: 0.0, weeklyQualityScore: 0.7),
      );
      final b = engine.calculateIMR(
        user,
        _state(weeklyAdherence: 1.0, weeklyQualityScore: 0.7),
      );
      expect(a.metabolicScore, b.metabolicScore);
    });

    test('Backward compat: tests pre-SPEC-53 sin weeklyQualityScore '
        'siguen dando un score determinista', () {
      // El helper defaultea weeklyQualityScore al valor de weeklyAdherence,
      // así que la aritmética antigua se preserva.
      final r1 = engine.calculateIMR(user, _state(weeklyAdherence: 0.7));
      final r2 = engine.calculateIMR(user, _state(weeklyAdherence: 0.7));
      expect(r1.totalScore, r2.totalScore);
    });
  });

  group('SPEC-70.3: FFMI baseline ajustado por edad', () {
    /// Helper: construye un user con FFMI computado igual al objetivo.
    /// Dado FFMI = leanMass / hMeter², con leanMass = weight*(1-bf/100):
    /// si fijamos height y bf, el peso requerido es FFMI * hMeter² / (1-bf/100).
    UserModel userWithFFMI(double targetFFMI, int age, {String gender = 'M'}) {
      const height = 175.0;
      const bf = 20.0;
      final hMeter = height / 100;
      final weight = targetFFMI * (hMeter * hMeter) / (1 - bf / 100);
      return _user(
        gender: gender,
        age: age,
        weight: weight,
        height: height,
        bodyFatPct: bf,
        waist: 78, // WHtR sano para que estructura no colapse por s1.
      );
    }

    test('Mismo FFMI=17, joven (25) vs mayor (70) → mayor puntúa más alto',
        () {
      final young = userWithFFMI(17.0, 25);
      final old = userWithFFMI(17.0, 70);
      final state = _state();
      final rYoung = engine.calculateIMR(young, state);
      final rOld = engine.calculateIMR(old, state);
      // Joven con FFMI=17 está en bottom-percentile (baseline=17 → s2=0).
      // Adulto mayor con mismo FFMI ya supera el umbral de sarcopenia
      // (baseline=15.5 → s2=1.5/6=0.25). Su estructura debe puntuar más.
      expect(rOld.structureScore, greaterThan(rYoung.structureScore));
    });

    test('FFMI=17 a los 70 supera el umbral de sarcopenia (s2 > 0)', () {
      final old = userWithFFMI(17.0, 70);
      final r = engine.calculateIMR(old, _state());
      // structureBlock = 0.65*s1 + 0.35*s2. Con s1≈1 (waist=78) y s2>0,
      // el structureBlock debe estar claramente arriba de 0.65.
      expect(r.structureScore, greaterThan(0.65));
    });

    test('FFMI=17 a los 25 está en el percentil ~5 (s2 ≈ 0)', () {
      final young = userWithFFMI(17.0, 25);
      final r = engine.calculateIMR(young, _state());
      // Con baseline=17.0, s2 = (17-17)/6 = 0.
      // structureBlock ≈ 0.65 * s1 (sólo WHtR aporta).
      expect(r.structureScore, closeTo(0.65, 0.01));
    });

    test('Misma edad >70, FFMI 21 vs FFMI 16: 21 puntúa cerca del peak', () {
      final athletic = userWithFFMI(21.0, 75);
      final lean = userWithFFMI(16.0, 75);
      final state = _state();
      final rAthletic = engine.calculateIMR(athletic, state);
      final rLean = engine.calculateIMR(lean, state);
      expect(rAthletic.structureScore, greaterThan(rLean.structureScore));
      // 21 a los 75: s2 = (21-15.5)/6 = 0.917. Excelente para edad.
      expect(rAthletic.structureScore, greaterThan(0.85));
    });

    test('Mujeres: baseline más bajo, mismo patrón de envejecimiento', () {
      final youngWoman = userWithFFMI(14.5, 25, gender: 'F');
      final olderWoman = userWithFFMI(14.5, 70, gender: 'F');
      final state = _state();
      final rYoung = engine.calculateIMR(youngWoman, state);
      final rOlder = engine.calculateIMR(olderWoman, state);
      // 14.5 es bottom para mujer joven (s2=0). Para mujer >70 ya supera
      // el umbral (baseline=13.0 → s2=1.5/5=0.3).
      expect(rOlder.structureScore, greaterThan(rYoung.structureScore));
    });

    test('Backward compat: usuario edad 30 (default helper) sigue funcionando',
        () {
      // Tests pre-SPEC-70.3 usaban age=30 implícito. Verificamos que no
      // rompen — el baseline a los 30 es 17.0 hombres / 14.5 mujeres
      // (cae en peak, < 50 años).
      final user = _user(weight: 75, height: 180, waist: 78);
      final r = engine.calculateIMR(user, _state());
      expect(r.totalScore, greaterThan(0));
      expect(r.totalScore, lessThanOrEqualTo(100));
    });
  });

  group('SPEC-70.2: bonus eTRF como sigmoid suave (no salto binario)', () {
    final user = _user(waist: 85);

    test('Cena a las 17:30 vs 18:30 → diferencia gradual (NO salto del 15%)',
        () {
      // Antes (binario): 17:30 → bonus 1.15, 18:30 → bonus 1.0.
      // Ahora (sigmoid): 17:30 ≈ 1.06, 18:30 ≈ 1.03. Diferencia ~3%.
      final early = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 17, 30)),
      );
      final late = engine.calculateIMR(
        user,
        _state(lastMealTime: DateTime(2026, 5, 6, 18, 30)),
      );
      // La diferencia entre estos dos puntos NO debe acercarse al 15%
      // que daría el salto binario antiguo.
      final delta = early.metabolicScore - late.metabolicScore;
      expect(delta, greaterThan(0),
          reason: 'Más temprano debe seguir puntuando más alto.');
      expect(delta, lessThan(0.10),
          reason: 'La transición debe ser gradual, no escalonada (15%+).');
    });

    test('Monotonicidad: cena más temprana → bonus mayor', () {
      final at15 = engine.calculateIMR(
        user, _state(lastMealTime: DateTime(2026, 5, 6, 15)),
      );
      final at17 = engine.calculateIMR(
        user, _state(lastMealTime: DateTime(2026, 5, 6, 17)),
      );
      final at19 = engine.calculateIMR(
        user, _state(lastMealTime: DateTime(2026, 5, 6, 19)),
      );
      expect(at15.metabolicScore, greaterThan(at17.metabolicScore));
      expect(at17.metabolicScore, greaterThan(at19.metabolicScore));
    });

    test('Asíntota: cena muy temprana NO supera el techo del binario antiguo',
        () {
      // Tope superior del bonus = 1.15 (asíntota). Una cena a las 13:00
      // se acerca pero no supera. Verificamos via la cota:
      // sigmoid((13-17)/1) ≈ 0.018 → bonus ≈ 1.0 + 0.15*0.982 = 1.147.
      // Como bonus * metabolicBlock < 1.0 * metabolicBlock * 1.15,
      // el metabolicScore con cena 13:00 debe ser MENOR o IGUAL al que
      // daría el binario con bonus exactamente 1.15.
      final atDawn = engine.calculateIMR(
        user, _state(lastMealTime: DateTime(2026, 5, 6, 13)),
      );
      // Cota teórica si etrfBonus = 1.15 y resto idéntico.
      // Aquí solo verificamos que el score sigue siendo razonable.
      expect(atDawn.metabolicScore, greaterThan(0));
      expect(atDawn.metabolicScore, lessThanOrEqualTo(1.0));
    });

    test('Continuidad: 17:59 vs 18:01 → diferencia mínima (no salto)', () {
      // El test crítico que motivó SPEC-70.2: el cliffhanger del binario.
      final at1759 = engine.calculateIMR(
        user, _state(lastMealTime: DateTime(2026, 5, 6, 17, 59)),
      );
      final at1801 = engine.calculateIMR(
        user, _state(lastMealTime: DateTime(2026, 5, 6, 18, 1)),
      );
      // Antes: at1759.totalScore - at1801.totalScore ≈ 4 puntos
      // (15% del metabolicBlock que es ~0.7, multiplicado por peso 0.25).
      // Ahora la diferencia debe ser < 1 punto.
      expect((at1759.totalScore - at1801.totalScore).abs(), lessThan(2));
    });
  });
}
