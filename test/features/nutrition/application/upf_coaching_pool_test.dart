// Tests del UpfCoachingPool — SPEC-138 §16.9.
//
// Verifican que el pool tenga copies en cada severidad, que cada uno
// lleve cita bibliográfica (criterio "todo comprobable
// científicamente") y que el selector con cooldown funcione.

import 'package:elena_app/src/features/nutrition/application/upf_coaching_pool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-138 — UpfCoachingPool tiene copies por severidad', () {
    test('alerts no vacío', () {
      expect(UpfCoachingPool.alerts, isNotEmpty);
      expect(UpfCoachingPool.alerts.length, greaterThanOrEqualTo(3));
    });

    test('improvements no vacío', () {
      expect(UpfCoachingPool.improvements, isNotEmpty);
      expect(UpfCoachingPool.improvements.length, greaterThanOrEqualTo(2));
    });

    test('maintenance no vacío', () {
      expect(UpfCoachingPool.maintenance, isNotEmpty);
      expect(UpfCoachingPool.maintenance.length, greaterThanOrEqualTo(2));
    });
  });

  group('SPEC-138 — invariantes de calidad de copy', () {
    test('todos los copies tienen id, headline, body, citation', () {
      final all = [
        ...UpfCoachingPool.alerts,
        ...UpfCoachingPool.improvements,
        ...UpfCoachingPool.maintenance,
      ];
      for (final c in all) {
        expect(c.id, isNotEmpty, reason: 'copy sin id');
        expect(c.headline, isNotEmpty, reason: '${c.id} sin headline');
        expect(c.body, isNotEmpty, reason: '${c.id} sin body');
        expect(c.citation, isNotEmpty, reason: '${c.id} sin citation');
      }
    });

    test('todas las citas mencionan al menos un autor canon', () {
      // Criterio "todo comprobable científicamente": cada copy debe
      // remitir a Monteiro 2019 o Hall 2019 (bibliografía SPEC-138).
      final canonAuthors = ['Monteiro', 'Hall', 'Srour'];
      final all = [
        ...UpfCoachingPool.alerts,
        ...UpfCoachingPool.improvements,
        ...UpfCoachingPool.maintenance,
      ];
      for (final c in all) {
        final hasCanon = canonAuthors.any((a) => c.citation.contains(a));
        expect(hasCanon, isTrue,
            reason: '${c.id} no cita ningún autor canon (Monteiro/Hall/Srour)');
      }
    });

    test('todos los ids son únicos', () {
      final all = [
        ...UpfCoachingPool.alerts,
        ...UpfCoachingPool.improvements,
        ...UpfCoachingPool.maintenance,
      ];
      final ids = all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'ids duplicados en el pool');
    });

    test('severity asignada coincide con su pool', () {
      for (final c in UpfCoachingPool.alerts) {
        expect(c.severity, UpfInsightSeverity.alert);
      }
      for (final c in UpfCoachingPool.improvements) {
        expect(c.severity, UpfInsightSeverity.improvement);
      }
      for (final c in UpfCoachingPool.maintenance) {
        expect(c.severity, UpfInsightSeverity.maintenance);
      }
    });

    test('headlines son cortos (≤ 50 chars)', () {
      // Pensados para card de coaching, no para body largo.
      final all = [
        ...UpfCoachingPool.alerts,
        ...UpfCoachingPool.improvements,
        ...UpfCoachingPool.maintenance,
      ];
      for (final c in all) {
        expect(c.headline.length, lessThanOrEqualTo(50),
            reason: '${c.id} headline largo: ${c.headline.length} chars');
      }
    });

    test('citation con formato "· Autor Año"', () {
      // Convención: empieza con "· " (separador visual)
      final all = [
        ...UpfCoachingPool.alerts,
        ...UpfCoachingPool.improvements,
        ...UpfCoachingPool.maintenance,
      ];
      for (final c in all) {
        expect(c.citation.startsWith('· '), isTrue,
            reason: '${c.id} citation no empieza con "· "');
      }
    });
  });

  group('SPEC-138 — selector con cooldown', () {
    test('select devuelve un copy de la severidad pedida', () {
      final r = UpfCoachingPool.select(severity: UpfInsightSeverity.alert);
      expect(r.severity, UpfInsightSeverity.alert);
    });

    test('select evita IDs en recentIds', () {
      final firstAlert = UpfCoachingPool.alerts.first.id;
      final r = UpfCoachingPool.select(
        severity: UpfInsightSeverity.alert,
        recentIds: {firstAlert},
      );
      expect(r.id, isNot(firstAlert));
    });

    test('select cae al primero si todos están en recentIds', () {
      final allAlertIds = UpfCoachingPool.alerts.map((c) => c.id).toSet();
      final r = UpfCoachingPool.select(
        severity: UpfInsightSeverity.alert,
        recentIds: allAlertIds,
      );
      // No falla; repite el primero antes que devolver null.
      expect(r.id, UpfCoachingPool.alerts.first.id);
    });
  });
}
