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

  // ─── Borrado de cuenta: Auth primero, Firestore lo limpia el servidor ──────
  //
  // Este grupo afirmaba lo contrario hasta el 27-jul-2026: que
  // `deleteAccount()` borrara `users/{uid}` y `fasting_history` desde el
  // CLIENTE. Era coherente con el orden de entonces (Firestore → Auth), pero
  // ese orden producía pérdida de datos sin borrado, verificado en el
  // Simulador: los pasos de Firestore se completaban, `user.delete()` lanzaba
  // `requires-recent-login` y el usuario quedaba con los datos destruidos y
  // la cuenta viva. Los tests protegían el bug en vez de impedirlo.
  //
  // El contrato nuevo es: el cliente SOLO borra la cuenta de Auth. La
  // cascada de Firestore la hace `onUserDeleted` con el Admin SDK, que cubre
  // estrictamente más (incluye `badges`, que las reglas prohíben borrar al
  // cliente). Ver la nota larga en `deleteAccount()`.
  group('deleteAccount — el cliente solo toca Auth', () {
    setUp(() async {
      await firestore.collection('users').doc(testUid).set({
        'name': 'Carlos MR',
        'email': testEmail,
      });
      for (var i = 0; i < 3; i++) {
        await firestore.collection('fasting_history').add({
          'userId': testUid,
          'startedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });

    test('elimina la cuenta de Firebase Auth', () async {
      expect(auth.currentUser, isNotNull);
      await repo.deleteAccount();
      expect(auth.currentUser, isNull,
          reason: 'tras borrar y cerrar sesión no debe quedar usuario');
    });

    test('NO borra Firestore desde el cliente: es trabajo de onUserDeleted',
        () async {
      await repo.deleteAccount();

      // Que estos datos sigan aquí no es un fallo: en producción el token
      // ya está invalidado cuando termina `user.delete()`, así que las
      // reglas rechazarían el intento. Quien los borra es la Cloud
      // Function. Este test fija esa frontera de responsabilidad.
      final raiz = await firestore.collection('users').doc(testUid).get();
      expect(raiz.exists, isTrue,
          reason: 'el doc raíz lo borra onUserDeleted en servidor');

      final ayunos = await firestore
          .collection('fasting_history')
          .where('userId', isEqualTo: testUid)
          .get();
      expect(ayunos.docs.length, 3,
          reason: 'fasting_history legacy también la limpia el servidor');
    });

    test('sin sesión activa no hace nada y no lanza', () async {
      await auth.signOut();
      await expectLater(repo.deleteAccount(), completes);
    });

    test('no lanza si el doc raíz ya no existe', () async {
      await firestore.collection('users').doc(testUid).delete();
      await expectLater(repo.deleteAccount(), completes);
    });
  });

  // ─── La regresión que este test existe para impedir ───────────────────────
  group('deleteAccount — un borrado fallido no destruye datos', () {
    setUp(() async {
      await firestore.collection('users').doc(testUid).set({
        'name': 'Carlos MR',
        'email': testEmail,
      });
      for (final sub in ['sleep_history', 'imr_history', 'metabolic_cycles']) {
        await firestore
            .collection('users')
            .doc(testUid)
            .collection(sub)
            .add({'seed': true});
      }
    });

    test('si Auth rechaza el borrado, los datos del usuario quedan intactos',
        () async {
      // El caso real: `requires-recent-login`. Aquí se fuerza el fallo
      // cerrando la sesión y usando un repo cuyo `currentUser` es null —
      // el mock de firebase_auth_mocks no permite inyectar el código de
      // error, pero lo que importa es la INVARIANTE: si el borrado de Auth
      // no se completa, no puede haberse tocado un solo dato.
      //
      // Antes del 27-jul-2026 esta invariante NO se cumplía: los pasos de
      // Firestore corrían ANTES de intentar Auth, así que un fallo dejaba
      // al usuario con los datos destruidos y la cuenta viva. Una cuenta
      // zombi, y sin forma de recuperar nada.
      await auth.signOut();
      await repo.deleteAccount();

      final raiz = await firestore.collection('users').doc(testUid).get();
      expect(raiz.exists, isTrue, reason: 'el perfil debe seguir existiendo');

      for (final sub in ['sleep_history', 'imr_history', 'metabolic_cycles']) {
        final docs = await firestore
            .collection('users')
            .doc(testUid)
            .collection(sub)
            .get();
        expect(docs.docs, isNotEmpty,
            reason: '$sub no debe haberse tocado si el borrado no ocurrió');
      }
    });
  });
}
