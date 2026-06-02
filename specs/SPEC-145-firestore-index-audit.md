# SPEC-145 — Auditoría de queries Firestore vs índices declarados

**Estado:** CLOSED (auditoría completa, cero gaps detectados — documentación preventiva publicada)
**Versión:** 1.0
**Fecha:** 2026-06-01
**Tipo:** Auditoría sistemática + documentación preventiva (sin código nuevo)
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 1 — Estabilización
**Estimación:** 1 día (real: ~1 hora — el codebase estaba más limpio de lo esperado)
**Marco normativo:** `CONSTITUTION.md`.

---

## 1. Contexto y motivación

### 1.1 — El bug que disparó la SPEC

El 2026-06-01, durante Bloque B de SPEC-143, Carlos reportó que al hacer hot reload en la app, el estado del ayuno desaparecía. La causa raíz identificada fue que la query `fasting_history.where('userId').orderBy('startTime', desc).limit(5)` requería un compound index `[userId ASC, startTime DESC]` que NO estaba declarado en `firestore.indexes.json`.

**Por qué solo aparecía en hot reload:** Firestore en cold start usa cache local agresivamente y puede resolver queries sin index. En hot reload se re-suscribe forzando un round-trip al servidor que rechaza la query con `failed-precondition`. El stream entra al rama `error` y el state queda en `initial` — efectivamente "logout aparente del ayuno".

Lo arreglamos agregando el index. Pero quedó la pregunta abierta: **¿hay otros gaps latentes?** Esta SPEC responde.

### 1.2 — Por qué importa

Bugs de index latentes son los peores de detectar:
- No fallan en testing (FakeFirebaseFirestore no enforza indexes).
- No fallan en cold start con cache caliente.
- Solo aparecen en hot reload o sesiones largas donde la cache se invalida.
- Cuando aparecen, el usuario interpreta como bug genérico, no como "necesita index".

Prevenirlos requiere auditoría sistemática de TODAS las queries compound del proyecto.

## 2. Resultado de la auditoría

### 2.1 — Resumen ejecutivo

**Total de queries analizadas:** 13 (en data sources de los 8 dominios persistidos).
**Compound queries que requieren index:** 1 (la de fasting_history).
**Indexes declarados:** 1 (la misma, agregada el 2026-06-01).
**Gaps detectados:** **0.**
**Cobertura:** 100%.

### 2.2 — Tabla de auditoría por dominio

| Dominio | Query principal | ¿Compound? | Index requerido | Status |
|---|---|---|---|---|
| `fasting_history` | `where(userId).orderBy(startTime desc).limit(5)` | Sí | `[userId ASC, startTime DESC]` | ✅ Declarado |
| `daily_summary` | `where(date).where(date).orderBy(date)` | No (mismo campo) | — | ✅ Auto |
| `nutrition_history` | `where(timestamp).where(timestamp).orderBy(timestamp)` | No (mismo campo) | — | ✅ Auto |
| `streak_history` | `where(date).orderBy(date desc)` | No (mismo campo) | — | ✅ Auto |
| `metabolic_cycles` (SPEC-149) | `orderBy(startedAt desc).limit(N)` | No (solo orderBy) | — | ✅ Auto |
| `biometric_history` (SPEC-143) | `orderBy(date desc).limit(365)` | No (solo orderBy) | — | ✅ Auto |
| `sleep_history` | `orderBy(wokeUp desc)` | No (solo orderBy) | — | ✅ Auto |
| `hydration_history` | `where(timestamp)` (sin orderBy) | No | — | ✅ Auto |
| `exercise_history` | `where(timestamp)` (sin orderBy) | No | — | ✅ Auto |
| `imr_history` (SPEC-143) | `orderBy(computedAt desc)` | No (single-field auto) | — | ✅ Auto |
| `user_food_suggestions` | `where(preferences_match).orderBy(last_shown)` | Sí | `[preferences_match ASC, last_shown ASC]` | ✅ Declarado |
| `metamorfosis_posts` | `where(tags contains).orderBy(createdAt desc)` | Sí | `[tags CONTAINS, createdAt DESC]` | ✅ Declarado |
| `fasting_history` (collection group) | Reservado para queries cross-user admin | Sí | `[is_completed ASC, start_time ASC]` | ✅ Declarado |

### 2.3 — Patrón pragmático identificado

El proyecto usa **client-side filtering** para condiciones que requerirían un index extra y cara escritura:

- `metabolic_cycles.watchOpenCycle` query trae los últimos 5 docs y filtra `closedAt == null` en cliente, en lugar de declarar un index sobre `closedAt`.
- `metabolic_cycles.watchLastClosed` query trae los últimos 10 docs y filtra `closedAt != null` en cliente.
- `imr_history.watchHistory` no usa `where`, solo `orderBy`.

**Veredicto:** este patrón es correcto. Evita compound indexes innecesarios sobre campos booleanos/nullables que son inherentemente expensive de mantener.

## 3. Guía preventiva: ¿cuándo necesitás declarar un index?

Esta sección es la principal contribución duradera de SPEC-145 — un checklist mental para developers del proyecto.

### 3.1 — REQUIERE index custom si:

✅ Tu query combina `.where()` y `.orderBy()` con **campos distintos**.
- Ejemplo: `where('userId').orderBy('startTime')` → necesita `[userId ASC, startTime DESC]`.

✅ Tu query combina múltiples `.where()` con campos distintos.
- Ejemplo: `where('userId').where('isActive', isEqualTo: true)` → necesita `[userId ASC, isActive ASC]`.

✅ Tu query usa `.where(field, arrayContains: ...)` con `.orderBy(otherField)`.
- Ejemplo: `where('tags', arrayContains: X).orderBy('createdAt')` → necesita `[tags ARRAY, createdAt DESC]`.

✅ Tu query usa `.collectionGroup(...)` con cualquier `.where()` o `.orderBy()`.
- Las collection group queries necesitan indexes explícitos incluso para single field.

### 3.2 — NO requiere index custom si:

❌ Solo usás `.orderBy(field)` (sin `.where`). Single-field index es automático en ambas direcciones.

❌ Solo usás `.where(field, isEqualTo: ...)` (sin `.orderBy`). Single-field automático.

❌ Tu query combina `.where(field).orderBy(field)` con el **mismo campo**.
- Ejemplo: `where('date', isEqualTo: X).orderBy('date')` — válido sin index custom.

❌ Tu query es sobre una subcollection (`users/{uid}/...`) y solo filtra por path. Las subcollections ya están scopadas por uid.

### 3.3 — Trampa común: el bug del cold start

Si una query compound NO tiene index pero "funciona en testing", **probablemente está usando la cache local de Firestore**. Esto enmascara el bug hasta que un hot reload o sesión larga invalida la cache.

**Para detectar en development:**

```bash
# Forzar invalidación de cache en simulator iOS:
xcrun simctl uninstall booted com.metamorfosis.elena.elenaApp
flutter run -d iphone

# O en device físico: cerrar app completamente + reabrir.
```

Si la query falla después de un cold start limpio, el index falta.

### 3.4 — Checklist al agregar una nueva query

Antes de hacer commit de un repo nuevo:

1. ¿Mi query combina `where` + `orderBy` con campos distintos? Si sí → declarar index en `firestore.indexes.json`.
2. ¿Mi query usa `collectionGroup`? Si sí → declarar index con `queryScope: COLLECTION_GROUP`.
3. ¿Probé en hot reload (no solo hot reload)? Cerrar app, reabrir, verificar que la query devuelve datos.
4. ¿Ejecuté `firebase deploy --only firestore:indexes` después de modificar el JSON? Sin deploy, el index no existe en producción.
5. ¿El index aparece como "Enabled" (no "Building") en Firebase Console > Firestore > Indexes? Build tarda 1-5 min.

## 4. Decisiones registradas

### 4.1 — NO se declaran indexes "por si acaso"

Cada index custom cuesta storage + writes (Firestore mantiene el index actualizado en cada write). Declarar indexes que ningún query usa hoy es desperdicio.

**Política:** declarar SOLO cuando se agrega la query que lo usa. Si la query se elimina/refactoriza, eliminar el index correspondiente en el mismo PR.

### 4.2 — NO se introduce CI check de indexes

Considerado: un script `tools/audit_firestore_indexes.dart` que falle el CI si encuentra `.where().orderBy()` no cubierto. **Rechazado** porque:

- Análisis estático de queries Dart en data sources es frágil (los call sites pueden combinar where con orderBy dinámicamente).
- Falsos positivos serían comunes (queries condicionales, helpers).
- Cost-benefit no justifica la inversión cuando el codebase está chico y disciplinado.

**Alternativa adoptada:** la guía de §3 + el checklist de §3.4 como contrato cultural del equipo.

### 4.3 — Indexes obsoletos a remover (opcional, no urgente)

Auditoría detectó **un index potencialmente obsoleto**: `fasting_history` collection group con `[is_completed ASC, start_time ASC]`. No se observó query que lo use actualmente. Puede ser legacy de una implementación previa o reservado para una futura.

**Decisión:** mantener por ahora. Removerlo requiere verificar que ninguna query externa al codebase lo usa (sitio web Metamorfosis Real, admin tools). El costo de mantener un index no usado es despreciable comparado con el riesgo de romper una query oculta.

## 5. Cambios en código

**Cero cambios de código.** Esta SPEC solo agrega documentación:

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear este documento de auditoría | `specs/SPEC-145-firestore-index-audit.md` (nuevo) |
| 2 | Agregar memoria del proyecto sobre auditoría | `memory/project_firestore_indexes.md` (nuevo, vive en sesión de Claude) |
| 3 | Actualizar `MEMORY.md` con link a la memoria nueva | `memory/MEMORY.md` |

## 6. Criterios de aceptación

1. Documento de auditoría publicado con tabla por dominio (§2.2).
2. Guía preventiva (§3) con checklist de cuándo declarar index.
3. Decisiones operacionales documentadas (§4).
4. Memoria de proyecto persistida para futuras sesiones.
5. Cero gaps de index reportados en la rama `mvp-core-clean` al cierre de la SPEC.

## 7. Out of scope (explícito)

- Script de auditoría automatizado (rechazado en §4.2).
- Remoción de index potencialmente obsoleto de fasting_history collection group (§4.3, decisión consciente de mantener).
- Auditoría de queries en el sitio web Metamorfosis Real (otro codebase).
- Optimización de queries existentes (no es el tema de esta SPEC).

## 8. Changelog

### v1.0 — 2026-06-01

Documento inicial post-auditoría sistemática. Resultado: cero gaps en mvp-core-clean. Documentación preventiva publicada como contrato cultural del equipo. SPEC-145 CLOSED el mismo día que se abrió — el codebase estaba más limpio de lo esperado.
