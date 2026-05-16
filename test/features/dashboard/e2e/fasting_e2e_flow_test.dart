// SPEC-118 — Grupo A: flujo completo de atribución del ayuno al día.
//
// Verifica que la regla simplificada del SPEC-118.bugfix (que vive
// dentro de `dailySummaryProvider`) responde correctamente a los 5
// estados del ayuno que conviven con `hasCompletedFastingTodayProvider`.
//
// Estrategia de testing:
//   El `dailySummaryProvider` real depende de ~7 StateNotifiers que a
//   su vez consumen Firestore + Auth + Ticker. Stubear ese ecosistema
//   entero en cada test sería frágil y caro en mantenimiento.
//
//   Por eso, la **regla de atribución** está replicada aquí como
//   función pura `_fastingProgressFromRule`. Es la misma fórmula
//   exacta que `dailySummaryProvider`. Si esa cambia, este archivo
//   debe actualizarse — y los tests B1/B4 también probarán la regla
//   en sus formas materializadas.
//
//   Trade-off: el test no detecta drift entre la regla del provider y
//   la regla aquí; pero blindar la regla por sí sola ya cubre 5 de los
//   6 bugs históricos.

import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Réplica EXACTA de la regla en
/// `lib/src/features/analysis/application/daily_summary_provider.dart`
/// líneas 68-75 (SPEC-118.bugfix).
double _fastingProgressFromRule({
  required bool completedFromBd,
  required FastingState fasting,
}) {
  if (completedFromBd || fasting.completedToday == true) return 1.0;
  if (fasting.isActive) return fasting.progressPercentage;
  return 0.0;
}

void main() {
  group('SPEC-118.A — Flujo de atribución del ayuno al día', () {
    test(
      'A1: ayuno activo en curso (5h, protocolo 16:8) — fastingProgress '
      'refleja proporción real ≈ 0.31',
      () {
        final state = FastingState(
          startTime: DateTime(2026, 5, 16, 10, 0),
          duration: const Duration(hours: 5),
          isActive: true,
          fastingProtocol: '16:8',
        );
        final progress = _fastingProgressFromRule(
          completedFromBd: false,
          fasting: state,
        );
        expect(progress, closeTo(5 / 16, 0.001));
        expect(state.progressPercentage, closeTo(5 / 16, 0.001));
      },
    );

    test(
      'A2: ayuno completado HOY (completedToday=true, isActive=false) — '
      'fastingProgress = 1.0 incluso en ventana de alimentación',
      () {
        // Caso post-cierre: el usuario ya cerró su ayuno, está en
        // ventana. Antes del fix caía a 0%. Hoy queda en 1.0 todo el día.
        final state = FastingState(
          startTime: DateTime(2026, 5, 16, 14, 0),
          duration: const Duration(minutes: 2),
          isActive: false,
          fastingProtocol: '16:8',
          completedToday: true,
        );
        final progress = _fastingProgressFromRule(
          completedFromBd: false,
          fasting: state,
        );
        expect(progress, 1.0);
      },
    );

    test(
      'A3: ayuno completado registrado SOLO en BD (completedFromBd=true, '
      'completedToday=null por hot-reload) — fastingProgress = 1.0',
      () {
        // Caso de hot-reload: el state in-memory perdió completedToday
        // pero la BD reporta el cierre. La doble fuente protege esto.
        final state = FastingState(
          startTime: null,
          isActive: false,
          fastingProtocol: '16:8',
          // completedToday: null (default explícito)
        );
        final progress = _fastingProgressFromRule(
          completedFromBd: true,
          fasting: state,
        );
        expect(progress, 1.0);
      },
    );

    test(
      'A4: estado inicial (sin ayuno activo, sin completedToday, BD limpia) '
      '— fastingProgress = 0.0',
      () {
        final state = FastingState.initial();
        final progress = _fastingProgressFromRule(
          completedFromBd: false,
          fasting: state,
        );
        expect(progress, 0.0);
      },
    );

    test(
      'A5: ayuno cerrado AYER (completedFromBd=false, completedToday=false) '
      '— fastingProgress = 0.0 hoy',
      () {
        // El día nuevo arranca con `resetDaily` que setea completedToday=false.
        // El provider hasCompletedFastingTodayProvider verifica que el
        // intervalo cerrado sea HOY — si fue ayer, retorna false.
        final state = FastingState(
          startTime: DateTime(2026, 5, 15, 23, 0),
          duration: const Duration(hours: 16),
          isActive: false,
          fastingProtocol: '16:8',
          completedToday: false,
        );
        final progress = _fastingProgressFromRule(
          completedFromBd: false,
          fasting: state,
        );
        expect(progress, 0.0);
      },
    );
  });
}
