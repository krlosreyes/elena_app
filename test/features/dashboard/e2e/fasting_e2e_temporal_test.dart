// SPEC-118 — Grupo B: reglas temporales del ayuno.
//
// 6 tests que verifican:
//   - Ayunos que cruzan medianoche
//   - Fases extendidas (autofagia >24h, survival >48h)
//   - Atribución correcta en protocolos no-16:8
//   - Bloqueo circadiano 21:30 (cierre intestinal)
//
// Filosofía: lógica pura sobre `FastingState` y `CircadianRules`.
// No requiere Firestore ni Riverpod porque la regla temporal vive en
// dominio puro.

import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-118.B — Reglas temporales del ayuno', () {
    test(
      'B1: ayuno cruza medianoche (start 23:00 ayer, cierre 15:00 hoy) — '
      'al instante del cierre completedToday=true → progresoHoy=1.0',
      () {
        final yesterday23 = DateTime(2026, 5, 15, 23, 0);
        final today15 = DateTime(2026, 5, 16, 15, 0);
        final duration = today15.difference(yesterday23); // 16h exactas.

        final stateAfterClose = FastingState(
          startTime: yesterday23,
          duration: duration,
          isActive: false,
          fastingProtocol: '16:8',
          completedToday: true,
        );

        // Regla simplificada de dailySummaryProvider: completedToday → 1.0.
        expect(stateAfterClose.progressPercentage, 1.0);
        // Duración exacta = 16h (no perdimos las horas previas a medianoche).
        expect(duration.inHours, 16);
      },
    );

    test(
      'B2: ayuno de 26h (autofagia) — fase correcta y progressPercentage '
      'clamp a 1.0 sin overflow',
      () {
        final start = DateTime(2026, 5, 15, 17, 0);
        final now = DateTime(2026, 5, 16, 19, 0); // +26h
        final duration = now.difference(start);

        expect(FastingState.determinePhase(duration), FastingPhase.autophagy);

        final state = FastingState(
          startTime: start,
          duration: duration,
          isActive: true,
          fastingProtocol: '16:8',
          phase: FastingPhase.autophagy,
        );
        // 26h / 16h = 1.625 → clamp(0,1) = 1.0.
        expect(state.progressPercentage, 1.0);
        expect(state.metabolicMilestone, 'Autofagia Activa');
      },
    );

    test(
      'B3: ayuno de 50h (survival) — fase correcta y getters textuales '
      'no son null',
      () {
        final duration = const Duration(hours: 50);
        expect(FastingState.determinePhase(duration), FastingPhase.survival);

        final state = FastingState(
          startTime: DateTime(2026, 5, 14, 17, 0),
          duration: duration,
          isActive: true,
          fastingProtocol: '16:8',
          phase: FastingPhase.survival,
        );

        expect(state.metabolicMilestone, 'Regeneración Celular');
        expect(state.nextMilestoneLabel, 'FASE DE REGENERACIÓN PROFUNDA');
        expect(state.timeRemainingForNextMilestone, Duration.zero);
        expect(state.progressPercentage, 1.0);
      },
    );

    test(
      'B4: protocolo 18:6 con completedToday=true (cierre a las 17:00, '
      'duración 17h) — satélite NO muestra 0% (bug histórico)',
      () {
        // Caso reportado en SPEC-118.bugfix: protocolo 18:6, target 18h,
        // cierre 17:00 con duración cercana al target → durante el resto
        // del día el satélite estaba en 0% por la regla previa.
        // Hoy: completedToday=true → 1.0 sin importar target.
        final state = FastingState(
          startTime: DateTime(2026, 5, 16, 0, 0),
          duration: const Duration(hours: 17),
          isActive: false,
          fastingProtocol: '18:6',
          completedToday: true,
        );
        expect(state.targetHours, 18);
        expect(state.progressPercentage, 1.0);
      },
    );

    test(
      'B5: CircadianRules.timeUntilLock a las 20:30 reporta ~1h al lock '
      '21:30 (cierre intestinal SPEC-70.5)',
      () {
        final at2030 = DateTime(2026, 5, 16, 20, 30);
        final remaining = CircadianRules.timeUntilLock(at2030);
        // 21:30 - 20:30 = 1h exacta.
        expect(remaining.inMinutes, 60);

        // Validamos también la constante: 21*60 + 30 = 1290.
        expect(CircadianRules.intestinalLockMinutes, 1290);
      },
    );

    test(
      'B6: ayuno activo cruzando medianoche — duración crece linealmente '
      '(no se reinicia al cambio de día)',
      () {
        final start = DateTime(2026, 5, 15, 23, 0);

        // Snapshot a las 23:30 del día de inicio: duración 30min.
        final t1 = DateTime(2026, 5, 15, 23, 30);
        final d1 = t1.difference(start);
        expect(d1.inMinutes, 30);

        // Snapshot a las 00:30 del día siguiente: duración 1.5h.
        final t2 = DateTime(2026, 5, 16, 0, 30);
        final d2 = t2.difference(start);
        expect(d2.inMinutes, 90);

        // Snapshot a las 15:00 del día siguiente: duración 16h.
        final t3 = DateTime(2026, 5, 16, 15, 0);
        final d3 = t3.difference(start);
        expect(d3.inHours, 16);

        // Sin completedToday, isActive=true: progressPercentage real.
        final state = FastingState(
          startTime: start,
          duration: d3,
          isActive: true,
          fastingProtocol: '16:8',
        );
        expect(state.progressPercentage, 1.0);

        // Fase determinada por la duración total (no por hora del día).
        // 16h cae en `transition` (12-18h); `fatBurning` empieza a las 18h.
        expect(FastingState.determinePhase(d3), FastingPhase.transition);
      },
    );
  });
}
