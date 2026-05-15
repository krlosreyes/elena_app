# SPEC-92 — Recálculo automático de % grasa al editar biometría + `bodyFatPercentage` nullable

**Estado:** DRAFT
**Versión:** 1.0
**Fecha:** 2026-05-14
**Tipo:** Bug fix + hardening de cálculo IMR
**Marco normativo:** `CONSTITUTION.md`, `BodyFatCalculator` (US Navy), SPEC-90 (bodyFat calculado en onboarding).

---

# 1. Contexto

SPEC-90 cerró el camino del **onboarding**: cuando un usuario nuevo completa el flujo, `bodyFatPercentage` se calcula con la fórmula US Navy (cintura, cuello, altura, género) y se persiste con confidence `ALTA` o `MEDIA`. Eliminó la trampa de heredar el `@Default(20.0)` para todo usuario nuevo.

Pero el camino del **Profile** quedó sin tocar. Hoy un usuario puede editar peso, cintura o cuello desde `profile_screen.dart` y persistir el nuevo valor **sin que `bodyFatPercentage` se recalcule**. El score engine usa `bodyFatPercentage` directamente para derivar masa magra (`score_engine.dart:100`, `:255`), por lo que un valor stale contamina el bloque Estructura del IMR para siempre — hasta que el usuario edite específicamente "%grasa" (que además no debería ser editable manualmente).

# 2. Problema

Tres bugs encadenados en el flujo de edición biométrica:

**2.1 `_editWaist` / `_editNeck` / `_editWeight` no recalculan bodyFat.**
`profile_screen.dart:200-258`: cada handler llama a `ProfileController.updateBiometry` pasando solo el campo modificado. `updateBiometry` (line 99) hace `bodyFatPercentage: bodyFatPercentage ?? currentUser.bodyFatPercentage` — preserva el valor viejo. Resultado: el IMR ya no refleja la geometría corporal real del usuario.

**2.2 `_editBodyFat` permite edición manual.**
`profile_screen.dart:243-259` abre `EditBiometryValueSheet` para que el usuario tipee directamente su %grasa. Esto contradice el contrato documentado en `body_fat_calculator.dart:3`: *"El usuario NUNCA ingresa % grasa — siempre se calcula"*. Permitir input manual genera divergencia entre lo que el sistema mide (cintura+cuello) y lo que el usuario afirma, y abre la puerta a IMR inflados o reducidos artificialmente.

**2.3 `UserModel.bodyFatPercentage` tiene `@Default(20.0)`.**
`user_model.dart:33`. Cualquier ruta de creación que omita el campo (un `copyWith`, una deserialización parcial, un test) cae silenciosamente al 20%. Es una trampa silenciosa que el score engine no puede detectar.

**Impacto reproducible:** usuario MR ingresa, completa onboarding (bodyFat=22% calculado), su IMR sale 65. Después edita cintura porque se midió mal (la subió 4 cm). El % grasa real debería subir a ~25%; en su lugar queda en 22% y el IMR baja a 59 por la cintura pero la masa magra que se ofrece al bloque Estructura sigue sobreestimada.

# 3. Solución propuesta

**3.1 Recalcular bodyFat en cada edición biométrica.**

En `profile_screen.dart`, los tres handlers (`_editWeight`, `_editWaist`, `_editNeck`) deben:

1. Capturar el nuevo valor del sheet.
2. Construir un set efectivo de medidas (weight, waist, neck, height, gender) usando el nuevo valor para el campo editado y los actuales para el resto.
3. Llamar a `BodyFatCalculator.calculateBodyFatPercentage` con ese set.
4. Validar coherencia con `BodyFatCalculator.isCoherent`. Si NO es coherente: persistir solo el campo editado y dejar `bodyFatPercentage` como estaba (NO sobreescribir con un cálculo malo). Si SÍ es coherente: pasar ambos campos (editado + bodyFat recalculado) a `updateBiometry`.
5. Si la confianza cambia (ej. de ALTA a MEDIA por una incoherencia recién introducida), actualizar `confidenceLevel`.

Toda la lógica de recálculo va en un helper puro `BiometryRecalcInputs.recompute(...)` en `lib/src/features/profile/domain/biometry_recalc.dart` (o ubicación equivalente), testeable sin Flutter.

**3.2 Quitar la edición manual de `bodyFatPercentage`.**

El tile actual de "Editar % grasa" se reemplaza por una fila **read-only** en `BodyCompositionPanel` que muestre:

- El % calculado con dos decimales.
- Una etiqueta visible: "Calculado a partir de cintura, cuello y altura".
- Un info-icon que al tap abre un BottomSheet explicando la fórmula US Navy y por qué no es editable.
- `confidenceLevel` visible como chip (ALTA/MEDIA/BAJA) con su semántica.

Eliminar `_editBodyFat()` de `profile_screen.dart`.

**3.3 Convertir `bodyFatPercentage` en nullable y eliminar el `@Default(20.0)`.**

En `user_model.dart:33`:

```dart
// ANTES
@Default(20.0) double bodyFatPercentage,

// DESPUÉS
double? bodyFatPercentage,
```

Impacto en consumidores:
- `score_engine.dart` (líneas 100, 255): si `bodyFatPercentage == null`, **NO** asumir 20%. Dos opciones:
  - (a) Omitir el componente Estructura del IMR; el score final usa solo los pilares con datos.
  - (b) Usar fallback explícito (15% hombre / 25% mujer) marcando el resultado con `confidenceLevel: 'BAJA'`.

  Decisión: **(b)** — el IMR debe poder calcularse siempre, pero quien lo consuma sabe que el valor viene de un fallback (vía `confidenceLevel`).
- `UserProfileMapper` y `CanonicalToLegacyAdapter`: ya manejan null al deserializar; verificar.
- Tests existentes: cualquiera que cree `UserModel` sin pasar `bodyFatPercentage` ahora obtiene `null` en lugar de 20.0 → revisar fixtures.

# 4. Plan

| # | Archivo | Cambio |
|---|---|---|
| 1 | `lib/src/features/profile/domain/biometry_recalc.dart` (nuevo) | Helper puro `BiometryRecalc.recompute({...})` que devuelve `{bodyFat, confidence, isCoherent}` |
| 2 | `test/features/profile/domain/biometry_recalc_test.dart` (nuevo) | Tests del helper: coherente, incoherente, edge cases |
| 3 | `lib/src/shared/domain/models/user_model.dart` | `bodyFatPercentage` → `double?` (eliminar `@Default(20.0)`) |
| 4 | Regenerar `user_model.freezed.dart` + `user_model.g.dart` | `dart run build_runner build --delete-conflicting-outputs` |
| 5 | `lib/src/core/engine/score_engine.dart` | Manejar `bodyFatPercentage == null` con fallback explícito + bajar confidence a 'BAJA' |
| 6 | `lib/src/features/auth/application/profile_controller.dart` | `updateBiometry` ya acepta `bodyFatPercentage` opcional — solo verificar que `null` se propaga bien |
| 7 | `lib/src/features/auth/presentation/profile_screen.dart` | `_editWeight`/`_editWaist`/`_editNeck` integran `BiometryRecalc`; eliminar `_editBodyFat` |
| 8 | `lib/src/features/profile/presentation/widgets/body_composition_panel.dart` (o equivalente) | Tile "% grasa" read-only con info-icon |
| 9 | `lib/src/shared/data/mappers/user_profile_mapper.dart` | Verificar que null serialize/deserialize sin perder data |
| 10 | `lib/src/features/auth/domain/canonical_to_legacy_adapter.dart` | Si el shape canónico trae `body.fatPct`, mantener; si no, dejar `null` (no inventar 20%) |
| 11 | Tests existentes que rompan por el cambio de default | Ajustar fixtures pasando `bodyFatPercentage` explícito |

# 5. Criterios de aceptación

1. Editar **peso** desde Profile recalcula bodyFat con la cintura/cuello/altura actuales y persiste ambos campos.
2. Editar **cintura** o **cuello** desde Profile recalcula bodyFat y persiste ambos campos.
3. Si la nueva combinación es incoherente (ej. cintura ≤ cuello), persiste solo el campo editado, conserva el bodyFat anterior, y muestra un snackbar/toast informativo: *"Las medidas no son coherentes — el % grasa no se actualizó."*
4. El tile "% grasa" en Profile es **read-only**. Al tap muestra explicación de fórmula US Navy.
5. `UserModel.bodyFatPercentage` es `double?` — sin default. Crear un `UserModel` sin pasarlo da `null`.
6. `ScoreEngine` con `bodyFatPercentage == null` no tira excepción; usa fallback documentado y marca `confidenceLevel: 'BAJA'`.
7. `flutter analyze` sin issues nuevos.
8. `flutter test` mantiene 479+ verdes con +N tests nuevos del helper.

# 6. Pruebas

**Tests puros (sin Flutter)** en `biometry_recalc_test.dart`:

- Hombre 80 kg / 175 cm / cintura 85 / cuello 38: recompute con cintura nueva 90 → bodyFat sube ~2-3 puntos, coherente, confidence ALTA.
- Mujer 65 kg / 165 cm / cintura 75 / cuello 32: recompute con cuello nuevo 40 → bodyFat baja, coherente.
- Caso incoherente: cintura 40 / cuello 38 → `isCoherent = false`, devolver el bodyFat anterior intacto.
- Caso con datos faltantes (waist == null): NO recalcular — devolver bodyFat anterior + confidence MEDIA o BAJA según se decida.

**Tests de score engine:**

- `bodyFatPercentage == null` + peso/altura presentes → IMR se calcula con fallback, no tira.
- `bodyFatPercentage == 22.0` ALTA confidence → IMR igual al cálculo actual (regresión).

**Tests de mapper:**

- Persistir `UserModel(bodyFatPercentage: null)` → Firestore guarda `null` (o omite el campo); lectura posterior devuelve `null` sin caer al 20.0 fantasma.

# 7. Riesgos

**7.1 `bodyFatPercentage` nullable rompe call-sites silenciosos.**
Cualquier `user.bodyFatPercentage` en la base de código que asume non-null va a fallar a compile time (good). Mitigación: corremos `flutter analyze` antes de commit; los call-sites que asumen non-null se ajustan caso por caso (mayoría son score engine y mapper, ambos en el plan).

**7.2 Regresión visual del Profile.**
El tile de %grasa pasa de editable a read-only. Mitigación: explicit copy en la UI explica por qué y dónde proviene el número. Esto es además consistente con el contrato documentado.

**7.3 Usuarios actuales con `bodyFatPercentage: 20.0` heredado.**
Hay perfiles en producción que se crearon antes de SPEC-90 con el default 20%. Cambiar el modelo a nullable no los toca — el valor 20.0 sigue ahí, no se vuelve null automáticamente. Pero ahora cualquier edición biométrica recalcula y los corrige progresivamente. **No requiere migración batch.** Documentar en release notes.

**7.4 Confidence chip puede confundir.**
ALTA/MEDIA/BAJA suena técnico. Mitigación: tooltip o info-icon que lo traduzca: *"ALTA = medidas completas y coherentes / MEDIA = falta alguna medida o hay inconsistencia / BAJA = sin medidas, usando estimación poblacional"*.

# 8. Out of scope

- Migración batch en Firestore para corregir bodyFat de usuarios actuales (auto-corrige en la siguiente edición; si se quiere agresivo, otra SPEC).
- Cambiar la fórmula de mujeres (la actual es aproximación por WHTR; SPEC futura puede agregar input de cadera para US Navy completa).
- Recalcular bodyFat al editar **altura** — la altura no se edita desde el Profile actual (es parte del onboarding solamente). Si en el futuro se permite editar altura, agregar a este mismo helper.
- Otras fórmulas (Jackson-Pollock, BIA) — fuera de MVP.
- Mover el `BodyCompositionEditorSheet` huérfano del feature `profile/` al `auth/`. Limpieza de código separado.

# 9. Resultado

(Se completa al cerrar el SPEC.)
