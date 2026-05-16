// SPEC-87 §6 — Tests del data source de perfil. Verifica que el id
// del doc Firestore se inyecta al map siempre.

import 'package:elena_app/src/shared/data/sources/firestore_user_profile_v1_source.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreUserProfileV1Source source;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    source = FirestoreUserProfileV1Source(firestore: firestore);
  });

  group('SPEC-87 — streamProfile inyecta id del doc', () {
    test('doc canónico sin campo id → map tiene id del path', () async {
      const uid = 'mr-user-123';
      await firestore.collection('users').doc(uid).set({
        'displayName': 'Carlos',
        'genderCanonical': 'male',
        'bio': {'heightCm': 180, 'weightKg': 80},
      });

      final emitted = await source.streamProfile(uid).first;

      expect(emitted, isNotNull);
      expect(emitted!['id'], uid);
      expect(emitted['displayName'], 'Carlos');
    });

    test('doc legacy con id correcto → id permanece igual', () async {
      const uid = 'app-user-456';
      await firestore.collection('users').doc(uid).set({
        'id': uid,
        'name': 'Carlos',
        'age': 35,
      });

      final emitted = await source.streamProfile(uid).first;

      expect(emitted!['id'], uid);
    });

    test('doc con id distinto al path → el path gana (autoritativo)', () async {
      const uid = 'real-uid';
      // Simulamos doc corrupto con id stale.
      await firestore.collection('users').doc(uid).set({
        'id': 'stale-id',
        'name': 'Carlos',
      });

      final emitted = await source.streamProfile(uid).first;

      expect(emitted!['id'], uid);
      expect(emitted['id'], isNot(equals('stale-id')));
    });

    test('doc inexistente → null', () async {
      final emitted = await source.streamProfile('no-existe').first;
      expect(emitted, isNull);
    });
  });
}
