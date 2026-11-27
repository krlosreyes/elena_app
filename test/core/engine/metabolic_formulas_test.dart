// SPEC-306: Elena y el sitio prueban contra el mismo archivo de casos.
// Si este test falla, la app y metamorfosisvital.com.co ya no calculan lo
// mismo: corrige la fórmula en ambos repos o actualiza el archivo en los dos.

import 'dart:convert';
import 'dart:io';

import 'package:elena_app/src/core/engine/metabolic_formulas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, dynamic> fixtures = jsonDecode(
    File('test/fixtures/metabolic_cases.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('misma versión de motor que el sitio', () {
    expect(fixtures['engineVersion'], kMetabolicEngineVersion);
  });

  for (final c in (fixtures['cases'] as List).cast<Map<String, dynamic>>()) {
    test('caso compartido: ${c['name']}', () {
      final i = c['input'] as Map<String, dynamic>;
      final e = c['expected'] as Map<String, dynamic>;
      final bool isMale = i['gender'] == 'male';
      final double h = (i['heightCm'] as num).toDouble();
      final double w = (i['weightKg'] as num).toDouble();
      final double waist = (i['waistCm'] as num).toDouble();
      final double neck = (i['neckCm'] as num).toDouble();
      final double? hip = (i['hipCm'] as num?)?.toDouble();
      final int age = i['age'] as int;

      final double? bf = MetabolicFormulas.bodyFatNavy(
        heightCm: h,
        waistCm: waist,
        neckCm: neck,
        hipCm: hip,
        isMale: isMale,
      );
      expect(
        MetabolicFormulas.bmrMifflin(
            weightKg: w, heightCm: h, age: age, isMale: isMale),
        closeTo((e['bmrMifflin'] as num).toDouble(), 0.05),
      );
      expect(MetabolicFormulas.whtrCategory(waist / h).name, e['whtrCategory']);
      if (e['bodyFatPct'] == null) {
        expect(bf, isNull);
        return;
      }
      expect(bf, isNotNull);
      expect(bf!, closeTo((e['bodyFatPct'] as num).toDouble(), 0.05));
      expect(
        MetabolicFormulas.metabolicAge(
          age: age,
          weightKg: w,
          heightCm: h,
          bodyFatPct: bf,
          isMale: isMale,
        ),
        e['metabolicAge'],
      );
      expect(MetabolicFormulas.fatCategory(bf, isMale).name, e['fatCategory']);
    });
  }

  group('casos límite', () {
    test('cintura menor o igual al cuello en hombres: sin cálculo', () {
      expect(
        MetabolicFormulas.bodyFatNavy(
            heightCm: 175, waistCm: 38, neckCm: 40, isMale: true),
        isNull,
      );
    });
    test('medidas en cero: sin cálculo', () {
      expect(
        MetabolicFormulas.bodyFatNavy(
            heightCm: 0, waistCm: 80, neckCm: 33, isMale: false),
        isNull,
      );
    });
    test('mujer sin cadera: no se calcula ni se inventa', () {
      expect(MetabolicFormulas.needsHip(isMale: false), isTrue);
      expect(MetabolicFormulas.needsHip(isMale: false, hipCm: 100), isFalse);
      expect(MetabolicFormulas.needsHip(isMale: true), isFalse);
      expect(
        MetabolicFormulas.bodyFatNavy(
            heightCm: 170, waistCm: 60, neckCm: 32, isMale: false),
        isNull,
      );
    });
    test('edad metabólica limitada a 18–80', () {
      expect(
        MetabolicFormulas.metabolicAge(
            age: 20, weightKg: 55, heightCm: 180, bodyFatPct: 5, isMale: true),
        18,
      );
    });
  });
}
