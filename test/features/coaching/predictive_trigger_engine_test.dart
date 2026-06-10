// SPEC-199 Fase A (RF-199-05) — tests del motor predictivo de prompts.

import 'package:elena_app/src/features/coaching/application/predictive_trigger_engine.dart';
import 'package:elena_app/src/features/coaching/domain/actionable_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mediodía: dentro de la ventana de vigilia típica (wake 7, sleep 23).
  final midday = DateTime(2026, 6, 10, 12, 0);

  ActionablePrompt? call({
    bool goalReached = false,
    DateTime? now,
    Duration? sinceLastGlass,
    int wakeHour = 7,
    int sleepHour = 23,
  }) =>
      PredictiveTriggerEngine.hydrationPrompt(
        goalReached: goalReached,
        now: now ?? midday,
        sinceLastGlass: sinceLastGlass,
        wakeHour: wakeHour,
        sleepHour: sleepHour,
      );

  group('PredictiveTriggerEngine.hydrationPrompt — supresión', () {
    test('meta cumplida → null', () {
      expect(call(goalReached: true), isNull);
    });

    test('antes de despertar → null', () {
      expect(call(now: DateTime(2026, 6, 10, 5, 0)), isNull);
    });

    test('tras el cutoff de reparación (21h) → null', () {
      expect(call(now: DateTime(2026, 6, 10, 21, 30)), isNull);
    });

    test('si duerme temprano, respeta su sleepHour como cutoff', () {
      // sleepHour 20 < 21 → cutoff 20; a las 20:30 se suprime.
      expect(
        call(now: DateTime(2026, 6, 10, 20, 30), sleepHour: 20),
        isNull,
      );
    });

    test('vaso reciente (< gap mínimo) → null', () {
      expect(call(sinceLastGlass: const Duration(minutes: 20)), isNull);
    });
  });

  group('PredictiveTriggerEngine.hydrationPrompt — emite', () {
    test('contexto válido → prompt con opción primaria de registrar agua', () {
      final p = call(sinceLastGlass: const Duration(hours: 2));
      expect(p, isNotNull);
      expect(p!.options.length, 2);
      final primary = p.options.firstWhere((o) => o.isPrimary);
      expect(primary.action, PromptActionType.logWater);
      expect(
        p.options.any((o) => o.action == PromptActionType.snooze),
        isTrue,
      );
    });

    test('sin vasos aún (sinceLastGlass null) → emite', () {
      expect(call(sinceLastGlass: null), isNotNull);
    });

    test('el id incluye bucket horario (estable dentro de la hora)', () {
      final a = call(now: DateTime(2026, 6, 10, 12, 5));
      final b = call(now: DateTime(2026, 6, 10, 12, 50));
      expect(a!.id, b!.id);
      final c = call(now: DateTime(2026, 6, 10, 13, 5));
      expect(a.id, isNot(c!.id));
    });
  });
}
