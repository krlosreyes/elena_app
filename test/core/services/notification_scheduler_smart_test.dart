// SPEC-169 §RF-169-06 (2026-06-04): tests del scheduler smart.
//
// Validan la matemática del anclaje al ciclo metabólico, el cómputo
// del eTRF pre-sueño y el mapeo protocolo → horas — sin tocar el
// plugin nativo de notificaciones (mismo enfoque que SPEC-150).

import 'package:elena_app/src/core/services/notification_scheduler.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replica la lógica del bloque 3 (lastMealWarning) de scheduleCircadianDay.
/// Retorna la hora:minuto a la que se programaría el aviso, o null si
/// no hay datos suficientes.
({int hour, int minute})? computeLastMealWarning({
  int? lastMealHour,
  int? lastMealMinute,
  String? cycleProtocol,
  DateTime? cycleStartedAt,
}) {
  // Igual que scheduler:
  //  - si openCycle && protocol conocido → usar startedAt+24h
  //  - else si lastMealGoal != null → usar lastMealGoal
  //  - else → no programar
  DateTime? lastMealDt;
  final cycleHours = cycleProtocol == null
      ? null
      : NotificationScheduler.protocolFastingHours(cycleProtocol);
  if (cycleStartedAt != null && cycleHours != null) {
    final close = cycleStartedAt.add(const Duration(hours: 24)).toLocal();
    lastMealDt = DateTime(2000, 1, 1, close.hour, close.minute);
  } else if (lastMealHour != null && lastMealMinute != null) {
    lastMealDt = DateTime(2000, 1, 1, lastMealHour, lastMealMinute);
  }
  if (lastMealDt == null) return null;
  final warning = lastMealDt.subtract(const Duration(minutes: 30));
  return (hour: warning.hour, minute: warning.minute);
}

/// Replica la lógica del bloque 8 (eTRF pre-sueño) de scheduleCircadianDay.
/// Retorna la hora:minuto a la que se programaría, o null si no se
/// agenda (lastMealDt cae antes de o igual a eTRFCutoff).
({int hour, int minute})? computeETRFPreSleep({
  required int sleepHour,
  required int sleepMinute,
  int? lastMealHour,
  int? lastMealMinute,
}) {
  final sleepDt = DateTime(2000, 1, 1, sleepHour, sleepMinute);
  final eTRFCutoff = sleepDt.subtract(const Duration(hours: 3));
  final lastMealDt = (lastMealHour == null || lastMealMinute == null)
      ? null
      : DateTime(2000, 1, 1, lastMealHour, lastMealMinute);
  if (lastMealDt != null && !eTRFCutoff.isBefore(lastMealDt)) return null;
  return (hour: eTRFCutoff.hour, minute: eTRFCutoff.minute);
}

void main() {
  group('SPEC-169 §RF-169-04 — protocolFastingHours', () {
    test('mapea protocolos canónicos', () {
      expect(NotificationScheduler.protocolFastingHours('12:12'), 12);
      expect(NotificationScheduler.protocolFastingHours('14:10'), 14);
      expect(NotificationScheduler.protocolFastingHours('16:8'), 16);
      expect(NotificationScheduler.protocolFastingHours('18:6'), 18);
      expect(NotificationScheduler.protocolFastingHours('20:4'), 20);
      expect(NotificationScheduler.protocolFastingHours('22:2'), 22);
      expect(NotificationScheduler.protocolFastingHours('OMAD'), 23);
    });

    test('Ninguno y desconocidos retornan null (fallback al perfil)', () {
      expect(NotificationScheduler.protocolFastingHours('Ninguno'), isNull);
      expect(NotificationScheduler.protocolFastingHours('basura'), isNull);
      expect(NotificationScheduler.protocolFastingHours(''), isNull);
    });
  });

  group('SPEC-169 §RF-169-04 — anclaje al ciclo en lastMealWarning', () {
    test('sin ciclo abierto usa lastMealGoal del perfil', () {
      final warning = computeLastMealWarning(
        lastMealHour: 20,
        lastMealMinute: 30,
      );
      expect(warning, isNotNull);
      expect(warning!.hour, 20);
      expect(warning.minute, 0);
    });

    test('con ciclo 16:8 startedAt 20:30 → ventana cierra 20:30 → aviso 20:00',
        () {
      // Ciclo iniciado 20:30 del día previo. startedAt + 24h = 20:30 hoy.
      final yesterdayClose = DateTime(2026, 6, 3, 20, 30);
      final warning = computeLastMealWarning(
        cycleProtocol: '16:8',
        cycleStartedAt: yesterdayClose,
        lastMealHour: 19, // distinto al ciclo a propósito — ciclo gana.
        lastMealMinute: 0,
      );
      expect(warning, isNotNull);
      expect(warning!.hour, 20);
      expect(warning.minute, 0);
    });

    test('ciclo protocolo Ninguno → cae al fallback del perfil', () {
      final warning = computeLastMealWarning(
        cycleProtocol: 'Ninguno',
        cycleStartedAt: DateTime(2026, 6, 3, 22, 0),
        lastMealHour: 21,
        lastMealMinute: 0,
      );
      // Debe usar lastMealGoal (21:00) → aviso 20:30, no la hora del ciclo.
      expect(warning, isNotNull);
      expect(warning!.hour, 20);
      expect(warning.minute, 30);
    });

    test('sin ciclo y sin lastMealGoal → no programa', () {
      final warning = computeLastMealWarning();
      expect(warning, isNull);
    });
  });

  group('SPEC-169 §RF-169-03 — eTRF pre-sueño', () {
    test('sleep 23:00 + lastMealGoal 22:00 → programa 20:00 (cae antes)', () {
      final etrf = computeETRFPreSleep(
        sleepHour: 23,
        sleepMinute: 0,
        lastMealHour: 22,
        lastMealMinute: 0,
      );
      expect(etrf, isNotNull);
      expect(etrf!.hour, 20);
      expect(etrf.minute, 0);
    });

    test('sleep 22:00 + lastMealGoal 19:00 → NO programa (eTRF = lastMeal)',
        () {
      // sleep 22 - 3h = 19:00 = lastMealGoal → no se agenda (no es before).
      final etrf = computeETRFPreSleep(
        sleepHour: 22,
        sleepMinute: 0,
        lastMealHour: 19,
        lastMealMinute: 0,
      );
      expect(etrf, isNull);
    });

    test(
        'sleep 22:00 + lastMealGoal 20:30 → NO programa (eTRF 19:00 < 20:30 es before, agenda 19:00)',
        () {
      // sleep 22 - 3h = 19:00. lastMeal 20:30. 19:00 < 20:30 → agenda.
      final etrf = computeETRFPreSleep(
        sleepHour: 22,
        sleepMinute: 0,
        lastMealHour: 20,
        lastMealMinute: 30,
      );
      expect(etrf, isNotNull);
      expect(etrf!.hour, 19);
      expect(etrf.minute, 0);
    });

    test('sin lastMealGoal → programa eTRF siempre', () {
      final etrf = computeETRFPreSleep(sleepHour: 23, sleepMinute: 30);
      expect(etrf, isNotNull);
      expect(etrf!.hour, 20);
      expect(etrf.minute, 30);
    });
  });

  group('SPEC-169 — IDs reservados', () {
    test('fasting16h en rango fasting 200-209', () {
      expect(NotificationIds.fasting16h, inInclusiveRange(200, 209));
    });

    test('eTRFPreSleep en rango circadiano 100-109', () {
      expect(NotificationIds.eTRFPreSleep, inInclusiveRange(100, 109));
    });

    test('los 4 hitos de ayuno son IDs distintos', () {
      final ids = {
        NotificationIds.fasting12h,
        NotificationIds.fasting16h,
        NotificationIds.fasting18h,
        NotificationIds.fasting24h,
      };
      expect(ids.length, 4);
    });
  });
}
