// SPEC-73: implementación Firebase del AuthRepository.
//
// Diferencias vs versión previa:
// - `signInWithEmail` retorna AppAccount y NUNCA lanza por ausencia de
//   perfil. La asunción anterior de que un sign-in válido implicaba un
//   doc `users/{uid}` con shape estricto rompía el flujo de usuarios
//   provenientes de metamorfosisreal.com (BD compartida, mismo
//   proyecto Firebase, distinto shape de perfil).
// - `authStateChanges` emite AppAccount no-nulo para cualquier usuario
//   autenticado. El null queda reservado a "no autenticado".
// - Se eliminó el método `isUserOnboarded`. El router lee
//   `AppAccount.profileStatus` directamente, evitando una lectura
//   extra de Firestore por cada cambio de ruta.
// - Nuevos métodos para magic link (RF-73-09): `sendSignInLinkToEmail`,
//   `signInWithEmailLink`, `setPassword`.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:elena_app/firebase_options.dart';
import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/shared/domain/validators/user_profile_validator.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AppAccount?> get authStateChanges =>
      _auth.authStateChanges().asyncMap<AppAccount?>((firebaseUser) async {
        if (firebaseUser == null) return null;
        return _buildAccount(firebaseUser);
      });

  @override
  Future<AppAccount> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      // Seed mínimo: id + name + email. NO escribe age/weight/height
      // porque el OnboardingController los completará. El doc queda en
      // estado PARTIAL inmediatamente y el router lo redirige a
      // /onboarding.
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': name,
        'email': email,
      }, SetOptions(merge: true));
      return AppAccount(
        uid: user.uid,
        email: email,
        displayName: name,
        profileStatus: AppProfileStatus.partialProfile,
        rawProfile: {'id': user.uid, 'name': name, 'email': email},
        createdAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<AppAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _buildAccount(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // SPEC-73 §RF-73-09: magic link.
  //
  // ActionCodeSettings.url debe coincidir con el dominio autorizado en
  // Firebase Console > Authentication > Authorized domains. El handler
  // del deep link en el cliente extrae el link y llama
  // `signInWithEmailLink`.
  //
  // ARCH-06 (auditoría 2026-07-11): antes el dominio venía hardcodeado
  // como literal ('elena-app-2026-v1.firebaseapp.com'), sin diferenciar
  // entorno y desincronizado de firebase_options.dart si el proyecto de
  // Firebase cambiara. Se deriva ahora de
  // `DefaultFirebaseOptions.web.authDomain` — la MISMA fuente única de
  // verdad que ya usa el resto de la app (regenerada automáticamente por
  // `flutterfire configure`). Se usa el config `web` explícitamente
  // porque `authDomain` es un campo específico del flujo de Firebase Auth
  // en navegador (el link del magic link siempre abre en un webview/
  // browser, sin importar si quien lo solicitó fue la app iOS o Android).
  @override
  Future<void> sendSignInLinkToEmail(String email) async {
    try {
      final authDomain = DefaultFirebaseOptions.web.authDomain;
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://$authDomain/set-password',
          handleCodeInApp: true,
          androidPackageName: 'com.metamorfosis.elena.elena_app',
          androidInstallApp: true,
          androidMinimumVersion: '1',
          iOSBundleId: 'com.metamorfosis.elena.elenaApp',
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<AppAccount> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        throw Exception('Link de acceso inválido o expirado.');
      }
      final credential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      return _buildAccount(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> setPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(
          'Sesión no encontrada. Vuelve a abrir el link del email.');
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ORDEN DEL BORRADO: Auth PRIMERO. Firestore lo limpia el servidor.
  //
  // 27-jul-2026, verificado borrando una cuenta real en el Simulador. El
  // orden anterior —Firestore primero, Auth al final— produce PÉRDIDA DE
  // DATOS SIN BORRADO:
  //
  //   1-3. borra subcolecciones, doc raíz y `fasting_history` legacy
  //   4.   `user.delete()` lanza `requires-recent-login`
  //   5.   signOut: inalcanzable, el paso 4 ya hizo `throw`
  //
  // Resultado observado: datos destruidos, cuenta de Auth viva, usuario
  // expulsado a /login. Una cuenta zombi. Y como `requires-recent-login`
  // salta a los pocos minutos de la última autenticación, ese es el camino
  // NORMAL de cualquiera que borre su cuenta, no un caso raro.
  //
  // POR QUÉ EL ORDEN ANTERIOR (SPEC-248b) PARTÍA DE UNA PREMISA FALSA
  // ------------------------------------------------------------------
  // Su razonamiento era: "tras `user.delete()` el token queda inválido y
  // las reglas rechazan cualquier write, así que las subcolecciones nunca
  // se borraban desde el cliente". La observación es correcta. La
  // conclusión no: **el cliente no tiene que borrarlas**.
  //
  // `onUserDeleted` (functions/src/index.ts) las borra en servidor con el
  // Admin SDK, y cubre estrictamente MÁS que el cliente:
  //   · sus 16 subcolecciones incluyen `badges`, que el cliente ni siquiera
  //     puede tocar porque `firestore.rules` la deja allow-create-only;
  //   · borra también el doc raíz `users/{uid}`;
  //   · y la colección plana `fasting_history` legacy.
  //
  // Es decir: los pasos 1-3 del cliente eran REDUNDANTES, y el precio de
  // ejecutarlos antes de saber si el borrado es siquiera posible era
  // destruir los datos de quien no puede completarlo. Con el orden
  // invertido, un fallo en Auth no destruye nada: el usuario conserva su
  // cuenta intacta y puede reintentar.
  //
  // DEPENDENCIA OPERATIVA: esto exige que `onUserDeleted` esté DESPLEGADA.
  // Si no lo está, el borrado deja Firestore huérfano. Comprobar con
  // `firebase functions:list` antes de publicar.
  //
  // Se conserva el `.timeout()` por llamada del fix del 18-jul: el
  // `.timeout(25s)` de `ProfileController.deleteAccount()` no cancela el
  // Future real, solo deja de esperarlo, así que un `await` colgado
  // (patrón offline-first, ver `feedback_offline_first_pattern.md`)
  // dejaría el método sin terminar nunca.
  @override
  // ── Google ─────────────────────────────────────────────────────────────
  //
  // Notas de la API 7.x, que rompió todo lo anterior:
  //   - `GoogleSignIn()` ya no se construye: es `GoogleSignIn.instance`.
  //   - Hay que llamar `initialize()` UNA vez antes de nada. Se hace
  //     perezosamente aquí (`_ensureGoogleInitialized`) en vez de en
  //     main.dart para no meter latencia ni un fallo de red en el
  //     arranque de una app que la mayoría de días no usa Google.
  //   - `signIn()` pasó a `authenticate()`, y cancelar LANZA en vez de
  //     devolver null.
  //   - `accessToken` desapareció. Para Firebase basta el `idToken`.
  //
  // En iOS no se pasa `clientId`: el plugin lo lee de
  // GoogleService-Info.plist. Pasarlo a mano sería un tercer sitio donde
  // vive el mismo dato.

  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  /// Credenciales de Google a la espera de que el usuario confirme su
  /// contraseña para vincularlas (ver [GoogleAccountNeedsLinkingException]).
  ///
  /// Vive en memoria y solo dentro del repositorio: una credencial de
  /// OAuth no tiene por qué pasar por la capa de presentación, así que a
  /// la UI solo le viaja un token opaco con el que volver a pedirla.
  final Map<String, AuthCredential> _pendingGoogleCredentials = {};

  /// True si el usuario canceló el selector de cuentas.
  ///
  /// Cancelar NO es un error: no debe pintar mensaje rojo. En la 7.x la
  /// cancelación llega como excepción, así que hay que distinguirla del
  /// fallo real.
  bool _isGoogleCancellation(Object e) =>
      e is GoogleSignInException &&
      e.code == GoogleSignInExceptionCode.canceled;

  /// Abre el selector de Google y devuelve la credencial para Firebase.
  /// `null` si el usuario cancela.
  Future<AuthCredential?> _obtenerCredencialGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final cuenta = await GoogleSignIn.instance.authenticate();
      final idToken = cuenta.authentication.idToken;
      if (idToken == null) {
        throw Exception(
          'Google no devolvió la identificación de tu cuenta. Inténtalo '
          'de nuevo en un momento.',
        );
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } catch (e) {
      if (_isGoogleCancellation(e)) return null;
      rethrow;
    }
  }

  @override
  Future<AppAccount?> signInWithGoogle() async {
    final credencial = await _obtenerCredencialGoogle();
    if (credencial == null) return null;

    try {
      final resultado =
          await _auth.signInWithCredential(credencial).timeout(_kDocTimeout);
      return _buildAccount(resultado.user!);
    } on TimeoutException {
      throw Exception(
        'La conexión está tardando más de lo esperado. Verifica tu red e '
        'inténtalo de nuevo.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        // Ese correo ya existe en Elena con contraseña. Guardamos la
        // credencial y dejamos que la UI pida la contraseña para VINCULAR
        // — crear una segunda cuenta con el mismo email partiría el
        // historial de esa persona en dos.
        final email = e.email;
        final pendiente = e.credential;
        if (email == null || pendiente == null) {
          throw Exception(
            'Ya existe una cuenta con ese correo, pero no pudimos '
            'identificarla. Entra con tu contraseña.',
          );
        }
        final token = 'google:$email:${DateTime.now().microsecondsSinceEpoch}';
        _pendingGoogleCredentials[token] = pendiente;
        throw GoogleAccountNeedsLinkingException(
          email: email,
          pendingCredentialToken: token,
        );
      }
      if (e.code == 'operation-not-allowed') {
        // Google no está habilitado como proveedor en Firebase Console.
        // Mensaje explícito porque el error crudo es indescifrable y es
        // el fallo más probable la primera vez que se despliega esto.
        throw Exception(
          'El ingreso con Google no está disponible ahora mismo. Entra '
          'con tu correo y contraseña.',
        );
      }
      throw _handleAuthException(e);
    }
  }

  @override
  Future<AppAccount> linkPendingGoogleCredential({
    required String pendingCredentialToken,
    required String password,
  }) async {
    final pendiente = _pendingGoogleCredentials[pendingCredentialToken];
    if (pendiente == null) {
      throw Exception(
        'La confirmación caducó. Vuelve a tocar "Continuar con Google".',
      );
    }

    final email = pendingCredentialToken.split(':').elementAtOrNull(1);
    if (email == null || email.isEmpty) {
      throw Exception('No pudimos identificar la cuenta. Inténtalo de nuevo.');
    }

    try {
      // 1. Entrar con la contraseña: es lo que demuestra que esa cuenta
      //    es suya. Sin este paso, cualquiera con una cuenta de Google
      //    del mismo correo podría apropiarse de la de Elena.
      final resultado = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_kDocTimeout);

      // 2. Unir Google al MISMO usuario. A partir de aquí entra como
      //    quiera, con un único uid.
      await resultado.user!.linkWithCredential(pendiente).timeout(_kDocTimeout);

      _pendingGoogleCredentials.remove(pendingCredentialToken);
      return _buildAccount(_auth.currentUser!);
    } on TimeoutException {
      throw Exception(
        'La conexión está tardando más de lo esperado. No se vinculó '
        'nada; inténtalo de nuevo.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked' ||
          e.code == 'credential-already-in-use') {
        // Ya estaban unidas (doble toque, o vinculado desde otro
        // dispositivo). El objetivo está cumplido: no es un error.
        _pendingGoogleCredentials.remove(pendingCredentialToken);
        return _buildAccount(_auth.currentUser!);
      }
      throw _handleAuthException(e);
    }
  }

  @override
  List<AuthProviderKind> currentUserProviders() {
    final user = _auth.currentUser;
    if (user == null) return const [];
    return user.providerData
        .map((info) => AuthProviderKind.fromProviderId(info.providerId))
        .whereType<AuthProviderKind>()
        .toList();
  }

  @override
  Future<bool> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay sesión activa. Vuelve a iniciar sesión.');
    }

    final credencial = await _obtenerCredencialGoogle();
    if (credencial == null) return false;

    try {
      await user.reauthenticateWithCredential(credencial).timeout(_kDocTimeout);
      return true;
    } on TimeoutException {
      throw Exception(
        'La confirmación está tardando más de lo esperado. Verifica tu '
        'conexión e inténtalo de nuevo.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-mismatch') {
        throw Exception(
          'Esa cuenta de Google no es la de esta sesión. Elige la misma '
          'con la que entraste.',
        );
      }
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay sesión activa. Vuelve a iniciar sesión.');
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception(
        'Esta cuenta no tiene email asociado, así que no se puede '
        'confirmar la identidad por contraseña.',
      );
    }

    try {
      await user
          .reauthenticateWithCredential(
            EmailAuthProvider.credential(email: email, password: password),
          )
          .timeout(_kDocTimeout);
    } on TimeoutException {
      throw Exception(
        'La confirmación está tardando más de lo esperado. Verifica tu '
        'conexión e inténtalo de nuevo.',
      );
    } on FirebaseAuthException catch (e) {
      // Las cuentas creadas por magic link que nunca pasaron por
      // `setPassword` no tienen contraseña que validar: Firebase
      // responde igual que ante una contraseña equivocada. No hay forma
      // de distinguir los dos casos desde aquí, así que el mensaje
      // menciona la salida que sirve para ambos.
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        throw Exception(
          'Contraseña incorrecta. Si entraste con un enlace por email y '
          'nunca creaste una contraseña, usa "¿Olvidaste tu contraseña?" '
          'para establecerla.',
        );
      }
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Eliminar la cuenta de Firebase Auth. Es lo único que puede fallar
    //    de forma recuperable, así que va primero: si falla, no se ha
    //    tocado un solo dato del usuario.
    try {
      await user.delete().timeout(_kDocTimeout);
    } on TimeoutException {
      throw Exception(
        'La eliminación está tardando más de lo esperado. Verifica tu '
        'conexión e inténtalo de nuevo. No se borró nada.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Tipada a propósito: la pantalla la reconoce y ofrece el
        // diálogo de contraseña. Ver `ReauthRequiredException`.
        throw ReauthRequiredException(email: user.email);
      }
      throw _handleAuthException(e);
    } catch (_) {
      throw Exception('Error técnico al eliminar la cuenta de autenticación.');
    }

    // 2. El borrado en cascada de Firestore lo hace `onUserDeleted` en
    //    servidor. Aquí ya no se puede: el token acaba de invalidarse.

    // 3. Cerrar sesión local para limpiar caches de Firebase Auth.
    try {
      await _auth.signOut().timeout(_kDocTimeout);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Duración máxima para una llamada de red individual (`.get()`,
  /// `batch.commit()`, borrado de doc, `user.delete()`, `signOut()`) dentro
  /// de `deleteAccount()`. Mismo criterio que `_buildAccount` (6s) — más
  /// margen porque un `batch.commit()` de hasta 400 docs puede pesar más
  /// que una lectura simple de un doc.
  static const Duration _kDocTimeout = Duration(seconds: 8);

  /// Lee `users/{uid}` y construye el AppAccount clasificando el shape.
  ///
  /// SPEC-73 §CA-73-01/02/03 — 3 ramas:
  /// - doc no existe → NEW_PROFILE, rawProfile = null
  /// - doc existe pero incompleto → PARTIAL_PROFILE, rawProfile = doc
  /// - doc existe y completo → COMPLETE_PROFILE, rawProfile = doc
  Future<AppAccount> _buildAccount(User firebaseUser) async {
    final email = firebaseUser.email ?? '';
    final displayName = firebaseUser.displayName;
    final uid = firebaseUser.uid;
    final createdAt = firebaseUser.metadata.creationTime;

    // SPEC-206: `authStateChanges` hace asyncMap sobre `_buildAccount`. Si este
    // `.get()` se CUELGA (puede pasar tras la secuencia offline→reconexión→
    // logout→login), el stream nunca emite, `authState` queda en loading y el
    // router atrapa al usuario en /splash ("no permite el ingreso a la app").
    // El try/catch previo solo atrapaba errores, no un cuelgue. Blindaje:
    //   1. timeout sobre la lectura de servidor,
    //   2. fallback a SOLO caché local (un usuario existente tiene su doc en
    //      caché → se clasifica bien aunque el servidor no responda).
    Map<String, dynamic>? rawProfile;
    try {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));
      rawProfile = snap.exists ? snap.data() : null;
    } catch (_) {
      try {
        final cached = await _firestore
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        rawProfile = cached.exists ? cached.data() : null;
      } catch (_) {
        // Sin servidor ni caché: tratamos como ausente. El router manda a
        // /onboarding; al recuperar red el authStateChanges re-emite y
        // re-clasifica.
        rawProfile = null;
      }
    }

    final AppProfileStatus status;
    if (rawProfile == null) {
      status = AppProfileStatus.newProfile;
    } else if (UserProfileValidator.isCompleteFromRaw(rawProfile)) {
      status = AppProfileStatus.completeProfile;
    } else {
      status = AppProfileStatus.partialProfile;
    }

    // Si el email no estaba denormalizado en el doc, lo añadimos.
    // Facilita queries cross-app y queries de admin sin abrir reglas.
    if (rawProfile != null && rawProfile['email'] == null) {
      // Best-effort, no bloqueamos el login si falla.
      _firestore.collection('users').doc(uid).set(
        {'email': email},
        SetOptions(merge: true),
      ).catchError((_) {});
    }

    return AppAccount(
      uid: uid,
      email: email,
      displayName: displayName ??
          (rawProfile?['name'] as String?) ??
          (rawProfile?['displayName'] as String?),
      profileStatus: status,
      rawProfile: rawProfile,
      createdAt: createdAt,
      // 29-jul: la foto la pone el proveedor (hoy solo Google) y Firebase
      // la expone aquí. Se prefiere la de Auth sobre la del doc porque
      // es la que el usuario acaba de ver al elegir su cuenta; el doc de
      // Firestore es el respaldo para cuentas MR que ya traían `photoUrl`.
      photoUrl: firebaseUser.photoURL ?? (rawProfile?['photoUrl'] as String?),
    );
  }

  // FIRE-01 (21-jul): ver doc completa en auth_repository.dart. El
  // `.timeout` usa la misma constante que el resto del archivo — esta
  // llamada es una lectura de token (`getIdTokenResult`), del mismo orden
  // de costo/latencia que las lecturas de doc que ya usan `_kDocTimeout`.
  @override
  Future<int?> getTrialExpiresAtClaimMillis({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final result =
          await user.getIdTokenResult(forceRefresh).timeout(_kDocTimeout);
      final claim = result.claims?['trialExpiresAt'];
      if (claim is int) return claim;
      if (claim is double) return claim.toInt();
      return null;
    } catch (_) {
      // Best-effort: el caller cae al cálculo local (HWM) como respaldo.
      return null;
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('Contraseña débil.');
      case 'email-already-in-use':
        // SPEC-73 §RF-73-08: mensaje específico que sugiere usar
        // sign-in en lugar de registro. El usuario MR llega aquí
        // cuando intenta "registrarse" con un email que ya existe en
        // la user-pool compartida.
        return Exception(
          'Ya tienes cuenta en Metamorfosis Real. '
          'Inicia sesión con tu contraseña.',
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Credenciales incorrectas.');
      case 'invalid-email':
        return Exception('Email inválido.');
      case 'user-disabled':
        return Exception('Esta cuenta está suspendida.');
      case 'too-many-requests':
        return Exception(
          'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
        );
      case 'network-request-failed':
        return Exception('Sin conexión. Verifica tu internet.');
      default:
        return Exception('Error de autenticación: ${e.code}.');
    }
  }
}
