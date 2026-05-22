// Tests de NervousSystem y NervousSystemScore — SPEC-137.
//
// Cubre la mecánica de scoring de §RF-137-08.B y el contrato de la
// sugerencia con MealRatio (§RF-137-09).

import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nervous_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NervousSystem.values', () {
    test('expone exactamente passive, excited, unknown', () {
      expect(NervousSystem.values, hasLength(3));
      expect(NervousSystem.values, containsAll([
        NervousSystem.passive,
        NervousSystem.excited,
        NervousSystem.unknown,
      ]));
    });
  });

  group('suggestedRatio (RF-137-09)', () {
    test('passive → a2e1 (2x1)', () {
      expect(NervousSystem.passive.suggestedRatio, MealRatio.a2e1);
    });

    test('excited → a3e1 (3x1)', () {
      expect(NervousSystem.excited.suggestedRatio, MealRatio.a3e1);
    });

    test('unknown → a2e1 (default seguro, mismo que passive)', () {
      expect(NervousSystem.unknown.suggestedRatio, MealRatio.a2e1);
    });
  });

  group('label', () {
    test('retorna etiquetas LatAm canónicas', () {
      expect(NervousSystem.passive.label, 'Pasivo');
      expect(NervousSystem.excited.label, 'Excitado');
      expect(NervousSystem.unknown.label, 'Por conocer');
    });
  });

  group('persistenceKey ↔ fromPersistenceKey', () {
    test('cada NervousSystem round-trippea', () {
      for (final ns in NervousSystem.values) {
        final key = ns.persistenceKey;
        expect(
          NervousSystem.fromPersistenceKey(key),
          ns,
          reason: 'round-trip falla para $ns (key="$key")',
        );
      }
    });

    test('null cae a unknown', () {
      expect(NervousSystem.fromPersistenceKey(null), NervousSystem.unknown);
    });

    test('clave desconocida cae a unknown', () {
      expect(NervousSystem.fromPersistenceKey('foo'), NervousSystem.unknown);
      expect(NervousSystem.fromPersistenceKey('PASSIVE'), NervousSystem.unknown);
    });
  });

  group('NervousSystemAnswer.classifies', () {
    test('classifiesAsPassive devuelve passive', () {
      expect(
        NervousSystemAnswer.classifiesAsPassive.classifies,
        NervousSystem.passive,
      );
    });

    test('classifiesAsExcited devuelve excited', () {
      expect(
        NervousSystemAnswer.classifiesAsExcited.classifies,
        NervousSystem.excited,
      );
    });

    test('unknown NO clasifica (null)', () {
      expect(NervousSystemAnswer.unknown.classifies, isNull);
    });
  });

  group('NervousSystemScore.fromAnswers', () {
    test('cuenta correctamente respuestas mixtas', () {
      final score = NervousSystemScore.fromAnswers([
        NervousSystemAnswer.classifiesAsPassive,
        NervousSystemAnswer.classifiesAsPassive,
        NervousSystemAnswer.classifiesAsExcited,
        NervousSystemAnswer.unknown,
        NervousSystemAnswer.classifiesAsPassive,
      ]);
      expect(score.passive, 3);
      expect(score.excited, 1);
      expect(score.unknown, 1);
      expect(score.totalAnswered, 5);
    });

    test('lista vacía produce todos en 0', () {
      final score = NervousSystemScore.fromAnswers([]);
      expect(score.passive, 0);
      expect(score.excited, 0);
      expect(score.unknown, 0);
      expect(score.totalAnswered, 0);
    });

    test('lista de 5 unknowns produce 5/0/0', () {
      final score = NervousSystemScore.fromAnswers(
        List.filled(5, NervousSystemAnswer.unknown),
      );
      expect(score.passive, 0);
      expect(score.excited, 0);
      expect(score.unknown, 5);
    });
  });

  group('NervousSystemScore.classify (RF-137-08.B)', () {
    test('si unknown ≥ 3 → unknown (regla 1, tiene prioridad)', () {
      const s = NervousSystemScore(passive: 1, excited: 1, unknown: 3);
      expect(s.classify(), NervousSystem.unknown);
    });

    test('si unknown ≥ 3 incluso con excited alto → unknown', () {
      const s = NervousSystemScore(passive: 0, excited: 2, unknown: 3);
      expect(s.classify(), NervousSystem.unknown);
    });

    test('si excited ≥ 3 (y unknown < 3) → excited', () {
      const s = NervousSystemScore(passive: 2, excited: 3, unknown: 0);
      expect(s.classify(), NervousSystem.excited);
    });

    test('excited = 5 puro → excited', () {
      const s = NervousSystemScore(passive: 0, excited: 5, unknown: 0);
      expect(s.classify(), NervousSystem.excited);
    });

    test('passive ≥ 3 → passive', () {
      const s = NervousSystemScore(passive: 3, excited: 2, unknown: 0);
      expect(s.classify(), NervousSystem.passive);
    });

    test('passive = 5 puro → passive', () {
      const s = NervousSystemScore(passive: 5, excited: 0, unknown: 0);
      expect(s.classify(), NervousSystem.passive);
    });

    test('empate 2-2-1 → passive (default seguro)', () {
      const s = NervousSystemScore(passive: 2, excited: 2, unknown: 1);
      expect(s.classify(), NervousSystem.passive);
    });

    test('empate 2-2-0 (no completó las 5) → passive', () {
      const s = NervousSystemScore(passive: 2, excited: 2, unknown: 0);
      expect(s.classify(), NervousSystem.passive);
    });

    test('todo cero → passive (default seguro absoluto)', () {
      const s = NervousSystemScore(passive: 0, excited: 0, unknown: 0);
      expect(s.classify(), NervousSystem.passive);
    });

    test('caso límite: excited=3 vs unknown=3 simultáneo (no debería ocurrir '
        'con 5 preguntas, pero por defensa: unknown gana)', () {
      const s = NervousSystemScore(passive: 0, excited: 3, unknown: 3);
      expect(s.classify(), NervousSystem.unknown);
    });
  });

  group('NervousSystemScore round-trip Firestore', () {
    test('toMap / fromMap preservan los tres campos', () {
      const original = NervousSystemScore(passive: 3, excited: 1, unknown: 1);
      final map = original.toMap();
      expect(map, {'passive': 3, 'excited': 1, 'unknown': 1});
      final parsed = NervousSystemScore.fromMap(map);
      expect(parsed, original);
    });

    test('fromMap(null) produce score vacío', () {
      final score = NervousSystemScore.fromMap(null);
      expect(score.passive, 0);
      expect(score.excited, 0);
      expect(score.unknown, 0);
    });

    test('fromMap con campos faltantes los asume 0', () {
      final score = NervousSystemScore.fromMap({'passive': 2});
      expect(score.passive, 2);
      expect(score.excited, 0);
      expect(score.unknown, 0);
    });

    test('fromMap acepta int, double y string parseable', () {
      final score = NervousSystemScore.fromMap({
        'passive': 2,
        'excited': 1.0,
        'unknown': '2',
      });
      expect(score.passive, 2);
      expect(score.excited, 1);
      expect(score.unknown, 2);
    });
  });

  group('NervousSystemScore equality', () {
    test('mismo contenido es igual', () {
      const a = NervousSystemScore(passive: 3, excited: 1, unknown: 1);
      const b = NervousSystemScore(passive: 3, excited: 1, unknown: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('contenido distinto no es igual', () {
      const a = NervousSystemScore(passive: 3, excited: 1, unknown: 1);
      const b = NervousSystemScore(passive: 2, excited: 1, unknown: 1);
      expect(a, isNot(b));
    });
  });
}
