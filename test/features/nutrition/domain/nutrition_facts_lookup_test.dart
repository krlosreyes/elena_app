// Tests del NutritionFactsLookup — SPEC-64.

import 'package:elena_app/src/features/nutrition/domain/nutrition_facts_lookup.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NutritionFactsLookup.findByName', () {
    test('encuentra por nombre exacto (case-insensitive)', () {
      final entry = NutritionFactsLookup.findByName('Avena');
      expect(entry, isNotNull);
      expect(entry!.name, 'Avena');
      expect(entry.calories, 150);
      expect(entry.glycemicIndex, 55);
    });

    test('encuentra por alias', () {
      final entry = NutritionFactsLookup.findByName('platano');
      expect(entry, isNotNull);
      expect(entry!.name, 'Plátano');
    });

    test('encuentra "huevo" → entrada Huevo entero', () {
      final entry = NutritionFactsLookup.findByName('huevo');
      expect(entry, isNotNull);
      expect(entry!.name, 'Huevo entero');
      expect(entry.protein, 6.3);
    });

    test('retorna null si no hay match', () {
      expect(NutritionFactsLookup.findByName('zzzunknown'), isNull);
    });

    test('retorna null para query vacía', () {
      expect(NutritionFactsLookup.findByName(''), isNull);
      expect(NutritionFactsLookup.findByName('   '), isNull);
    });
  });

  group('NutritionFactsLookup.search', () {
    test('match parcial en nombre', () {
      final results = NutritionFactsLookup.search('arroz');
      expect(results.length, greaterThanOrEqualTo(2));
      // Debería incluir "Arroz integral" y "Arroz blanco".
      final names = results.map((e) => e.name).toSet();
      expect(names.contains('Arroz integral'), isTrue);
      expect(names.contains('Arroz blanco'), isTrue);
    });

    test('match parcial en alias', () {
      final results = NutritionFactsLookup.search('porotos');
      expect(results, isNotEmpty);
      expect(results.first.name, 'Frijoles negros');
    });

    test('lista vacía si nada matchea', () {
      expect(NutritionFactsLookup.search('xxxno_match'), isEmpty);
    });

    test('lista vacía para query vacía', () {
      expect(NutritionFactsLookup.search(''), isEmpty);
    });
  });

  group('NutritionFactsLookup.applyToLog', () {
    test('aplica macros del catálogo y marca source como catalog', () {
      final log = NutritionLog(
        id: 'l-1',
        timestamp: DateTime(2026, 5, 1, 8),
        label: 'Desayuno',
        withinCircadianWindow: true,
      );
      final entry = NutritionFactsLookup.findByName('avena')!;
      final patched = NutritionFactsLookup.applyToLog(log, entry);

      expect(patched.calories, 150);
      expect(patched.protein, 5.0);
      expect(patched.carbs, 27.0);
      expect(patched.fat, 2.5);
      expect(patched.fiber, 4.0);
      expect(patched.glycemicIndex, 55);
      expect(patched.source, NutritionLogSource.catalog);

      // Campos no nutricionales se preservan.
      expect(patched.id, log.id);
      expect(patched.timestamp, log.timestamp);
      expect(patched.label, log.label);
    });
  });

  group('Integridad del catálogo', () {
    test('todas las entradas tienen valores no negativos', () {
      for (final e in NutritionFactsLookup.all) {
        expect(e.calories, greaterThanOrEqualTo(0),
            reason: '${e.name} calories');
        expect(e.protein, greaterThanOrEqualTo(0), reason: '${e.name} protein');
        expect(e.carbs, greaterThanOrEqualTo(0), reason: '${e.name} carbs');
        expect(e.fat, greaterThanOrEqualTo(0), reason: '${e.name} fat');
        if (e.fiber != null) {
          expect(e.fiber, greaterThanOrEqualTo(0), reason: '${e.name} fiber');
        }
        if (e.glycemicIndex != null) {
          expect(e.glycemicIndex! >= 0 && e.glycemicIndex! <= 100, isTrue,
              reason: '${e.name} glycemicIndex fuera de 0-100');
        }
      }
    });

    test('todas las entradas tienen aliases en lowercase', () {
      for (final e in NutritionFactsLookup.all) {
        for (final a in e.aliases) {
          expect(a, a.toLowerCase(),
              reason: 'Alias "$a" de ${e.name} no está en lowercase');
        }
      }
    });

    test('catálogo contiene al menos 20 alimentos', () {
      expect(NutritionFactsLookup.all.length, greaterThanOrEqualTo(20));
    });
  });
}
