# SPEC-250 — Timeout guard en eliminar cuenta + silenciar not-found esperado en IMR persistence

**Estado:** IMPLEMENTED
**Versión:** 1.0
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
- [ ] `flutter analyze` sin warnings nuevos.
- [ ] `flutter test` sin regresiones, con test nuevo cubriendo el timeout de `deleteAccount()`.
- [ ] Validación manual en simulador de Xcode: reproducir el escenario original (o forzar el timeout con `timeout: Duration(seconds: 1)` puntualmente) y confirmar que el spinner se libera.

**Nota de cobertura:** Fix B (silenciar `not-found`) no tiene test automatizado dedicado — requeriría simular el `Timer` de debounce de 15s de `imrPersistenceProvider` (`fakeAsync`, no presente hoy como dependencia del proyecto) para llegar al `catchError`. Es un cambio de severidad de log, no de comportamiento funcional; se verifica por lectura de código + `flutter analyze`. Mismo criterio que SPEC-83 aplicó para su Bug C (bug de integración Firebase, verificación manual en vez de mock).

## 7. Alternativa considerada y descartada

Agregar `.timeout()` individual a cada una de las ~18 llamadas dentro de `firebase_auth_repository.dart` (mismo patrón que `_buildAccount`) en vez de un timeout global en el controller. Más preciso para diagnosticar cuál paso específico cuelga, pero:

- Mayor superficie de cambio (18 call sites vs. 1).
- El límite global de 25s ya resuelve el síntoma reportado (UI trabada) sin necesitar saber cuál paso falló — la Cloud Function limpia el resto igual.
- Queda como mejora futura si este timeout global resulta insuficiente en device real (out of scope de este SPEC).

## 8. Riesgos

- Si el timeout de 25s se dispara pero el borrado eventualmente completa en background, el usuario podría ver "tardó mucho, reintenta" y luego, al reintentar, encontrarse ya sin cuenta (Auth ya borrado) — el segundo intento fallaría con `user-not-found` o similar. Es un estado transitorio aceptable dado que ya era el comportamiento best-effort preexistente; no lo introduce este fix.
- 25s es una estimación conservadora sin datos de producción sobre cuánto tarda el borrado real de 15 subcolecciones con volumen de datos alto. Si se detecta que usuarios con mucho historial exceden ese margen en condiciones normales (no colgado), ajustar la constante.

## 9. Resultado

Implementado 2026-07-08. Pendiente: `flutter analyze`, `flutter test` con test nuevo, y validación manual en device por Carlos.
