# SPEC-250 — Timeout guard en eliminar cuenta + silenciar not-found esperado en IMR persistence

**Estado:** IMPLEMENTED (inc1 + inc2 + inc3)
**Versión:** 1.2
**Fecha:** 2026-07-08
**Tipo:** Bugfix
**Rama:** mvp-core-clean
**Relacionado:** [[SPEC-83]] (delete-account-fix original), [[SPEC-206]] (offline-first, causa raíz `await` cuelga offline), [[SPEC-248/248b]] (orden Firestore→Auth en delete), [[SPEC-82]] (canonical mirror IMR)

---

## 1. Contexto

Carlos reportó, probando en simulador de Xcode: al presionar "ELIMINAR CUENTA" en Perfil, la UI se quedó trabada (spinner indefinido). En el log de Flutter apareció, en paralelo:

```
⚠️ [imrPersistence] No se persistió imr.current: [cloud_firestore/not-found] Some requested document was not found.
```

Diagnóstico hecho en conversación con Carlos, sin tocar código hasta su autorización explícita.

## 2. Causa raíz

**Bug A — el bloqueo.** `ProfileController.deleteAccount()` (`profile_controller.dart`) hace un único `await` sobre `AuthRepository.deleteAccount()`. Esa implementación (`FirebaseAuthRepository.deleteAccount`, SPEC-248b) encadena secuencialmente:

1. Borrado de 15 subcolecciones bajo `users/{uid}` (cada una en loop paginado de `await .get()` + `await batch.commit()` hasta vaciarse).
2. Borrado del doc raíz `users/{uid}`.
3. Borrado de `fasting_history` legacy (query + batch delete).
4. `user.delete()` de Firebase Auth.
5. `signOut()`.

Son ~18+ llamadas a Firestore/Auth encadenadas, **ninguna con `.timeout()`**. Este es exactamente el patrón que SPEC-206 ya diagnosticó como causa raíz de "la app se cuelga offline": un `await` sobre un write/read de Firestore que, sin conectividad o con un hipo de red, no resuelve hasta reconectar (flutter#20871/#25415). SPEC-206 ya blindó `_buildAccount` (`firebase_auth_repository.dart`) con `.timeout(6s)` + fallback a caché, pero `deleteAccount()` quedó fuera de esa cobertura.

Con `isSaving` seteado en `true` al entrar y sin ningún límite de tiempo, si cualquiera de esos ~18 pasos se cuelga, el spinner del botón "ELIMINAR CUENTA" queda pegado indefinidamente — el síntoma reportado.

**Bug B — el `not-found` (síntoma correlacionado, no causante).** SPEC-248b invirtió el orden del borrado a propósito ("Firestore PRIMERO, Auth DESPUÉS") para que las reglas de Firestore (que exigen `request.auth` válido) permitan borrar las subcolecciones antes de invalidar el token. Efecto secundario: el doc raíz `users/{uid}` se borra en el paso 2, pero la sesión de Auth sigue válida hasta el paso 4. La navegación a `/login` solo ocurre cuando **toda** la cadena `deleteAccount()` resuelve (`ref.invalidate(authStateProvider)` en profile_controller.dart, tras el `await`), así que el Dashboard sigue montado durante ese intervalo — y con él, `imrPersistenceProvider` (imr_persistence_provider.dart, SPEC-82), que sigue vivo escuchando `imrProvider`.

Si había un write debounced (15s) pendiente, o el pulso de 10s recalculó el IMR durante esa ventana, el intento de escritura cae sobre `updateCurrentImr()` → `.update()` (no `.set(merge:true)`) contra un doc que el paso 2 ya borró → Firestore lanza `not-found`. Ya estaba atrapado en un `catchError` (no bloquea ni crashea), pero se logueaba como `warning`, generando ruido que complicó el diagnóstico inicial.

## 3. Solución implementada

**Fix A — timeout guard.** `ProfileController.deleteAccount()` ahora acepta un parámetro opcional `Duration timeout = const Duration(seconds: 25)` y envuelve el `await` con `.timeout(timeout)`:

```dart
Future<void> deleteAccount({
  Duration timeout = const Duration(seconds: 25),
}) async {
  state = state.copyWith(isSaving: true, errorMessage: null);
  try {
    await ref.read(authRepositoryProvider).deleteAccount().timeout(timeout);
    ref.invalidate(authStateProvider);
    state = state.copyWith(isSaving: false);
  } on TimeoutException {
    const message = 'La eliminación está tardando más de lo esperado. '
        'Verifica tu conexión e intenta de nuevo.';
    state = state.copyWith(isSaving: false, errorMessage: message);
    throw Exception(message);
  } catch (e) {
    state = state.copyWith(isSaving: false, errorMessage: e.toString());
    rethrow;
  }
}
```

Notas de diseño:

- `.timeout()` de Dart **no cancela** el `Future` original — solo deja de esperarlo. La cadena de borrado sigue corriendo en background hasta completar o fallar. Esto es seguro porque `deleteAccount()` ya está diseñado como *best-effort*: la Cloud Function `onUserDeleted` (SPEC-207/248) actúa como red de seguridad si el cliente no termina. Un timeout no deja el dato en peor estado del que el diseño ya contempla.
- 25s de presupuesto total (no por-paso) porque son ~18 llamadas secuenciales; un timeout por-llamada (como los 6s de `_buildAccount`, que es una sola lectura) sería demasiado ajustado para la suma.
- El `TimeoutException` crudo **no se relanza tal cual**: `profile_screen.dart` (línea ~1302) muestra `e.toString()` directo en un `SnackBar` sin leer `state.errorMessage`, y el `toString()` de `TimeoutException` es ilegible para el usuario final (`"TimeoutException after 0:00:25.000000: ..."`). Se lanza en su lugar una `Exception(mensaje)`, mismo patrón que `firebase_auth_repository.dart` ya usa para `requires-recent-login`.
- El parámetro `timeout` es inyectable (con default de 25s) para permitir tests rápidos sin esperar 25s reales.

**Fix B — silenciar el `not-found` esperado.** En `imr_persistence_provider.dart`, el `catchError` del write debounced ahora distingue el código de error:

```dart
.catchError((Object error, StackTrace stack) {
  if (error is FirebaseException && error.code == 'not-found') {
    AppLogger.info(
      '[imrPersistence] Doc ausente al escribir imr.current '
      '(probable borrado de cuenta en curso, SPEC-248b): $error',
    );
    return;
  }
  AppLogger.warning(
    '[imrPersistence] No se persistió imr.current: $error',
    error,
  );
});
```

`not-found` durante una eliminación de cuenta en curso es una carrera esperada por diseño (Fix B no cambia el comportamiento funcional, solo el nivel de log) — cualquier otro código de error (permisos, red genuina) sigue como `warning`.

## 4. Archivos modificados

| Archivo | Cambio |
|---|---|
| `lib/src/features/auth/application/profile_controller.dart` | `deleteAccount()` acepta `timeout` inyectable, envuelve el await con `.timeout()`, maneja `TimeoutException` con mensaje propio. Agregado `import 'dart:async'`. |
| `lib/src/core/engine/imr_persistence_provider.dart` | `catchError` distingue `FirebaseException.code == 'not-found'` (info) del resto (warning). Agregado `import 'package:cloud_firestore/cloud_firestore.dart'`. |

## 5. Archivos NO tocados

- `firebase_auth_repository.dart` — el orden Firestore→Auth de SPEC-248b se mantiene intacto; no se agregó timeout por-paso dentro de `deleteAccount()` (ver §7, alternativa considerada).
- `profile_screen.dart` — el `catch (e)` que muestra `e.toString()` en el SnackBar no se tocó; se resolvió la legibilidad del mensaje desde el controller (ver Fix A).
- Cloud Function `onUserDeleted` (SPEC-207/248) — sigue siendo la red de seguridad, sin cambios.

## 6. Criterios de aceptación

- [x] `deleteAccount()` tiene un límite de tiempo total (25s) y no puede quedar colgado indefinidamente.
- [x] Si el timeout se dispara, el usuario ve un mensaje legible en español, no un `toString()` crudo de `TimeoutException`.
- [x] El error `not-found` durante borrado de cuenta ya no se loguea como `warning` (se degrada a `info`).
- [x] Cualquier otro código de error en `updateCurrentImr` sigue logueándose como `warning` (sin regresión de visibilidad).
- [x] `flutter analyze` sin warnings nuevos. Verificado por Carlos 2026-07-08: 67 issues preexistentes (ninguno en los 2 archivos tocados por este SPEC ni en el test nuevo).
- [x] `flutter test` sin regresiones, con test nuevo cubriendo el timeout de `deleteAccount()`. Verificado 2026-07-08: 1639 passing / 3 skipped / 40 failing — los 40 son preexistentes en archivos no relacionados (`watch_action_handler`, `feature_gate_test` parámetro `isInTrial`, `AnalysisRange.d30/all`, `SuggestionType.simplify`, timeouts de `paywall_screen_test`, tests de `fasting_interval` con fake_cloud_firestore, etc.). `profile_controller_delete_account_test.dart` (3 tests nuevos) no aparece en la lista de fallos.
- [x] Validación manual en simulador de Xcode (inc1): reproducida por Carlos 2026-07-08 — reveló el bug de inc2 (spinner infinito en `ProfileScreen`, ver §7.1).
- [x] Validación manual en simulador de Xcode (inc2): reproducida por Carlos 2026-07-08 — el fix de inc2 solo cubría el camino de `TimeoutException`; `requires-recent-login` (camino de error genérico) seguía sin recovery. Reveló inc3 (ver §7.2).
- [ ] Validación manual en simulador de Xcode (inc3): reintentar "ELIMINAR CUENTA" (con sesión antigua, para forzar `requires-recent-login`, o esperando el timeout) y confirmar que la app redirige a `/login` en cualquiera de los dos casos, sin dejar `ProfileScreen` en spinner infinito. Pendiente.

**Nota de cobertura:** Fix B (silenciar `not-found`) no tiene test automatizado dedicado — requeriría simular el `Timer` de debounce de 15s de `imrPersistenceProvider` (`fakeAsync`, no presente hoy como dependencia del proyecto) para llegar al `catchError`. Es un cambio de severidad de log, no de comportamiento funcional; se verifica por lectura de código + `flutter analyze`. Mismo criterio que SPEC-83 aplicó para su Bug C (bug de integración Firebase, verificación manual en vez de mock).

## 7. Alternativa considerada y descartada

Agregar `.timeout()` individual a cada una de las ~18 llamadas dentro de `firebase_auth_repository.dart` (mismo patrón que `_buildAccount`) en vez de un timeout global en el controller. Más preciso para diagnosticar cuál paso específico cuelga, pero:

- Mayor superficie de cambio (18 call sites vs. 1).
- El límite global de 25s ya resuelve el síntoma reportado (UI trabada) sin necesitar saber cuál paso falló — la Cloud Function limpia el resto igual.
- Queda como mejora futura si este timeout global resulta insuficiente en device real (out of scope de este SPEC).

## 7.1. inc2 — spinner infinito en ProfileScreen tras el timeout (2026-07-08)

Validación manual en simulador de Xcode (Carlos reintentó "ELIMINAR CUENTA" tras el inc1): la pantalla Perfil quedó con un spinner de página completa, sin AppBar de acciones ni contenido — screenshot confirmado.

**Causa raíz.** `ProfileScreen.build` (`profile_screen.dart:86-95`) renderiza:

```dart
body: userAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('Error: $e')),
  data: (user) {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _ProfileBody(user: user);
  },
),
```

`userAsync` es `currentUserStreamProvider` (`shared/providers/user_provider.dart`), que emite `null` en tres casos: sin cuenta, perfil incompleto, o — el relevante aquí — el stream `watchProfile(uid)` (listener vivo de Firestore) emite `null` porque el doc ya no existe.

El paso 2 de `FirebaseAuthRepository.deleteAccount` (SPEC-248b) borra `users/{uid}` temprano y rápido. `currentUserStreamProvider` reacciona a eso **al instante** vía su listener de Firestore. Pero `authStateProvider` — de donde `ProfileScreen` obtendría la señal para dejar de existir vía el router — es un stream de `FirebaseAuth.authStateChanges()` que NO se re-evalúa por cambios en Firestore; solo se refresca cuando `ref.invalidate(authStateProvider)` se llama explícitamente, algo que en el código (antes de inc2) solo pasaba en el camino exitoso de `deleteAccount()`, DESPUÉS de que los ~18 pasos completos resuelven.

Si el paso lento es justo el último (`user.delete()` de Firebase Auth, paso 4) — el caso más probable dado que es la única llamada de un SDK distinto (`firebase_auth`, no `cloud_firestore`) en toda la cadena — entonces: el doc ya está borrado (`user == null` para siempre), pero `authStateProvider` sigue reportando la cuenta como completa indefinidamente. El fix del timeout (Fix A, inc1) libera `isSaving` a los 25s, pero eso solo desbloquea el spinner del **botón**; el spinner del **body** de `ProfileScreen` es independiente y no tenía ninguna salida.

**Fix.** En el bloque `on TimeoutException` de `ProfileController.deleteAccount()`, además de liberar `isSaving`, se agrega:

```dart
try {
  await ref.read(authRepositoryProvider).signOut();
} catch (_) {
  // Best-effort.
}
ref.invalidate(authStateProvider);
```

`signOut()` termina la sesión local de Firebase Auth (no intenta borrar nada de nuevo). Esto hace que `authStateChanges()` emita `null`, el router redirige a `/login`, y `ProfileScreen` se desmonta — cerrando el spinner infinito. Es seguro porque:

- Si el paso 4 (Auth) sí completó en background mientras esperábamos, este `signOut()` es redundante e inofensivo.
- Si no completó, la cuenta de Auth queda residual sin doc de Firestore — mismo riesgo que SPEC-83 ya documentó y aceptó para el caso `requires-recent-login`, cubierto por la Cloud Function `onUserDeleted` (SPEC-207/248) si el borrado de Auth eventualmente se completa en background.

Test agregado: `profile_controller_delete_account_test.dart` — nuevo caso verifica que `signOutCalled` sea `true` tras el timeout.

## 7.2. inc3 — el recovery de inc2 estaba mal alcanzado: cualquier error, no solo timeout (2026-07-08)

Carlos reprodujo el mismo spinner infinito de `ProfileScreen` una TERCERA vez, ahora con un mensaje visible en un `SnackBar` rojo:

> "Exception: Por seguridad, tu sesión es muy antigua. Cierra sesión, vuelve a iniciar sesión y vuelve a intentar eliminar la cuenta."

Este es el mensaje exacto de `firebase_auth_repository.dart:213-216` para `FirebaseAuthException.code == 'requires-recent-login'` — Firebase Auth exige un login reciente (~5 min) para operaciones sensibles como borrar la cuenta, y la sesión de prueba de Carlos ya la excedía.

**Por qué inc2 no lo cubrió.** El `SnackBar` con este mensaje SÍ se mostró correctamente — el bug real es que `ProfileScreen` seguía sin desmontarse. Causa: este error **no pasa por el `.timeout()`** en absoluto. `FirebaseAuthRepository.deleteAccount()` (`firebase_auth_repository.dart:177-221`) tiene esta estructura:

```dart
Future<void> deleteAccount() async {
  // 1. Borrar 15 subcolecciones — try/catch que traga TODO, nunca lanza.
  // 2. Borrar doc raíz users/{uid} — try/catch que traga TODO, nunca lanza.
  // 3. Borrar fasting_history legacy — try/catch que traga TODO, nunca lanza.
  // 4. user.delete() de Firebase Auth — el ÚNICO paso que puede lanzar.
  try {
    await user.delete();
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      throw Exception('Por seguridad...');
    }
    throw _handleAuthException(e);
  } catch (_) {
    throw Exception('Error técnico al eliminar la cuenta de autenticación.');
  }
  // 5. signOut() local.
}
```

Los pasos 1-3 están envueltos en `try { } catch (_) { /* best-effort */ }` — **nunca relanzan**, pase lo que pase. El único punto de todo el método que puede lanzar una excepción real es el paso 4. Esto significa algo importante: **cualquier excepción que llegue al `catch (e)` de `ProfileController.deleteAccount()` — no solo un timeout — implica que Firestore ya fue borrado**, porque los pasos 1-3 ya corrieron (best-effort) antes de siquiera intentar el paso 4.

El fix de inc2 (`signOut()` + `invalidate(authStateProvider)`) solo estaba dentro del bloque `on TimeoutException`. El `catch (e)` genérico —que es el que atrapa `requires-recent-login`— seguía sin ese recovery: solo seteaba `errorMessage` y hacía `rethrow`. Resultado: mismo bug, camino distinto.

**Fix.** Se extrae la lógica de recovery a un método compartido `_recoverFromPartialDelete()` y se llama desde **ambos** catch — el de `TimeoutException` y el genérico:

```dart
} on TimeoutException {
  const message = '...';
  await _recoverFromPartialDelete();
  state = state.copyWith(isSaving: false, errorMessage: message);
  throw Exception(message);
} catch (e) {
  await _recoverFromPartialDelete();
  state = state.copyWith(isSaving: false, errorMessage: e.toString());
  rethrow;
}

Future<void> _recoverFromPartialDelete() async {
  try {
    await ref.read(authRepositoryProvider).signOut();
  } catch (_) {
    // Best-effort.
  }
  ref.invalidate(authStateProvider);
}
```

Efecto colateral positivo: el propio mensaje de `requires-recent-login` le pide al usuario "cierra sesión, vuelve a iniciar sesión y reintenta" — pero antes de este fix no tenía forma de cerrar sesión desde una pantalla congelada en un spinner. Ahora la sesión se cierra sola, así que el usuario puede seguir la instrucción del mensaje sin fricción adicional.

Tests agregados: dos casos nuevos en `profile_controller_delete_account_test.dart` verifican `signOutCalled == true` tanto en el camino de timeout como en el de error genérico (simulando `requires-recent-login`).

## 8. Riesgos

- Si el timeout de 25s se dispara pero el borrado eventualmente completa en background, el usuario podría ver "tardó mucho, reintenta" y luego, al reintentar, encontrarse ya sin cuenta (Auth ya borrado) — el segundo intento fallaría con `user-not-found` o similar. Es un estado transitorio aceptable dado que ya era el comportamiento best-effort preexistente; no lo introduce este fix.
- 25s es una estimación conservadora sin datos de producción sobre cuánto tarda el borrado real de 15 subcolecciones con volumen de datos alto. Si se detecta que usuarios con mucho historial exceden ese margen en condiciones normales (no colgado), ajustar la constante.

## 9. Resultado

inc1 implementado, commiteado (`33c6cf2`, `86f2bf0`) y pusheado a `origin/mvp-core-clean` 2026-07-08. `flutter analyze` y `flutter test` corridos por Carlos: sin regresiones atribuibles a este SPEC.

inc2 (signOut + invalidate en el timeout) implementado y commiteado (`d2375b6`) 2026-07-08, pero solo cubría el camino de `TimeoutException` — insuficiente, según reveló la siguiente validación de Carlos.

inc3 (recovery generalizado a `_recoverFromPartialDelete()`, llamado desde AMBOS catch — timeout y error genérico, incluyendo `requires-recent-login`) implementado 2026-07-08. Esta es la cobertura completa: dado que `FirebaseAuthRepository.deleteAccount()` solo puede lanzar desde su paso 4 (Auth), y los pasos 1-3 (Firestore) son best-effort y nunca relanzan, CUALQUIER excepción capturada en `ProfileController.deleteAccount()` implica que Firestore ya está borrado — por lo tanto el recovery debe aplicar siempre, no solo en timeout.

Pendiente: commit+push de inc3 y validación manual final en device (forzar tanto timeout como `requires-recent-login` y confirmar redirect a `/login` en ambos).
