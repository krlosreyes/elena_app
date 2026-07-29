// SPEC-73: contrato de identidad post-autenticación.
//
// AuthRepository NUNCA lanza Exception por ausencia o shape del
// documento `users/{uid}`. La ausencia se modela vía
// `AppAccount.profileStatus == newProfile`, el shape inválido vía
// `partialProfile`. Sólo lanza para errores reales de credenciales
// (wrong-password, user-not-found, network) o de plataforma.

import 'package:elena_app/src/features/auth/domain/app_account.dart';

/// Firebase exige una autenticación reciente para operaciones sensibles
/// (`requires-recent-login`). Se lanza tipada, y no como una `Exception`
/// con mensaje suelto, porque la UI tiene que poder DISTINGUIRLA para
/// ofrecer el diálogo de contraseña en vez de limitarse a mostrar texto.
///
/// Antes del 27-jul-2026 el repositorio lanzaba
/// `Exception('Por seguridad, tu sesión es muy antigua. Cierra sesión,
/// vuelve a iniciar sesión…')`. La pantalla no tenía forma fiable de
/// reconocer ese caso —habría tenido que comparar cadenas— así que el
/// único remedio ofrecido al usuario era salir y volver a entrar a mano.
/// Para App Store 5.1.1(v), que exige que borrar la cuenta sea sencillo,
/// eso no basta.
class ReauthRequiredException implements Exception {
  const ReauthRequiredException({this.email});

  /// Email de la cuenta, para prellenar el diálogo si se conoce.
  final String? email;

  @override
  String toString() =>
      'Por seguridad hace falta que confirmes tu identidad antes de '
      'continuar. Tus datos siguen intactos.';
}

/// Proveedores de identidad que Elena soporta.
///
/// Existe para que la UI no tenga que comparar los literales de Firebase
/// (`'password'`, `'google.com'`). Importa sobre todo en el borrado de
/// cuenta: la reautenticación es distinta según con qué entró el usuario,
/// y pedirle una contraseña a alguien que solo usó Google lo dejaría sin
/// poder borrar su cuenta.
enum AuthProviderKind {
  password,
  google;

  /// Traduce el `providerId` de Firebase. Devuelve `null` para
  /// proveedores que Elena no ofrece (Apple, Facebook…): quien reciba
  /// `null` debe tratarlo como "no sé reautenticar esto" y no asumir
  /// contraseña.
  static AuthProviderKind? fromProviderId(String providerId) =>
      switch (providerId) {
        'password' => AuthProviderKind.password,
        'google.com' => AuthProviderKind.google,
        _ => null,
      };
}

/// El email de la cuenta de Google ya existe en Elena registrado con
/// contraseña.
///
/// Firebase lo señala como `account-exists-with-different-credential`. Es
/// el caso más común y confuso del login social: la persona se registró
/// con `alguien@gmail.com` y contraseña hace meses, hoy pulsa "Continuar
/// con Google" y —sin este manejo— recibe un error críptico que la deja
/// fuera de su propia cuenta.
///
/// Se lanza tipada para que la pantalla pueda ofrecer lo único que
/// resuelve de verdad: pedir la contraseña una vez y VINCULAR ambos
/// métodos al mismo usuario. Crear una segunda cuenta con el mismo correo
/// no es opción — partiría su historial en dos.
class GoogleAccountNeedsLinkingException implements Exception {
  const GoogleAccountNeedsLinkingException({
    required this.email,
    required this.pendingCredentialToken,
  });

  /// Email en conflicto. Se muestra para que entienda de qué cuenta se
  /// habla.
  final String email;

  /// Identificador opaco de la credencial de Google pendiente, guardada
  /// en el repositorio a la espera de la contraseña.
  ///
  /// No viaja la credencial en sí: es material sensible y no tiene por
  /// qué pasar por la capa de presentación.
  final String pendingCredentialToken;

  @override
  String toString() =>
      'Ya tienes una cuenta con este correo. Confirma tu contraseña una '
      'vez y dejamos las dos formas de entrar unidas.';
}

abstract class AuthRepository {
  /// Stream del estado de autenticación.
  ///
  /// Emite `null` SÓLO cuando no hay sesión activa en Firebase Auth.
  /// Para cualquier usuario autenticado emite un `AppAccount` no-nulo,
  /// anexando su `profileStatus` (NEW / PARTIAL / COMPLETE).
  Stream<AppAccount?> get authStateChanges;

  /// Registra un usuario con email/password y crea el documento de
  /// perfil mínimo en Firestore.
  ///
  /// El AppAccount retornado siempre tiene `profileStatus = newProfile`
  /// porque acabamos de crear la cuenta — el OnboardingController es
  /// quien completa los campos.
  Future<AppAccount> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Valida credenciales contra Firebase Auth y clasifica el estado de
  /// perfil del usuario.
  ///
  /// Retorna `AppAccount` con uno de tres `profileStatus`:
  /// - `newProfile`: doc `users/{uid}` no existe.
  /// - `partialProfile`: doc existe pero no cumple invariantes mínimos.
  /// - `completeProfile`: doc cumple invariantes.
  ///
  /// NUNCA lanza por ausencia de perfil. Sólo por credenciales
  /// inválidas (wrong-password, user-not-found, etc.).
  Future<AppAccount> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  /// SPEC-73 §RF-73-09: dispara email transaccional con magic link para
  /// usuarios MR que necesitan establecer contraseña por primera vez.
  Future<void> sendSignInLinkToEmail(String email);

  /// Valida el magic link y autentica al usuario. Después de esta
  /// llamada el usuario está autenticado pero típicamente sin password
  /// — el flujo de UI debe forzar `setPassword` inmediatamente.
  Future<AppAccount> signInWithEmailLink({
    required String email,
    required String emailLink,
  });

  /// Establece (o reemplaza) la contraseña del usuario autenticado.
  /// Sólo válido inmediatamente después de `signInWithEmailLink`.
  Future<void> setPassword(String newPassword);

  /// Vuelve a autenticar al usuario actual con su contraseña, para
  /// refrescar la "sesión reciente" que Firebase exige antes de borrar
  /// la cuenta.
  ///
  /// Lanza `Exception` con mensaje presentable si la contraseña es
  /// incorrecta o si la cuenta no tiene contraseña — caso posible en
  /// usuarios que entraron por magic link y nunca pasaron por
  /// [setPassword]. Para ellos la vía es restablecer la contraseña con
  /// [sendPasswordResetEmail]; reautenticar con el propio magic link
  /// exigiría rehacer todo ese flujo y queda fuera de alcance.
  Future<void> reauthenticateWithPassword(String password);

  // ── Google ────────────────────────────────────────────────────────────

  /// Entra (o registra) con Google.
  ///
  /// Devuelve `null` si la persona cierra el selector de cuentas sin
  /// elegir ninguna. Cancelar no es un error: no debe pintar mensaje
  /// rojo ni registrarse como fallo.
  ///
  /// Lanza [GoogleAccountNeedsLinkingException] si el email de esa cuenta
  /// de Google ya existe en Elena registrado con contraseña. La UI debe
  /// pedir la contraseña y llamar a [linkPendingGoogleCredential].
  Future<AppAccount?> signInWithGoogle();

  /// Cierra la vinculación pendiente que dejó
  /// [GoogleAccountNeedsLinkingException]: comprueba la contraseña y une
  /// Google al MISMO usuario.
  ///
  /// A partir de aquí la persona puede entrar de las dos formas, con un
  /// único uid y un único historial. Es la razón de ser de todo el
  /// mecanismo: sin esto tendríamos dos cuentas con el mismo correo y los
  /// datos partidos.
  ///
  /// [pendingCredentialToken] es el que viajó en la excepción.
  Future<AppAccount> linkPendingGoogleCredential({
    required String pendingCredentialToken,
    required String password,
  });

  /// Con qué proveedores puede entrar el usuario actual.
  ///
  /// Vacío si no hay sesión. Un usuario vinculado devuelve los dos.
  ///
  /// Lo consume el borrado de cuenta para decidir CÓMO reautenticar —
  /// ver [reauthenticateWithGoogle].
  List<AuthProviderKind> currentUserProviders();

  /// Reautentica al usuario actual reabriendo el flujo de Google.
  ///
  /// Existe porque [reauthenticateWithPassword] no sirve para quien entró
  /// solo con Google: no tiene contraseña que confirmar. Sin esta vía,
  /// un usuario de Google que topa con `requires-recent-login` al borrar
  /// su cuenta se quedaría ante un diálogo pidiéndole algo que no existe
  /// — es decir, sin poder borrar su cuenta, que es justo el bloqueante
  /// de App Store 5.1.1(v).
  ///
  /// Devuelve `false` si cancela el selector. No lanza en ese caso.
  Future<bool> reauthenticateWithGoogle();

  /// Elimina la cuenta de Firebase Auth.
  ///
  /// Lanza [ReauthRequiredException] si Firebase pide sesión reciente.
  /// En ese caso NO se ha borrado nada: la UI debe reautenticar por la
  /// vía que corresponda al proveedor ([currentUserProviders]) y
  /// reintentar.
  Future<void> deleteAccount();

  /// FIRE-01 (auditoría técnica 21-jul): lee el custom claim
  /// `trialExpiresAt` (epoch millis) fijado server-side por la Cloud
  /// Function `onUserCreated` (SEC-02) — inmune a que el usuario atrase
  /// el reloj del dispositivo o reinstale la app (lo que sí borra el
  /// high-water-mark local que usa `billing_providers.dart` como único
  /// mecanismo hasta este fix).
  ///
  /// Devuelve `null` si no hay usuario autenticado, si el claim todavía
  /// no existe (cuentas creadas antes de este trigger, o el token recién
  /// emitido en el signup que aún no lo incluye — ver nota en
  /// `functions/src/index.ts`), o si la lectura falla. El caller debe
  /// tratar `null` como "usar el cálculo local de respaldo", nunca como
  /// "trial vencido".
  ///
  /// `forceRefresh: true` fuerza a pedir un token nuevo al servidor en
  /// vez de reusar el cacheado — necesario justo después del signup,
  /// donde el primer token emitido puede no incluir el claim todavía.
  Future<int?> getTrialExpiresAtClaimMillis({bool forceRefresh = false});
}
