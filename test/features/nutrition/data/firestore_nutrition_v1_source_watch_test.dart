// Auditoría 2026-06-08 — tests anti-regresión de persistencia del pilar
// Nutrición (P1 live-updates + P2 ventana abierta tras medianoche).
//
// Bug original: `watchTodayLogs` aplicaba `endOfDay ?? endOfDay(now)` como
// tope superior del rango. Eso:
//   - (P2) cortaba las comidas registradas DESPUÉS de medianoche en ciclos
//     metabólicos que cruzan el día, a diferencia de exercise/hydration
//     (que son streams abiertos).
//   - (P1) en combinación con el churn de App Check, hacía que las nuevas
//     comidas "no se registraran en tiempo real" hasta reabrir la app.
//
// Fix: el tope superior SOLO se aplica cuando `endOfDay` es explícito.
// Con `endOfDay == null` el stream queda abierto. Estos tests bloquean
// la regresión.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/nutrition/data/sources/firestore_nutrition_v1_source.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreNutritionV1Source source;
  const userId = 'user-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    source = FirestoreNutritionV1Source(firestore);
  });

  CollectionReference<Map<String, dynamic>> col() => firestore
      .collection('users')
      .doc(userId)
      .collection('nutrition_history');

  Future<void> seedMeal(String id, DateTime ts) =>
      col().doc(id).set({'timestamp': Timestamp.fromDate(ts)});

  group('watchTodayLogs — stream abierto (endOfDay == null)', () {
    test('P2: captura comidas registradas DESPUÉS de medianoche', () async {
      // start = ayer 18:00 (ciclo metabólico que cruza el día).
      final start = DateTime(2026, 6, 6, 18, 0);
      // Comida registrada hoy 01:30 — pasada la medianoche del start.
      await seedMeal('m_post_midnight', DateTime(2026, 6, 7, 1, 30));
      // Comida dentro del mismo día del start.
      await seedMeal('m_evening', DateTime(2026, 6, 6, 20, 0));

      final logs = await source
          .watchTodayLogs(userId, startOfDay: start, endOfDay: null)
          .first;

      final ids = logs.map((e) => e.docId).toSet();
      expect(ids, containsAll(['m_evening', 'm_post_midnight']),
          reason: 'sin tope superior, ambas comidas deben aparecer');
    });

    test('P1: una comida nueva aparece en vivo sin reabrir el stream',
        () async {
      final start = DateTime(2026, 6, 7, 0, 0);
      await seedMeal('m1', DateTime(2026, 6, 7, 8, 0));

      // El stream es de suscripción única: lo escuchamos UNA vez con
      // matchers. Primera emisión = solo m1; tras escribir m2 (más tarde
      // en el día) debe re-emitir con ambas. Si el stream estuviera
      // capado arriba, m2 no aparecería en vivo (la regresión).
      final stream =
          source.watchTodayLogs(userId, startOfDay: start, endOfDay: null);

      final expectation = expectLater(
        stream,
        emitsInOrder([
          predicate<List<({String docId, Map<String, dynamic> data})>>(
            (l) => l.length == 1 && l.first.docId == 'm1',
          ),
          predicate<List<({String docId, Map<String, dynamic> data})>>(
            (l) =>
                l.length == 2 &&
                l.map((e) => e.docId).toSet().containsAll({'m1', 'm2'}),
          ),
        ]),
      );

      // Escritura posterior una vez la suscripción está activa.
      await seedMeal('m2', DateTime(2026, 6, 7, 13, 0));
      await expectation;
    });

    test('excluye comidas anteriores al start', () async {
      final start = DateTime(2026, 6, 7, 0, 0);
      await seedMeal('m_ayer', DateTime(2026, 6, 6, 23, 0));
      await seedMeal('m_hoy', DateTime(2026, 6, 7, 9, 0));

      final logs = await source
          .watchTodayLogs(userId, startOfDay: start, endOfDay: null)
          .first;

      final ids = logs.map((e) => e.docId).toSet();
      expect(ids, contains('m_hoy'));
      expect(ids, isNot(contains('m_ayer')));
    });
  });

  group('watchTodayLogs — tope explícito (endOfDay != null)', () {
    test('respeta el límite superior cuando se provee', () async {
      final start = DateTime(2026, 6, 7, 0, 0);
      final end = DateTime(2026, 6, 7, 12, 0);
      await seedMeal('m_manana', DateTime(2026, 6, 7, 9, 0));
      await seedMeal('m_tarde', DateTime(2026, 6, 7, 15, 0));

      final logs = await source
          .watchTodayLogs(userId, startOfDay: start, endOfDay: end)
          .first;

      final ids = logs.map((e) => e.docId).toSet();
      expect(ids, contains('m_manana'));
      expect(ids, isNot(contains('m_tarde')),
          reason: 'con endOfDay explícito, la tarde queda fuera');
    });
  });
}
