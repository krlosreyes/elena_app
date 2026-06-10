// SPEC-199 Fase A — tests de la cola de acciones pendientes.

import 'package:elena_app/src/core/services/pending_action_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PendingActionQueue — base', () {
    test('enqueue + peekAll devuelve la acción', () async {
      await PendingActionQueue.enqueue(const PendingAction(
        id: 'a1',
        type: PendingActionType.addWater,
        amount: 0.25,
        millisSinceEpoch: 1000,
      ));

      final all = await PendingActionQueue.peekAll();
      expect(all.length, 1);
      expect(all.first.id, 'a1');
      expect(all.first.type, PendingActionType.addWater);
      expect(all.first.amount, 0.25);
    });

    test('enqueue es idempotente por id (no duplica)', () async {
      const a = PendingAction(
        id: 'dup',
        type: PendingActionType.addWater,
        amount: 0.25,
        millisSinceEpoch: 1,
      );
      await PendingActionQueue.enqueue(a);
      await PendingActionQueue.enqueue(a);

      final all = await PendingActionQueue.peekAll();
      expect(all.length, 1);
    });

    test('remove borra por id', () async {
      await PendingActionQueue.enqueue(const PendingAction(
        id: 'x',
        type: PendingActionType.addWater,
        millisSinceEpoch: 1,
      ));
      await PendingActionQueue.remove('x');

      expect((await PendingActionQueue.peekAll()), isEmpty);
    });

    test('persiste entre lecturas (sobrevive cold start simulado)', () async {
      await PendingActionQueue.enqueue(const PendingAction(
        id: 'persist',
        type: PendingActionType.addWater,
        millisSinceEpoch: 1,
      ));
      // Segunda "sesión": SharedPreferences sigue teniendo el dato mock.
      final all = await PendingActionQueue.peekAll();
      expect(all.single.id, 'persist');
    });
  });

  group('PendingActionQueue — handleNotificationAction', () {
    final fixed = DateTime(2026, 6, 10, 14, 30);

    test('"Sí" encola addWater con el tamaño de vaso', () async {
      await PendingActionQueue.handleNotificationAction(
        kHydrationYesActionId,
        400,
        now: fixed,
      );
      final all = await PendingActionQueue.peekAll();
      expect(all.length, 1);
      expect(all.first.type, PendingActionType.addWater);
      expect(all.first.amount, kHydrationGlassLiters);
    });

    test('doble-tap dentro de la misma hora se deduplica', () async {
      await PendingActionQueue.handleNotificationAction(
        kHydrationYesActionId,
        400,
        now: fixed,
      );
      await PendingActionQueue.handleNotificationAction(
        kHydrationYesActionId,
        400,
        now: fixed.add(const Duration(minutes: 5)),
      );
      expect((await PendingActionQueue.peekAll()).length, 1);
    });

    test('"Aún no" encola hydrationSnoozed', () async {
      await PendingActionQueue.handleNotificationAction(
        kHydrationNoActionId,
        400,
        now: fixed,
      );
      final all = await PendingActionQueue.peekAll();
      expect(all.single.type, PendingActionType.hydrationSnoozed);
    });

    test('actionId nulo o desconocido no encola nada', () async {
      await PendingActionQueue.handleNotificationAction(null, 400, now: fixed);
      await PendingActionQueue.handleNotificationAction(
          'algo_raro', 400, now: fixed);
      expect((await PendingActionQueue.peekAll()), isEmpty);
    });
  });
}
