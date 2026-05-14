# SPEC-76 — Disclaimer clínico versionado + acceso permanente desde Profile

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** Hardening pre-launch
**Marco normativo:** `CONSTITUTION.md`, `IMR_BIBLIOGRAPHY.md §11` (poblaciones de riesgo).
**Antecedente:** SPEC-70.8 (disclaimer obligatorio en onboarding paso 0).

---

# 1. Contexto

SPEC-70.8 introdujo el paso 0 del onboarding con el disclaimer médico (5 contraindicaciones de IMR_BIBLIOGRAPHY.md §11). El `UserModel` ya persiste `healthDisclaimerAccepted` (bool) + `healthDisclaimerAcceptedAt` (DateTime). Para release necesitamos:

- Versionado del disclaimer: si en el futuro se agrega/modifica una contraindicación (recomendación clínica externa, nuevo paper, ajuste regulatorio), debemos forzar re-aceptación.
- Acceso permanente desde Profile: el usuario debe poder consultar las condiciones que aceptó en cualquier momento (requisito legal y UX).
- Texto separado en archivo de configuración para que legal/clínico revise sin tocar UI.

# 2. Problema

Hoy:
1. El disclaimer no tiene versión. Si lo cambiamos, ningún usuario existente vuelve a verlo.
2. El usuario no tiene cómo releer el disclaimer una vez aceptado (no hay entry point en Profile).
3. El texto está embebido en `onboarding_screen.dart` (5 widgets `_DisclaimerItem`). Cambiar una palabra requiere tocar UI.

# 3. Solución propuesta

**3.1 Constante `kHealthDisclaimerVersion`** en `lib/src/features/auth/domain/health_disclaimer.dart` (archivo nuevo). Inicialmente `1`. Si en el futuro se cambia el texto/condiciones, se incrementa y los usuarios re-aceptan.

**3.2 Campo `healthDisclaimerVersion: int` en `UserModel`** con `@Default(0)` (un usuario que nunca vio el disclaimer queda en 0; cuando lo acepta se setea a `kHealthDisclaimerVersion`).

**3.3 Re-prompt condicional en el onboarding adaptativo.** Si `user.healthDisclaimerVersion < kHealthDisclaimerVersion` o `!user.healthDisclaimerAccepted`, el paso 0 se muestra. Esto reemplaza la condición actual basada solo en `_disclaimerAccepted` local.

**3.4 Texto canonicalizado** en `health_disclaimer.dart`:
```dart
class HealthDisclaimerCondition {
  final IconData icon;
  final String title;
  final String body;
}

const List<HealthDisclaimerCondition> kHealthDisclaimerConditions = [
  HealthDisclaimerCondition(...),
  // 5 condiciones según IMR_BIBLIOGRAPHY.md §11
];
```

`onboarding_screen.dart` consume esta lista en lugar de tener los `_DisclaimerItem` hardcodeados.

**3.5 Pantalla `DisclaimerScreen`** (`lib/src/features/auth/presentation/disclaimer_screen.dart`):
- Read-only. Muestra `kHealthDisclaimerConditions` con el mismo formato del onboarding.
- Si `user.healthDisclaimerAccepted`, muestra fecha y versión de aceptación.
- Si la versión cambia, muestra banner: "Hemos actualizado las condiciones — vuelve a aceptarlas para seguir usando la app". Tap → `/onboarding`.
- Ruta: `/profile/disclaimer`.

**3.6 Entry point en Profile**: agregar tile bajo la sección "CUENTA" con label "Condiciones médicas (v1, aceptado el dd/mm/yyyy)" que abre la pantalla.

# 4. Plan

| Archivo | Cambio |
|---|---|
| `lib/src/features/auth/domain/health_disclaimer.dart` (nuevo) | Constante + lista canónica |
| `lib/src/shared/domain/models/user_model.dart` | + `healthDisclaimerVersion` con @Default(0) — requiere build_runner |
| `lib/src/features/onboarding/presentation/onboarding_screen.dart` | Consume `kHealthDisclaimerConditions` + setea `healthDisclaimerVersion` al aceptar |
| `lib/src/features/onboarding/application/onboarding_controller.dart` | Sin cambio (saveProfile lo hace) |
| `lib/src/features/auth/application/profile_controller.dart` | Sin cambio |
| `lib/src/features/auth/presentation/disclaimer_screen.dart` (nuevo) | Pantalla read-only |
| `lib/src/features/auth/presentation/profile_screen.dart` | Tile bajo "CUENTA" |
| `lib/src/router/app_router.dart` | Ruta `/profile/disclaimer` |
| `test/features/auth/health_disclaimer_test.dart` (nuevo) | Tests del re-prompt + versión |

# 5. Criterios de aceptación

- Usuario nuevo registrándose: ve paso 0 → acepta → `healthDisclaimerAccepted=true, healthDisclaimerVersion=1, healthDisclaimerAcceptedAt=now()` en Firestore.
- Usuario existente con `healthDisclaimerAccepted=true, healthDisclaimerVersion=null/0`: al abrir la app vuelve a ver el paso 0 (forzamos re-aceptación al introducir la versión).
- Si `kHealthDisclaimerVersion` se cambia a 2 en el futuro: usuario con versión 1 vuelve a ver el paso 0.
- Profile tiene un tile "Condiciones médicas" que abre la pantalla read-only.
- La pantalla muestra las 5 contraindicaciones + fecha y versión de aceptación.
- `flutter analyze` sin issues nuevos.
- `flutter test` mantiene 446+ verdes con nuevos tests.

# 6. Pruebas

`health_disclaimer_test.dart`:
- `kHealthDisclaimerConditions.length == 5` (las 5 contraindicaciones).
- `needsReprompt(user)` retorna true si `healthDisclaimerVersion < kHealthDisclaimerVersion`.
- `needsReprompt(user)` retorna true si `!healthDisclaimerAccepted`.
- `needsReprompt(user)` retorna false si version ≥ kVersion + accepted.

# 7. Riesgos

- **Revisión legal externa** del texto sigue pendiente. La SPEC habilita la estructura pero el copy final debe ser revisado por abogado/clínico antes de submission a stores. Marcado como bloqueador EXTERNO.
- **Migración de usuarios existentes:** todos los que aceptaron pre-SPEC-76 tienen `healthDisclaimerVersion=0` (default) cuando re-deserializan tras el deploy. Re-prompt automático. Aceptable, se les explica con un mensaje suave en el banner.
- **build_runner** requerido para regenerar `user_model.freezed.dart` / `.g.dart`.

# 8. Out of scope

- Revisión legal del texto (es proceso externo, no codeable).
- Soporte i18n del disclaimer (la app está solo en español neutro).
- Notificación push cuando se cambia la versión del disclaimer (re-prompt es al abrir la app).
- Pantalla equivalente en el sitio MR (responsabilidad del otro equipo).

# 9. Resultado

**Verificación local (13-may-2026):** `flutter test` 454 verdes / 3 skipped / 0 rojos (+7 nuevos de `health_disclaimer_test.dart`).

**Smoke test pendiente:**
1. Usuario nuevo: ve paso 0 → acepta → Firestore confirma `healthDisclaimerVersion == 1`.
2. Usuario existente legacy: al abrir la app vuelve a ver el paso 0 (versión 0 < 1).
3. Profile → tile "Condiciones médicas" abre `/profile/disclaimer` con fecha y versión.
4. Simulación bump versión (cambiar `kHealthDisclaimerVersion = 2` localmente) → banner naranja en `/profile/disclaimer` con CTA a re-aceptar.

**Bloqueador externo pendiente:** revisión legal/clínica del texto de las 5 contraindicaciones antes de submission a stores. La estructura técnica está lista; el copy puede ajustarse incrementando `kHealthDisclaimerVersion` y los usuarios re-aceptan automáticamente.
