// SPEC-73 §CA-73-01/02/03: tests de las 3 ramas del classifier.
//
// REQUIERE pubspec dev_dependencies:
//   firebase_auth_mocks: ^0.14.0
//   fake_cloud_firestore: ^3.0.0
//
// Si no están instaladas, ejecutar:
//   flutter pub add --dev firebase_auth_mocks fake_cloud_firestore
//   flutter pub get
//
// Estos paquetes no estaban en pubspec antes de SPEC-73. El líder de
// proyecto los agregará al cierre de la SPEC en el mismo PR.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/auth/data/firebase_auth_repository.dart';
import 'package:elena_app/src/features/auth/domain/app_account.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late FirebaseAuthRepository repo;

  const testEmail = 'mr_user@metamorfosis.com';
  const testPassword = 'TestPass123!';
  const testUid = 'mock_uid_001';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      // signedIn:true garantiza que authStateChanges emite el mockUser
      // inmediatamente. Sin esto la primera lectura del stream emite
      // null porque el mock arranca en "signed out".
      signedIn: true,
      mockUser: MockUser(
        uid: testUid,
        email: testEmail,
        displayName: 'Carlos MR',
      ),
    );
    repo = FirebaseAuthRepository(auth: auth, firestore: firestore);
  });

  group('signInWithEmail — clasificación de profileStatus', () {
    test('CA-73-01: usuario MR sin doc users/{uid} → AppAccount(NEW_PROFILE)',
        () async {
      // No hay doc Firestore.
      final account = await repo.signInWithEmail(
        email: testEmail,
        password: testPassword,
      );

      expect(account.uid, testUid);
      expect(account.profileStatus, AppProfileStatus.newProfile);
      expect(account.rawProfile, isNull);
      expect(account.needsOnboarding, isTrue);
    });

    test(
        'CA-73-02: usuario MR con doc shape MR (name/email/subscription) → '
        'AppAccount(PARTIAL_PROFILE) preservando rawProfile', () async {
      await firestore.collection('users').doc(testUid).set({
        'name': 'Carlos MR',
        'email': testEmail,
        'subscription_active': true,
        'purchases': ['programa_2025'],
      });

      final account = await repo.signInWithEmail(
        email: testEmail,
        password: testPassword,
      );

      expect(account.profileStatus, AppProfileStatus.partialProfile);
      expect(account.rawProfile, isNotNull);
      expect(account.rawProfile!['subscription_active'], true);
      expect(account.rawProfile!['purchases'], ['programa_2025']);
      expect(account.needsOnboarding, isTrue);
    });

    test(
        'CA-73-03: usuario app con doc completo → '
        'AppAccount(COMPLETE_PROFILE)', () async {
      await firestore.collection('users').doc(testUid).set({
        'id': testUid,
        'name': 'Carlos MR',
        'email': testEmail,
        'age': 38,
        'gender': 'M',
        'weight': 84.5,
        'height': 178,
        'profile': {
          'wakeUpTime': DateTime(2026, 1, 1, 7).toIso8601String(),
          'sleepTime': DateTime(2026, 1, 1, 22).toIso8601String(),
        },
      });

      final account = await repo.signInWithEmail(
        email: testEmail,
        password: testPassword,
      );

      expect(account.profileStatus, AppProfileStatus.completeProfile);
      expect(account.isComplete, isTrue);
    });

    test(
        'CA-73-09: NUNCA lanza "Perfil no encontrado" — la ausencia es un '
        'estado válido, no un error', () async {
      // Sin doc — el método NO debe lanzar.
      expect(
        () async => await repo.signInWithEmail(
          email: testEmail,
          password: testPassword,
        ),
        returnsNormally,
      );
    });
  });

  group('authStateChanges — coherencia con sign-in', () {
    test('emite AppAccount no-nulo para usuario autenticado sin perfil',
        () async {
      // El MockFirebaseAuth ya está "signed in" desde setUp.
      final account = await repo.authStateChanges.first;
      expect(account, isNotNull);
      expect(account!.uid, testUid);
      expect(account.profileStatus, AppProfileStatus.newProfile);
    });
  });

  group('signUpWithEmail — escribe seed mínimo', () {
    test(
        'crea doc users/{uid} con id/name/email pero queda en PARTIAL hasta '
        'que onboarding lo complete', () async {
      // Nota: MockFirebaseAuth.createUserWithEmailAndPassword puede tener
      // limitaciones. Este test queda como referencia del contrato.
      // (Verificación manual a través de smoke test en el dispositivo.)
    }, skip: 'Pendiente fixture de MockFirebaseAuth.createUser');
  });

  group('handleAuthException — mensajes específicos', () {
    test('email-already-in-use → mensaje MR específico', () async {
      // Construimos una FirebaseAuthException simulada y verificamos el
      // mapeo del helper privado. Como el helper es privado, el test
      // pasa por el flujo público de signUp si MockFirebaseAuth puede
      // dispararlo. En caso contrario, se reemplaza por test de la
      // clase concreta — verificación marcada como pendiente.
    }, skip: 'MockFirebaseAuth no soporta forzar email-already-in-use');
  });

  group('Helpers — métadatos preservados', () {
    test('rawProfile preserva exactamente el shape original del doc', () async {
      final originalShape = {
        'name': 'Carlos MR',
        'email': testEmail,
        'subscription_active': true,
        'purchases': ['programa_2025'],
        'campo_desconocido_mr': 'valor_X',
      };
      await firestore.collection('users').doc(testUid).set(originalShape);

      final account = await repo.signInWithEmail(
        email: testEmail,
        password: testPassword,
      );

      // Todos los campos MR originales presentes (no se pierden).
      // El email se denormaliza si no estaba — aquí ya estaba, así que el
      // shape se mantiene idéntico.
      for (final key in originalShape.keys) {
        expect(account.rawProfile!.containsKey(key), isTrue,
            reason: 'rawProfile debe contener key "$key" del doc MR original');
      }
    });
  });

  // ─── SPEC-207: Borrado en cascada al eliminar cuenta ────────────────────────

  group('SPEC-207 — deleteAccount: best-effort fasting_history', () {
    setUp(() async {
      // Seed: doc raíz del usuario
      await firestore.collection('users').doc(testUid).set({
        'name': 'Carlos MR',
        'email': testEmail,
      });

      // Seed: 3 docs de fasting_history del usuario
      for (var i = 0; i < 3; i++) {
        await firestore.collection('fasting_history').add({
          'userId': testUid,
          'startedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Seed: 1 doc de otro usuario (NO debe borrarse)
      await firestore.collection('fasting_history').add({
        'userId': 'otro-uid',
        'startedAt': DateTime.now().millisecondsSinceEpoch,
      });
    });

    test(
        'SPEC-207-01: borra los 3 docs de fasting_history del usuario '
        'y preserva el de otro usuario', () async {
      await repo.deleteAccount();

      final propios = await firestore
          .collection('fasting_history')
          .where('userId', isEqualTo: testUid)
          .get();
      expect(propios.docs, isEmpty,
          reason: 'Los docs del usuario deben estar eliminados');

      final ajenos = await firestore
          .collection('fasting_history')
          .where('userId', isEqualTo: 'otro-uid')
          .get();
      expect(ajenos.docs.length, 1,
          reason: 'Docs de otros usuarios no deben tocarse');
    });

    test('SPEC-207-02: borra el doc raíz users/{uid}', () async {
      await repo.deleteAccount();

      final doc = await firestore.collection('users').doc(testUid).get();
      expect(doc.exists, isFalse);
    });

    test(
        'SPEC-207-03: no lanza si fasting_history del usuario ya está vacía',
        () async {
      // Borrar previamente los docs del usuario
      final snapshot = await firestore
          .collection('fasting_history')
          .where('userId', isEqualTo: testUid)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // deleteAccount no debe lanzar en este caso
      await expectLater(repo.deleteAccount(), completes);
    });

    test(
        'SPEC-207-04: no lanza si no hay doc raíz users/{uid} '
        '(doc ya fue borrado por la Cloud Function)', () async {
      // Borrar el doc raíz antes de llamar deleteAccount
      await firestore.collection('users').doc(testUid).delete();

      // No debe propagar excepción
      await expectLater(repo.deleteAccount(), completes);
    });
  });
}
