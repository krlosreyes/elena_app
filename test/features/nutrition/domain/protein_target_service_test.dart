// SPEC-270 — Tests del cálculo de peso ideal + objetivo proteico.
//
// Ancla los valores a los ejemplos textuales de El Milagro Metabólico
// (Jaramillo, cap. 10): mujer 1.60 m → ~55 kg ideal; hombre 1.85 m → ~80
// kg ideal y 80 g de proteína con actividad moderada. El libro dice "más
// o menos", así que se usan tolerancias, no igualdad exacta.

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/protein_target_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const svc = ProteinTargetService();

  group('ProteinTargetService — peso ideal (Devine)', () {
    test('hombre 1.85 m ≈ 80 kg (ejemplo del libro)', () {
      final w = svc.idealWeightKg(heightCm: 185, gender: 'M');
      expect(w, closeTo(79.5, 1.0));
    });

    test('mujer 1.60 m ≈ 55 kg (ejemplo del libro, aproximado)', () {
      final w = svc.idealWeightKg(heightCm: 160, gender: 'F');
      // Devine da 52.4; el libro dice "más o menos 55". Tolerancia amplia.
      expect(w, closeTo(52.4, 0.6));
      expect(w, greaterThan(48));
      expect(w, lessThan(58));
    });

    test('estatura bajo 5 pies no produce peso negativo (clamp a base)', () {
      final w = svc.idealWeightKg(heightCm: 150, gender: 'M');
      expect(w, 50.0); // base masculina, sin restar
    });

    test('género desconocido usa el promedio de ambas bases', () {
      final w = svc.idealWeightKg(heightCm: 152.4, gender: 'no-binario');
      expect(w, closeTo(47.75, 0.001)); // (50 + 45.5) / 2, exactamente en 5ft
    });

    test('sinónimos de género se toleran (hombre/mujer/male/female)', () {
      expect(svc.idealWeightKg(heightCm: 185, gender: 'hombre'),
          svc.idealWeightKg(heightCm: 185, gender: 'male'));
      expect(svc.idealWeightKg(heightCm: 160, gender: 'mujer'),
          svc.idealWeightKg(heightCm: 160, gender: 'female'));
    });
  });

  group('ProteinTargetService — factor de actividad (g/kg)', () {
    test('umbrales del PAL → nivel proteico', () {
      expect(svc.activityFromPal(1.2), ProteinActivity.sedentary);
      expect(svc.activityFromPal(1.39), ProteinActivity.sedentary);
      expect(svc.activityFromPal(1.4), ProteinActivity.moderate);
      expect(svc.activityFromPal(1.55), ProteinActivity.moderate);
      expect(svc.activityFromPal(1.6), ProteinActivity.moderate);
      expect(svc.activityFromPal(1.61), ProteinActivity.active);
      expect(svc.activityFromPal(1.9), ProteinActivity.active);
    });

    test('g/kg por nivel coincide con el método (0.8 / 1.0 / 1.5)', () {
      expect(ProteinActivity.sedentary.gramsPerKg, 0.8);
      expect(ProteinActivity.moderate.gramsPerKg, 1.0);
      expect(ProteinActivity.active.gramsPerKg, 1.5);
    });
  });

  group('ProteinTargetService — objetivo proteico diario', () {
    test('hombre 1.85 m, actividad moderada → ~80 g (ejemplo del libro)', () {
      final g = svc.targetProteinG(heightCm: 185, gender: 'M', pal: 1.5);
      expect(g, closeTo(79.5, 1.0));
      expect(
        svc.targetProteinGRounded(heightCm: 185, gender: 'M', pal: 1.5),
        anyOf(79, 80),
      );
    });

    test('mujer sedentaria pesa el objetivo por el factor 0.8', () {
      final ideal = svc.idealWeightKg(heightCm: 160, gender: 'F');
      final g = svc.targetProteinG(heightCm: 160, gender: 'F', pal: 1.2);
      expect(g, closeTo(ideal * 0.8, 0.001));
    });

    test('activo consume más proteína que sedentario para igual cuerpo', () {
      final act = svc.targetProteinG(heightCm: 175, gender: 'M', pal: 1.8);
      final sed = svc.targetProteinG(heightCm: 175, gender: 'M', pal: 1.1);
      expect(act, greaterThan(sed));
    });
  });

  group('ProteinTargetService — deriveTargets', () {
    test('empaqueta peso ideal, proteína y ventana en DerivedTargets', () {
      final d = svc.deriveTargets(
        heightCm: 185,
        gender: 'M',
        pal: 1.5,
        windowFirst: '07:30',
        windowLast: '19:30',
      );
      expect(d, isA<DerivedTargets>());
      expect(d.idealWeightKg, closeTo(79.5, 1.0));
      expect(d.targetProteinG, closeTo(79.5, 1.0));
      expect(d.windowFirst, '07:30');
      expect(d.windowLast, '19:30');
    });

    test('ventana vacía por defecto (sin circadiano)', () {
      final d = svc.deriveTargets(heightCm: 170, gender: 'F', pal: 1.2);
      expect(d.windowFirst, '');
      expect(d.windowLast, '');
    });
  });
}
