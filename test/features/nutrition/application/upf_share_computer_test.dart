// Tests de UpfShareComputer — SPEC-138 §16.4.
//
// Verifican el cálculo del % UPF agregado con retrocompatibilidad
// (logs pre-138 sin campos NOVA), invariantes de denominador cero,
// y la marca de "accionable" según mínimo de logs con datos NOVA.

import 'package:elena_app/src/features/nutrition/application/upf_share_computer.dart';
import 'package:elena_app/src/features/nutrition/application/upf_thresholds.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionLog _log({
  required String id,
  int? upfSlots,
  int? totalSlots,
}) =>
    NutritionLog(
      id: id,
      timestamp: DateTime(2026, 6, 5, 13),
      label: 'Almuerzo',
      withinCircadianWindow: true,
      upfSlots: upfSlots,
      totalSlots: totalSlots,
    );

void main() {
  group('SPEC-138 — UpfShareComputer.compute', () {
    test('lista vacía → empty result', () {
      final r = UpfShareComputer.compute(const []);
      expect(r.sharePercent, 0);
      expect(r.upfSlots, 0);
      expect(r.totalSlots, 0);
      expect(r.logsWithNova, 0);
      expect(r.totalLogs, 0);
    });

    test('todos los logs pre-138 (sin NOVA) → 0% pero totalLogs > 0', () {
      final logs = [
        _log(id: 'old-1'),
        _log(id: 'old-2'),
        _log(id: 'old-3'),
      ];
      final r = UpfShareComputer.compute(logs);
      expect(r.sharePercent, 0,
          reason: 'sin datos NOVA → semántica "aún no sabemos"');
      expect(r.totalSlots, 0);
      expect(r.logsWithNova, 0);
      expect(r.totalLogs, 3);
    });

    test('3 logs sin UPF: 0% pero logsWithNova = 3', () {
      final logs = [
        _log(id: 'a', upfSlots: 0, totalSlots: 5),
        _log(id: 'b', upfSlots: 0, totalSlots: 4),
        _log(id: 'c', upfSlots: 0, totalSlots: 5),
      ];
      final r = UpfShareComputer.compute(logs);
      expect(r.sharePercent, 0);
      expect(r.upfSlots, 0);
      expect(r.totalSlots, 14);
      expect(r.logsWithNova, 3);
    });

    test('1 log 100% UPF, 2 logs 0% UPF: 2/14 = 14%', () {
      final logs = [
        _log(id: 'a', upfSlots: 0, totalSlots: 5),
        _log(id: 'b', upfSlots: 2, totalSlots: 2),
        _log(id: 'c', upfSlots: 0, totalSlots: 5),
      ];
      final r = UpfShareComputer.compute(logs);
      expect(r.upfSlots, 2);
      expect(r.totalSlots, 12);
      // 2/12 = 16.67 → redondeo a 17.
      expect(r.sharePercent, 17);
    });

    test('mix de logs con y sin NOVA: solo cuentan los con NOVA', () {
      final logs = [
        _log(id: 'old-1'),
        _log(id: 'new-1', upfSlots: 1, totalSlots: 4),
        _log(id: 'old-2'),
        _log(id: 'new-2', upfSlots: 0, totalSlots: 5),
      ];
      final r = UpfShareComputer.compute(logs);
      expect(r.logsWithNova, 2);
      expect(r.totalLogs, 4);
      // 1/9 = 11.1 → 11
      expect(r.sharePercent, 11);
    });

    test('log con totalSlots=0 se ignora del cálculo', () {
      // Caso defensivo: si el plato fue armado y luego vaciado, no
      // debe corromper el denominador.
      final logs = [
        _log(id: 'a', upfSlots: 0, totalSlots: 0),
        _log(id: 'b', upfSlots: 1, totalSlots: 4),
      ];
      final r = UpfShareComputer.compute(logs);
      expect(r.logsWithNova, 1);
      expect(r.totalSlots, 4);
      expect(r.sharePercent, 25);
    });

    test('100% UPF agregado: solo logs ultraprocesados', () {
      final logs = [
        _log(id: 'a', upfSlots: 2, totalSlots: 2),
        _log(id: 'b', upfSlots: 4, totalSlots: 4),
      ];
      final r = UpfShareComputer.compute(logs);
      expect(r.sharePercent, 100);
    });
  });

  group('SPEC-138 — UpfShareResult.isActionable', () {
    test('cero logsWithNova: NO accionable', () {
      const r = UpfShareResult.empty(totalLogs: 5);
      expect(
        r.isActionable(minLogsWithNova: UpfThresholds.weeklyMinLogsWithNova),
        isFalse,
      );
    });

    test('debajo del umbral: NO accionable', () {
      const r = UpfShareResult(
        sharePercent: 50,
        upfSlots: 4,
        totalSlots: 8,
        logsWithNova: 3,
        totalLogs: 5,
      );
      expect(r.isActionable(minLogsWithNova: 5), isFalse);
    });

    test('iguala el umbral: accionable', () {
      const r = UpfShareResult(
        sharePercent: 30,
        upfSlots: 3,
        totalSlots: 10,
        logsWithNova: 5,
        totalLogs: 5,
      );
      expect(r.isActionable(minLogsWithNova: 5), isTrue);
    });
  });

  group('SPEC-138 — UpfThresholds (constantes científicas)', () {
    test('weeklyAlertPercent = 40 (Hall 2019)', () {
      expect(UpfThresholds.weeklyAlertPercent, 40);
    });

    test('hoyVisibilityPercent = 25 (decisión UI)', () {
      expect(UpfThresholds.hoyVisibilityPercent, 25);
    });

    test('weeklyMinLogsWithNova >= 5 (datos accionables)', () {
      expect(UpfThresholds.weeklyMinLogsWithNova,
          greaterThanOrEqualTo(5));
    });
  });
}
