// Fix notificaciones (2026-10-30): máximo 3 avisos al día.

import 'package:elena_app/src/core/services/notification_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationPolicy', () {
    test('por defecto: mañana, comidas y buenas noches (3 avisos)', () {
      final ids = NotificationPolicy.allowedIdsFor(
        NotificationPolicy.defaultEnabled,
        kHardMaxPerDay,
      );
      expect(ids, {108, 102, 611});
    });

    test('nunca más de 3, aunque se activen los 5 tipos', () {
      final ids = NotificationPolicy.allowedIdsFor(
        NotificationKind.values.toSet(),
        99,
      );
      expect(ids.length, 3);
      // Se quedan los de mayor prioridad.
      expect(ids, {108, 102, 611});
    });

    test('respeta un límite menor elegido por el usuario', () {
      final ids = NotificationPolicy.allowedIdsFor(
        NotificationPolicy.defaultEnabled,
        1,
      );
      expect(ids, {108});
    });

    test('agua: solo el ID 400, nunca los 40 slots de antes', () {
      final ids = NotificationPolicy.allowedIdsFor(
        {NotificationKind.agua},
        3,
      );
      expect(ids, {400});
      for (var id = 401; id <= 439; id++) {
        expect(ids.contains(id), isFalse);
      }
    });

    test('bloquea hitos, check-ins, rutina de sueño y muro de pago', () {
      final ids = NotificationPolicy.allowedIdsFor(
        NotificationPolicy.defaultEnabled,
        3,
      );
      for (final blocked in [
        100, 101, 103, 104, 105, 107, 109, // circadianas extra
        200, 201, 202, 203, // hitos de ayuno (203 solo si se activa)
        300, 301, 450, 500, 501, 600, 601, 602, 603, 610,
      ]) {
        expect(ids.contains(blocked), isFalse, reason: 'ID $blocked');
      }
    });

    test('la purga cancela todo lo conocido salvo lo permitido y el 700', () {
      final allowed = {108, 102, 611};
      final targets = NotificationPolicy.purgeTargets(allowed);
      expect(targets, isNot(contains(108)));
      expect(targets, isNot(contains(102)));
      expect(targets, isNot(contains(611)));
      expect(targets, isNot(contains(700)));
      expect(targets, containsAll([100, 101, 200, 400, 439, 500, 600, 610]));
    });

    test('guarda y carga la configuración, recortando el límite a 3',
        () async {
      SharedPreferences.setMockInitialValues({});
      await NotificationPolicy.save(
        enabled: {NotificationKind.manana, NotificationKind.agua},
        maxPerDay: 10,
      );
      await NotificationPolicy.load();
      expect(NotificationPolicy.enabled,
          {NotificationKind.manana, NotificationKind.agua});
      expect(NotificationPolicy.maxPerDay, kHardMaxPerDay);
      expect(NotificationPolicy.allows(400), isTrue);
      expect(NotificationPolicy.allows(611), isFalse);

      // Deja el estado global como estaba para otros tests.
      await NotificationPolicy.save(
        enabled: NotificationPolicy.defaultEnabled,
        maxPerDay: kHardMaxPerDay,
      );
    });
  });
}
