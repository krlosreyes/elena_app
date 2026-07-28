// SPEC-149.1 Bug 1a: tests del CycleClosureDismissalNotifier.
//
// Garantiza:
//  - hidrata el estado desde SharedPreferences en construcción.
//  - dismiss() escribe a prefs Y actualiza state in-memory.
//  - el cambio de state notifica a watchers.

import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kKey = 'metabolicCycle.lastClosureDismissedCycleId';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SPEC-149.1 Bug 1a — CycleClosureDismissalNotifier', () {
    test('estado inicial es null cuando prefs no tiene valor previo', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = CycleClosureDismissalNotifier(prefs);

      expect(notifier.state, isNull);
    });

    test('hidrata el estado desde prefs en construcción', () async {
      SharedPreferences.setMockInitialValues({_kKey: 'cycle-abc-123'});
      final prefs = await SharedPreferences.getInstance();
      final notifier = CycleClosureDismissalNotifier(prefs);

      expect(notifier.state, 'cycle-abc-123');
    });

    test('dismiss() actualiza el state in-memory inmediatamente', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = CycleClosureDismissalNotifier(prefs);
      expect(notifier.state, isNull);

      await notifier.dismiss('cycle-new-id');

      expect(notifier.state, 'cycle-new-id');
    });

    test('dismiss() persiste el cycleId en SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = CycleClosureDismissalNotifier(prefs);

      await notifier.dismiss('cycle-persisted');

      expect(prefs.getString(_kKey), 'cycle-persisted');
    });

    test('dismiss() múltiples veces reemplaza el cycleId, no acumula',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = CycleClosureDismissalNotifier(prefs);

      await notifier.dismiss('cycle-1');
      await notifier.dismiss('cycle-2');
      await notifier.dismiss('cycle-3');

      expect(notifier.state, 'cycle-3');
      expect(prefs.getString(_kKey), 'cycle-3');
    });

    test('el nuevo notifier hidrata el último dismiss persistido', () async {
      // Simula reapertura de la app: dismiss en una sesión, lee en otra.
      var prefs = await SharedPreferences.getInstance();
      final firstNotifier = CycleClosureDismissalNotifier(prefs);
      await firstNotifier.dismiss('cycle-prev-session');

      // Nueva instancia leyendo de las mismas prefs.
      prefs = await SharedPreferences.getInstance();
      final secondNotifier = CycleClosureDismissalNotifier(prefs);

      expect(secondNotifier.state, 'cycle-prev-session');
    });
  });
}
