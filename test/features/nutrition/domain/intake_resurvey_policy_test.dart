// SPEC-275 — Tests de la política de re-encuesta del intake.

import 'package:elena_app/src/features/nutrition/domain/intake_resurvey_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = IntakeResurveyPolicy();
  final base = DateTime(2026, 8, 1);

  group('fase activa (4 semanas)', () {
    test('a los 27 días aún NO vence', () {
      expect(
        policy.isDue(updatedAt: base, now: base.add(const Duration(days: 27))),
        false,
      );
    });

    test('a los 28 días vence', () {
      expect(
        policy.isDue(updatedAt: base, now: base.add(const Duration(days: 28))),
        true,
      );
    });

    test('daysUntilDue cuenta hacia abajo', () {
      expect(
        policy.daysUntilDue(
            updatedAt: base, now: base.add(const Duration(days: 10))),
        18,
      );
    });
  });

  group('fase mantenimiento (12 semanas)', () {
    test('a los 83 días aún NO vence', () {
      expect(
        policy.isDue(
          updatedAt: base,
          now: base.add(const Duration(days: 83)),
          phase: IntakePhase.maintenance,
        ),
        false,
      );
    });

    test('a los 84 días vence', () {
      expect(
        policy.isDue(
          updatedAt: base,
          now: base.add(const Duration(days: 84)),
          phase: IntakePhase.maintenance,
        ),
        true,
      );
    });
  });

  test('intervalos por fase', () {
    expect(policy.intervalDays(IntakePhase.active), 28);
    expect(policy.intervalDays(IntakePhase.maintenance), 84);
  });
}
