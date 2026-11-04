// Fix notificaciones (2026-10-30): máximo 3 avisos al día.

import 'package:elena_app/src/core/services/notification_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationPolicy', () {
    test('por defecto: los 3 avisos del día metabólico', () {
      final ids = NotificationPolicy.allowedIdsFor(
        NotificationPolicy.defaultEnabled,
        kHardMaxPerDay,
      );
      expect(ids, {310, 311, 312});
    });

    test('nunca más de 3, aunque se activen los 5 tipos', () {
      final ids = NotificationPolicy.allowedIdsFor(
        NotificationKind.values.toSet(),
        99,
      );
      expect(ids.length, 3);
      // Se quedan los de mayor prioridad: los del día metabólico.
      expect(ids, {310, 311, 312});
    });

    test('respeta un límite menor elegido por el usuario', () {
      final ids = NotificationPolicy.allowedIdsFor(
        NotificationPolicy.defaultEnabled,
        1,
      );
      expect(ids, {311}, reason: 'con 1 aviso, queda "Cierra tu día"');
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
        100, 101, 102, 103, 104, 105, 107, 108, 109, 611, // de reloj
        200, 201, 202, 203, // hitos de ayuno (203 solo si se activa)
        300, 301, 450, 500, 501, 600, 601, 602, 603, 610,
      ]) {
        expect(ids.contains(blocked), isFalse, reason: 'ID $blocked');
      }
    });

    test('la purga cancela todo lo conocido salvo lo permitido y el 700', () {
      final allowed = {310, 311, 312};
      final targets = NotificationPolicy.purgeTargets(allowed);
      expect(targets, isNot(contains(310)));
      expect(targets, isNot(contains(311)));
      expect(targets, isNot(contains(312)));
      expect(targets, isNot(contains(700)));
      expect(targets,
          containsAll([100, 101, 108, 200, 400, 439, 500, 600, 610, 611]));
    });

    test('migra una configuración v1 guardada a los nuevos defaults',
        () async {
      SharedPreferences.setMockInitialValues({
        'notificationPolicy.enabledKinds': ['manana', 'comidas', 'sueno'],
        'notificationPolicy.maxPerDay': 3,
      });
      await NotificationPolicy.load();
      expect(NotificationPolicy.enabled, NotificationPolicy.defaultEnabled);
      expect(NotificationPolicy.allows(311), isTrue);
      expect(NotificationPolicy.allows(108), isFalse);
    });

    test('guarda y carga la configuración, recortando el límite a 3', () async {
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
