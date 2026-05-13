# SPEC-87 — Inyectar `id` del doc Firestore al deserializar perfil

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Bugfix crítico (consecuencia de SPEC-84)
**Marco normativo:** `CONSTITUTION.md`

---

# 1. Contexto

SPEC-84 desbloqueó el flujo "usuario registrado en sitio entra a la app sin pasar por onboarding completo". Pero al hacerlo, expuso otro bug latente: cuando el sitio escribe un doc `users/{uid}` con shape canónico puro, el doc NO contiene un campo `id` plano (porque el id es el del documento en Firestore, no se duplica como campo).

# 2. Problema

Cadena de fallos observada en device (13-may-2026):

1. Usuario MR registrado solo en sitio → doc canónico sin `id` plano.
2. `UserProfileMapper.fromMap` → `UserModel.fromJson` lee `json['id'] as String? ?? ''` (`user_model.g.dart:11`) → `UserModel.id = ''`.
3. Consumidores (`StreakNotifier`, `SleepNotifier`, `HydrationNotifier`, `ExerciseNotifier`, `NutritionNotifier`, `OnboardingController.completeOnboarding`) usan `user.id` para construir paths Firestore: `users/{user.id}/streak_history`.
4. Con `user.id = ''`, el path resulta `users//streak_history` → Firestore retorna `permission-denied` (la regla wildcard `users/{userId}/{allPaths=**}` no matchea con `userId == ''`).

El error reportado por el usuario: `[StreakNotifier] Error en historial: [cloud_firestore/permission-denied]`.

# 3. Solución propuesta

Inyectar el `id` en el map al deserializar el doc. El data source (`FirestoreUserProfileV1Source.streamProfile`) ya conoce el `userId` (es el parámetro del método). Lo inyecta al `Map<String, dynamic>` antes de devolverlo.

Es el patrón estándar de "denormalizar el doc id" — robusto frente a cualquier shape de doc (legacy, canónico, mezclado, futuro).

# 4. Plan

Un archivo a modificar:

1. `lib/src/shared/data/sources/firestore_user_profile_v1_source.dart` — método `streamProfile`. Inyectar `'id': userId` al map antes de devolverlo.

# 5. Criterios de aceptación

- Un doc canónico SIN campo `id` plano se deserializa con `UserModel.id` == uid del documento Firestore (no string vacío).
- Las queries de los notifiers (`streak_history, sleep_history, hydration_history, exercise_history, nutrition_history`) ya no fallan con `permission-denied` para usuarios MR.
- Docs legacy con `id` plano ya correcto: el comportamiento no cambia (sobrescribir con el mismo valor es idempotente).
- `flutter test` sin regresión.

# 6. Pruebas

Test nuevo en `test/shared/data/sources/firestore_user_profile_v1_source_test.dart`:

- "streamProfile inyecta id del doc cuando el map no lo trae" — usando `FakeFirebaseFirestore`.
- "streamProfile sobrescribe id si el doc lo trajo distinto" — el id del doc gana (autoritativo).

# 7. Riesgos

- **El doc tenía un `id` distinto al uid del Firestore (bug previo o doc corrupto)** → el fix lo sobrescribe con el correcto. Es lo deseable.
- **Otros data sources** (`firestore_streak_v1_source`, `firestore_sleep_v1_source`, etc.) podrían tener el mismo bug si deserializan a un modelo con `id`. Out of scope inmediato — esos no son consumidos por el flujo de auth crítico.

# 8. Out of scope

- Auditar otros mappers/data sources que puedan tener el mismo patrón.
- Migración de docs viejos con `id` plano incorrecto (no se conoce ningún caso).

# 9. Resultado

(Se completa al cerrar el SPEC.)
