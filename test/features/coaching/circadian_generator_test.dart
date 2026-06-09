// SPEC-194 Adenda circadiana — tests del CircadianGenerator:
// override del bloqueo intestinal (§5), menú fase→acción (§4) y
// circadianImpact alineado a las constantes del spec (§3/§8).

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/coaching/application/circadian_generator.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/scoring/scoring_weights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CoachingAction? byId(List<CoachingAction> xs, String id) {
    for (final a in xs) {
      if (a.id == id) return a;
    }
    return null;
  }

  group('Override del bloqueo intestinal (§5)', () {
    test('dentro de la ventana (≤60 min) genera "cierra tu cocina"', () {
      final out = CircadianGenerator.generate(
        CircadianPhase.creatividad,
        minutesToIntestinalLock: 45,
      );
      final close = byId(out, 'circadian_close_kitchen');
      expect(close, isNotNull);
      expect(close!.circadianImpact, kCircProtectBoundary);
      expect(close.minutesToDeadline, 45);
    });

    test('en el límite exacto (60 min) todavía dispara', () {
      final out = CircadianGenerator.generate(
        CircadianPhase.creatividad,
        minutesToIntestinalLock: CircadianGenerator.kLockOverrideMin,
      );
      expect(byId(out, 'circadian_close_kitchen'), isNotNull);
    });

    test('fuera de la ventana (>60 min) NO dispara el override', () {
      final out = CircadianGenerator.generate(
        CircadianPhase.creatividad,
        minutesToIntestinalLock: 90,
      );
      expect(byId(out, 'circadian_close_kitchen'), isNull);
    });

    test('lock ya pasado (negativo) o null NO dispara', () {
      expect(
        byId(
          CircadianGenerator.generate(CircadianPhase.creatividad,
              minutesToIntestinalLock: -5),
          'circadian_close_kitchen',
        ),
        isNull,
      );
      expect(
        byId(
          CircadianGenerator.generate(CircadianPhase.creatividad),
          'circadian_close_kitchen',
        ),
        isNull,
      );
    });
  });

  group('Menú fase→acción (§4) + circadianImpact (§3/§8)', () {
    test('ALERTA → hidratar al despertar (neutral 0.30)', () {
      final a = byId(
          CircadianGenerator.generate(CircadianPhase.alerta),
          'circadian_morning_hydrate');
      expect(a, isNotNull);
      expect(a!.circadianImpact, kCircNeutral);
    });

    test('RECESO → comida principal temprana (bonus 0.85)', () {
      final a = byId(
          CircadianGenerator.generate(CircadianPhase.receso),
          'circadian_main_meal_early');
      expect(a, isNotNull);
      expect(a!.circadianImpact, kCircEarlyMealBonus);
    });

    test('MOTOR/FUERZA → entrenar (actividad en fase 0.75)', () {
      final a = byId(
          CircadianGenerator.generate(CircadianPhase.motorFuerza),
          'circadian_train_peak');
      expect(a, isNotNull);
      expect(a!.circadianImpact, kCircPhaseAlignedActivity);
    });

    test('CREATIVIDAD → bajar el ritmo (proteger sueño 0.80)', () {
      // Sin override (lock lejos) para aislar la acción de fase.
      final a = byId(
          CircadianGenerator.generate(CircadianPhase.creatividad,
              minutesToIntestinalLock: 200),
          'circadian_winddown');
      expect(a, isNotNull);
      expect(a!.circadianImpact, kCircProtectSleep);
    });

    test('SUEÑO y COGNITIVO no generan acción de fase', () {
      expect(CircadianGenerator.generate(CircadianPhase.sueno), isEmpty);
      expect(CircadianGenerator.generate(CircadianPhase.cognitivo), isEmpty);
    });
  });

  test('todos los circadianImpact quedan en [0,1]', () {
    for (final phase in CircadianPhase.values) {
      for (final a in CircadianGenerator.generate(phase,
          minutesToIntestinalLock: 30)) {
        expect(a.circadianImpact, inInclusiveRange(0.0, 1.0),
            reason: '${a.id} fuera de rango');
      }
    }
  });
}
