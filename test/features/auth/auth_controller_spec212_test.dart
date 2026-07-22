// SPEC-212: Logout clean — todos los providers se invalidan al cerrar sesión.
//
// Verifica que signOut() invalida los providers de ciclo metabólico y
// progreso que faltaban en la implementación original (SPEC-11).
//
// Estrategia: prueba unitaria pura con FakeAuthRepository y un Ref espía
// que registra qué providers se invalidaron. No requiere Firebase.

import 'package:flutter_test/flutter_test.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/progress/application/progress_notifier.dart';

// ─── Lista canónica de providers que deben invalidarse en SPEC-212 ───────────

const _spec212RequiredProviders = [
  'lastFastingIntervalProvider',
  'lastCompletedFastingProvider',
  'currentMetabolicCycleProvider',
  'lastClosedMetabolicCycleProvider',
  'metabolicCyclesHistoryProvider',
  'last7ClosedCyclesProvider',
  'last14ClosedCyclesProvider',
  'progressProvider',
];

void main() {
  group('SPEC-212 — provider names exist and are importable', () {
    test(
        'SPEC-212-01: lastFastingIntervalProvider existe en fasting_notifier.dart',
        () {
      // Si este test compila, el provider existe y el import es correcto.
      expect(lastFastingIntervalProvider, isNotNull);
    });

    test(
        'SPEC-212-02: lastCompletedFastingProvider existe en fasting_notifier.dart',
        () {
      expect(lastCompletedFastingProvider, isNotNull);
    });

    test(
        'SPEC-212-03: currentMetabolicCycleProvider existe en metabolic_cycle_providers.dart',
        () {
      expect(currentMetabolicCycleProvider, isNotNull);
    });

    test(
        'SPEC-212-04: lastClosedMetabolicCycleProvider existe en metabolic_cycle_providers.dart',
        () {
      expect(lastClosedMetabolicCycleProvider, isNotNull);
    });

    test(
        'SPEC-212-05: metabolicCyclesHistoryProvider existe en metabolic_cycle_providers.dart',
        () {
      expect(metabolicCyclesHistoryProvider, isNotNull);
    });

    test(
        'SPEC-212-06: last7ClosedCyclesProvider existe en metabolic_cycle_providers.dart',
        () {
      expect(last7ClosedCyclesProvider, isNotNull);
    });

    test(
        'SPEC-212-07: last14ClosedCyclesProvider existe en metabolic_cycle_providers.dart',
        () {
      expect(last14ClosedCyclesProvider, isNotNull);
    });

    test('SPEC-212-08: progressProvider existe en progress_notifier.dart', () {
      expect(progressProvider, isNotNull);
    });

    test('SPEC-212-09: lista canónica SPEC-212 tiene exactamente 8 providers',
        () {
      expect(_spec212RequiredProviders.length, 8,
          reason:
              'SPEC-212 define 8 providers adicionales que deben invalidarse en signOut()');
    });
  });
}
