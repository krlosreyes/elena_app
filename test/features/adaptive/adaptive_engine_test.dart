// TEST-08 (auditoría pre-producción 2026-07-11).
//
// AdaptiveEngine (lib/src/features/adaptive/application/adaptive_engine.dart)
// no tenía ningún test. Cubre las dos funciones puras públicas:
// `isIMRStable` (estabilidad de IMR SPEC-08) y `evaluateProtocolAdjustment`
// (sugerencia de subir de nivel de protocolo de ayuno o de meta de
// ejercicio). No depende de Riverpod ni de widgets — son static methods
// Dart puros, testeables directamente.

import 'package:elena_app/src/features/adaptive/application/adaptive_engine.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Construye una StreakEntry mínima con el imrScore indicado; el resto de
/// campos booleanos/magnitudes no importan para isIMRStable ni para
/// evaluateProtocolAdjustment (que solo lee `imrScore` a través de
/// isIMRStable).
StreakEntry _entry(int imrScore, {String date = '2026-01-01'}) => StreakEntry(
      date: date,
      fastingCompleted: true,
      sleepCompleted: true,
      hydrationCompleted: true,
      exerciseLogged: true,
      nutritionLogged: true,
      imrScore: imrScore,
    );

List<StreakEntry> _history(List<int> imrScores) =>
    List.generate(imrScores.length, (i) => _entry(imrScores[i], date: '2026-01-${i + 1}'));

/// Usuario adulto sin patologías declaradas — el caso "sin restricción
/// de Eje A" (tope 22:2). Suficiente para los tests de
/// `evaluateProtocolAdjustment` que no ejercitan `eligibility`.
UserModel _user({int age = 30, List<String> pathologies = const ['Ninguna']}) =>
    UserModel(
      age: age,
      gender: 'F',
      weight: 65,
      height: 165,
      pathologies: pathologies,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 7),
        sleepTime: DateTime(2026, 1, 1, 23),
      ),
    );

void main() {
  group('AdaptiveEngine.isIMRStable', () {
    test('menos de 7 días de historial → no estable', () {
      final history = _history([90, 90, 90, 90, 90, 90]); // 6 días
      expect(AdaptiveEngine.isIMRStable(history), false);
    });

    test('7 días, 6 con IMR >= 75 → estable', () {
      final history = _history([90, 90, 90, 90, 90, 90, 60]);
      expect(AdaptiveEngine.isIMRStable(history), true);
    });

    test('7 días, solo 5 con IMR >= 75 → no estable', () {
      final history = _history([90, 90, 90, 90, 90, 60, 60]);
      expect(AdaptiveEngine.isIMRStable(history), false);
    });

    test('7 días, todos exactamente en el umbral 75 → estable', () {
      final history = _history(List.filled(7, 75));
      expect(AdaptiveEngine.isIMRStable(history), true);
    });
  });

  group('AdaptiveEngine.evaluateProtocolAdjustment', () {
    final stableHistory = _history([90, 90, 90, 90, 90, 90, 90]);

    test('engagement neutro → nunca sugiere, aunque el IMR sea estable', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.neutro,
        history: stableHistory,
        currentProtocol: '12:12',
        currentExerciseGoal: 20,
      );
      expect(result, isNull);
    });

    test('engagement excelente + IMR estable + protocolo intermedio → level up de protocolo', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.excelente,
        history: stableHistory,
        currentProtocol: '12:12',
        currentExerciseGoal: 20,
      );

      expect(result, isNotNull);
      expect(result!.type, SuggestionType.levelUp);
      expect(result.newProtocol, '14:10');
      expect(result.newExerciseGoal, isNull);
    });

    // SPEC-257 RF-257-B1: la escalera de auto-progresión ahora llega
    // hasta 20:4 (antes tope en 16:8) — 22:2/OMAD quedan reservados a
    // elección consciente del usuario (Eje A). Estos dos tests usaban
    // '16:8' como "ya en el tope"; se actualizan a '20:4', el tope
    // real de la escalera automática.
    test('engagement excelente + protocolo ya en el tope (20:4) + meta de ejercicio baja → sugiere subir ejercicio', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.excelente,
        history: stableHistory,
        currentProtocol: '20:4',
        currentExerciseGoal: 30,
      );

      expect(result, isNotNull);
      expect(result!.type, SuggestionType.levelUp);
      expect(result.newProtocol, isNull);
      expect(result.newExerciseGoal, 40);
    });

    test('engagement excelente + protocolo tope + meta de ejercicio ya alta (>=45) → sin sugerencia', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.excelente,
        history: stableHistory,
        currentProtocol: '20:4',
        currentExerciseGoal: 45,
      );
      expect(result, isNull);
    });

    test('escalera extendida: 16:8 sube a 18:6 (antes era el tope)', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.excelente,
        history: stableHistory,
        currentProtocol: '16:8',
        currentExerciseGoal: 20,
      );
      expect(result, isNotNull);
      expect(result!.type, SuggestionType.levelUp);
      expect(result.newProtocol, '18:6');
    });

    // ── SPEC-257 Eje A: la elegibilidad médica manda sobre la adherencia ──

    test('eligibility con tope por debajo del siguiente nivel → sin sugerencia aunque el comportamiento sea perfecto', () {
      // IMC < 20 (bajo peso moderado) → tope 20:4 (FastingEligibility).
      final eligibility = FastingEligibility.assess(
        _user().copyWith(weight: 50, height: 165), // IMC ≈ 18.4 → bloqueado
      );
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.excelente,
        history: stableHistory,
        currentProtocol: '12:12',
        currentExerciseGoal: 20,
        eligibility: eligibility,
      );
      // IMC 18.4 < 18.5 → FastingEligibility bloquea del todo ('Ninguno').
      // 12:12 ya está por encima del tope permitido, así que ninguna
      // subida es válida.
      expect(result, isNull);
    });

    test('eligibility permite el siguiente nivel → sugerencia normal', () {
      final eligibility = FastingEligibility.assess(_user()); // sin restricción, tope 22:2
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.excelente,
        history: stableHistory,
        currentProtocol: '12:12',
        currentExerciseGoal: 20,
        eligibility: eligibility,
      );
      expect(result, isNotNull);
      expect(result!.newProtocol, '14:10');
    });

    // ── SPEC-257 Eje B "simplify" ──────────────────────────────────────

    test('engagement crítico → sugiere bajar un nivel (simplify)', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.critico,
        history: const [],
        currentProtocol: '16:8',
        currentExerciseGoal: 20,
      );
      expect(result, isNotNull);
      expect(result!.type, SuggestionType.simplify);
      expect(result.newProtocol, '14:10');
    });

    test('engagement crítico en el piso (Ninguno) → sin sugerencia, no hay a dónde bajar', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.critico,
        history: const [],
        currentProtocol: 'Ninguno',
        currentExerciseGoal: 20,
      );
      expect(result, isNull);
    });

    test('protocolo elegido a mano fuera de la escalera automática (22:2) + crítico → baja al tope automático (20:4)', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.critico,
        history: const [],
        currentProtocol: '22:2',
        currentExerciseGoal: 20,
      );
      expect(result, isNotNull);
      expect(result!.type, SuggestionType.simplify);
      expect(result.newProtocol, '20:4');
    });

    test('hipoglucemia reportada → simplify inmediato aunque el engagement sea neutro', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.neutro,
        history: const [],
        currentProtocol: '16:8',
        currentExerciseGoal: 20,
        hypoglycemiaReported: true,
      );
      expect(result, isNotNull);
      expect(result!.type, SuggestionType.simplify);
      expect(result.newProtocol, '14:10');
    });

    test('engagement bueno (no excelente) → sin sugerencia aunque el IMR sea estable', () {
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.bueno,
        history: stableHistory,
        currentProtocol: '12:12',
        currentExerciseGoal: 20,
      );
      expect(result, isNull);
    });

    test('engagement excelente pero IMR no estable → sin sugerencia', () {
      final unstableHistory = _history([90, 90, 60, 60, 60, 60, 60]);
      final result = AdaptiveEngine.evaluateProtocolAdjustment(
        engagement: EngagementLevel.excelente,
        history: unstableHistory,
        currentProtocol: '12:12',
        currentExerciseGoal: 20,
      );
      expect(result, isNull);
    });
  });
}
