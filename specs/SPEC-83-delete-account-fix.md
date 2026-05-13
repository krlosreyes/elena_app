# SPEC-83 — Fix delete account: spinner colgado + residual en Firebase Auth

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Bugfix
**Marco normativo:** `CONSTITUTION.md`

---

# 1. Contexto

El botón "Eliminar cuenta" del perfil tiene tres bugs encadenados detectados durante prueba en device (13-may-2026). Cada uno tiene fix independiente; los tres deben aplicarse juntos para que el flujo sea operativo.

# 2. Problema

**Bug A (loading bloqueado).** `ProfileController.deleteAccount` (líneas 110-121 de `profile_controller.dart`) setea `isSaving = true` al entrar y solo lo limpia en el `catch`. En el camino exitoso, `isSaving` queda en `true` indefinidamente y el spinner del AppBar (`profile_screen.dart:57-68`) nunca se apaga.

**Bug B (no transición a login).** El callback de la pantalla (`_confirmDeleteAccount`, `profile_screen.dart:486-597`) hace `context.go('/login')` tras `await deleteAccount`. Pero el `currentUserStreamProvider` reacciona al borrado del doc Firestore antes de que el `context.go` ejecute, y la pantalla renderiza un `CircularProgressIndicator` (línea 76) porque `user == null`. Resultado visual: spinner indefinido en lugar de transición a login.

**Bug C (residual en Firebase Auth).** `FirebaseAuthRepository.deleteAccount` (líneas 156-173) borra primero el doc Firestore y después llama `user.delete()`. Si `user.delete()` lanza `requires-recent-login` (Firebase exige sesión reciente, típicamente <5 min), el doc Firestore ya se eliminó pero el usuario Auth queda residual. Estado inconsistente: el usuario no puede entrar a la app (no hay perfil) pero su email sigue ocupado en la user-pool compartida con Metamorfosis Real.

# 3. Solución propuesta

**Fix A.** En `ProfileController.deleteAccount`, agregar `state = state.copyWith(isSaving: false)` después del `await` exitoso. También invalidar `authStateProvider` para forzar al stream a re-emitir el estado de no-autenticado.

**Fix B.** En `_confirmDeleteAccount`, mostrar un `SnackBar` de confirmación antes de navegar. Y usar `context.go('/login')` que el router maneja vía redirect; no hacer pop adicional.

**Fix C.** En `FirebaseAuthRepository.deleteAccount`, invertir el orden:
1. `user.delete()` PRIMERO (Firebase Auth).
2. Si falla con `requires-recent-login`, lanzar Exception específica y NO tocar Firestore.
3. Si tiene éxito, borrar `users/{uid}` de Firestore. Si esto falla, loguear warning pero no propagar excepción (el usuario ya está eliminado de Auth; la limpieza del doc se puede hacer manualmente).
4. `signOut()` final para limpiar la sesión cacheada localmente.

# 4. Plan

Tres archivos a modificar, en orden:

1. `lib/src/features/auth/data/firebase_auth_repository.dart` — método `deleteAccount`.
2. `lib/src/features/auth/application/profile_controller.dart` — método `deleteAccount`.
3. `lib/src/features/auth/presentation/profile_screen.dart` — método `_confirmDeleteAccount` (callback del botón ELIMINAR CUENTA).

# 5. Criterios de aceptación

- Tras confirmar "ELIMINAR" en el diálogo, el usuario ve un SnackBar verde con mensaje de confirmación y la app navega a `/login`.
- El spinner del AppBar de Perfil ya no queda colgado.
- En Firebase Console:
  - El doc `users/{uid}` desaparece de Firestore.
  - El usuario desaparece de Authentication > Users.
- Si la sesión es vieja (`requires-recent-login`), el usuario ve un mensaje claro y el doc Firestore no se borra (consistencia).
- Re-registro con el mismo email funciona inmediatamente después del delete (porque el email se liberó en Auth).
- `flutter analyze` sin issues nuevos.
- `flutter test` 375 verdes / 3 skipped / 0 rojos (sin regresión).

# 6. Pruebas

Smoke test manual en device:
1. Login con usuario MR.
2. Ir a Perfil → ELIMINAR CUENTA → escribir "ELIMINAR" → confirmar.
3. Verificar SnackBar + redirect a `/login`.
4. Abrir Firebase Console: confirmar que `users/{uid}` no existe y el usuario Auth tampoco.
5. Registrar nuevo usuario con el mismo email: debe funcionar (email liberado).

Test automatizado: no se agrega test nuevo por ser un bug de integración Firebase difícil de mockear sin `fake_cloud_firestore` + `firebase_auth_mocks` simulando `requires-recent-login`. La SPEC se cierra con verificación manual.

# 7. Riesgos

- **Subcolecciones huérfanas** (`users/{uid}/sleep_history`, `streak_history`, etc.) NO se eliminan en este fix. Quedan en Firestore como datos huérfanos del usuario eliminado. Es un bug pre-existente que esta SPEC no aborda — se documenta como SPEC futura (limpieza recursiva o Cloud Function `onDelete`).
- **`requires-recent-login`** es comportamiento esperado de Firebase y no se puede evitar sin un re-auth flow completo. El mensaje al usuario explica qué hacer ("cierra sesión y vuelve a iniciar antes de reintentar"). Re-auth in-line es scope mayor (SPEC futura si se vuelve fricción real).
- **Email liberado inmediato:** tras eliminar de Auth, el email queda disponible para registro inmediato. Si el usuario se arrepiente, no hay forma de recuperar la cuenta — el doc Firestore ya se borró. Esto es deseable (el usuario pidió eliminar) pero documentado.

# 8. Out of scope

- Limpieza recursiva de subcolecciones `users/{uid}/*` (SPEC futura).
- Re-auth flow in-line para `requires-recent-login` (SPEC futura).
- Eliminar campos canónicos (SPEC-82) en otras colecciones que referencien al usuario (`metamorfosis_posts/{postId}.authorUid`, si existe).
- Test automatizado con mocks de `requires-recent-login`.

# 9. Resultado

(Se completa al cerrar el SPEC.)
