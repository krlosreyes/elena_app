# SPEC-143 — Persistencia histórica unificada: `imr_history` + versionado automático biométrico

**Estado:** IN_PROGRESS (aprobada por Carlos 2026-06-01)
**Versión:** 1.0
**Fecha:** 2026-06-01 · aprobada 2026-06-01
**Tipo:** Infraestructura de datos — cierra dos gaps de persistencia detectados en auditoría 2026-06-01.
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** 1.5 (bloqueante de SPEC-141 — sin esta SPEC el IMR longitudinal no tiene dónde escribir su tendencia ni cómo confiar en el `bodyFatPercentage` actual)
**Estimación:** 2–3 días Carlos+Claude
**Marco normativo:** `CONSTITUTION.md` §3.2 (no leaking Firestore en notifiers), `IMR_BIBLIOGRAPHY.md`.
**Depende de:**
- SPEC-82 (canonical mirror, ya escribe `users/{uid}` doc raíz — interceptamos su path de update).
- SPEC-92 (`BodyFatCalculator` ya existe — sus llamados también deben versionar).
- SPEC-132 nativa (instalación del plugin `health` — los listeners de SPEC-132 también versionarán cuando se conecten en SPEC-141.2).

**Bloquea:**
- **SPEC-141** (IMR longitudinal con cadencia semanal). SPEC-141 escribe en `imr_history/{weekISO}` y depende del check-in biométrico confiable. Sin SPEC-143, SPEC-141 no puede pasar a IN_PROGRESS.

---

## 1. Contexto y motivación

### 1.1 — Los dos gaps detectados

Auditoría de persistencia del 2026-06-01 reveló dos brechas que afectan directamente la promesa de valor *"salud metabólica longitudinal verificable"* del producto:

**Gap 1 — El IMR no tiene historial propio.** La métrica más identitaria del producto solo persiste como snapshot actual en `users/{uid}.imr.current` (SPEC-82). Si el usuario quiere ver "cómo evolucionó mi IMR en los últimos 6 meses", no hay datos. El `daily_summary/{YYYYMMDD}.imrScore` contiene el IMR diario, no el longitudinal. SPEC-141 introduce el concepto de IMR longitudinal pero necesita un sustrato físico donde escribir cada snapshot semanal.

**Gap 2 — Cambios biométricos directos no se versionan automáticamente.** El usuario que edita su peso desde Profile (o desde el recálculo automático de `BodyFatCalculator` en SPEC-92, o desde un futuro sync de HealthKit en SPEC-132) sobrescribe los campos `weight`, `waistCircumference`, `neckCircumference`, `bodyFatPercentage` en `users/{uid}` **sin dejar rastro** en `biometric_history`. La única ruta que versiona hoy es el sheet `BiometricCheckIn` manual. Esto rompe la promesa de tendencia: el usuario que pierde 5 kg en 2 meses no puede verlo si lo registró editando Profile en vez de haciendo check-ins formales.

### 1.2 — Por qué esta SPEC existe ahora

SPEC-141 v1.1 (IMR longitudinal con cadencia semanal) consume ambas piezas:

- Escribe a `imr_history/{weekISO}` → necesita que la colección exista.
- Dispara recálculo al check-in biométrico → necesita que TODO update biométrico (no solo el manual) sea detectable y versionado.

Sin SPEC-143, SPEC-141 puede implementarse pero queda con dos puntos ciegos: la tendencia no tiene tabla y el gatillo confía en una sola ruta de edición. SPEC-143 cierra ambos para que SPEC-141 sea técnicamente sólida.

### 1.3 — Por qué NO es parte de SPEC-141

SPEC-141 ya tiene 711 líneas y un alcance bien delimitado (cómputo + cadencia). Meterle persistencia de subcollection nueva + interceptor de updates biométricos rompe el principio de "una SPEC, un cambio coherente". SPEC-143 es infraestructura pura que también será útil para SPEC-132 (HealthKit sync versiona automáticamente) y para cualquier feature futura que cambie biometría.

## 2. Decisión de producto (resumen ejecutivo)

1. **Se crea la subcollection `users/{uid}/imr_history/{weekISO}`** con shape canónico, security rules y un índice compuesto para tendencia. SPEC-143 solo crea el sustrato — SPEC-141 escribe en él.
2. **Se introduce `BiometricHistoryService`** como punto único por donde toda escritura de biometría debe pasar. Reemplaza llamados directos a `userProfileRepository.update()` cuando esos updates tocan campos biométricos.
3. **Cada escritura de biometría versiona automáticamente** una entrada en `users/{uid}/biometric_history/{yyyy-MM-dd}` con el snapshot completo del momento, indicando el `source` (`'profile_edit'`, `'checkin_sheet'`, `'healthkit_sync'`, `'bodyfat_recompute'`, `'onboarding_baseline'`).
4. **La subcollection `biometric_history` existente NO se reescribe.** Se extiende su schema con campos opcionales (`source`, `previousValues`). Los docs históricos preservan su shape; los nuevos enriquecen.
5. **El límite hardcoded de 90 días en `BiometricRepository.watchHistory()` sube a 365 días** y se hace configurable vía parámetro. SPEC-141 lee historial > 90 días para tendencia anual del IMR sin recargar.
6. **Backfill mínimo y honesto:** al deploy, cada usuario activo recibe UNA entrada inicial en `biometric_history` con la fecha del día del deploy y `source: 'spec_143_backfill'`. No se inventan timestamps históricos. Esta entrada sirve de baseline para la tendencia.
7. **No se introducen Cloud Functions.** Toda la lógica vive client-side en el servicio + repo. Esto reduce costos GCP y mantiene la app testeable en CI sin emulador completo.

## 3. Lo que NO se hace (límites duros de scope)

- **No se reescribe `biometric_history` existente.** Los docs históricos preservan su shape. Se extienden con campos opcionales.
- **No se cambia el shape de `users/{uid}`** ni los campos biométricos del doc raíz. Siguen siendo la fuente de "valor actual"; lo que cambia es que cada escritura ahora también escribe historial.
- **No se reescribe `BiometricRepository`** — se *envuelve* por el nuevo `BiometricHistoryService`. El repo existente sigue siendo válido para reads.
- **No se toca el shape ni la persistencia de los 5 pilares** (`sleep_history`, `nutrition_history`, etc. siguen igual — la auditoría confirmó que están bien).
- **No se implementa el cómputo del IMR longitudinal.** Eso es SPEC-141. SPEC-143 solo crea la subcollection donde SPEC-141 escribirá.
- **No se implementa UI para visualizar el historial biométrico expandido.** Sigue mostrándose en `progress_screen.dart` igual que antes; lo que cambia es que el historial es más completo (y más largo).
- **No se introduce GDPR-grade audit trail** (quién, cuándo, desde qué IP). El `source` es suficiente para el caso de uso actual. SPEC futura puede agregar audit completo si hay requisito regulatorio.
- **No se versiona la edición de `height`** automáticamente. Altura no cambia en adultos; las ediciones son correcciones de typo del onboarding. Versionarla generaría ruido.
- **No se hace migración destructiva.** Si el deploy falla, el estado actual queda intacto. Toda escritura nueva es aditiva.

## 4. Requisitos funcionales

### RF-143-01 — Crear subcollection `imr_history`

Nueva subcollection: `users/{uid}/imr_history/{weekISO}`.

**Shape canónico:**

```
{
  weekISO: "2026-W23",                  // string, PK = doc id
  totalScore: 0..100,                   // int — IMR longitudinal de esa semana
  computedAt: Timestamp,                // serverTimestamp al escribir
  reason: "onboarding_baseline" |
          "biometric_checkin"  |
          "healthkit_sync"     |
          "fallback_stale",

  subscores: {
    structure: 0..1,
    behaviorTrend: 0..1,
    adherence: 0..1,
    coherence: 0..1,
  },

  biometricSnapshot: {
    weight: number,                     // kg
    waistCircumference: number | null,  // cm
    neckCircumference: number | null,   // cm
    bodyFatPercentage: number | null,   // %
    isMeasurementEstimated: bool,
  },

  derivedMetrics: {                     // derivados SPEC-82
    imc: number,
    tmb: number,
    metabolicAge: number,
    ica: number,
    ffmi: number,
    whtr: number,
  }
}
```

**Security rules** (extensión de `firestore.rules`):

```
match /users/{userId}/imr_history/{weekISO} {
  allow read:  if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null && request.auth.uid == userId
                 && request.resource.data.weekISO == weekISO
                 && request.resource.data.totalScore is number
                 && request.resource.data.totalScore >= 0
                 && request.resource.data.totalScore <= 100;
}
```

**Índice** (para queries de tendencia que ordenan por fecha):

Firestore crea automáticamente single-field indexes en ambas direcciones para
todos los campos. La query típica `imr_history.orderBy('computedAt', desc).limit(N)`
NO requiere declaración en `firestore.indexes.json` — falla el `firebase deploy`
con HTTP 400 "this index is not necessary" si se intenta declarar.

Si en el futuro se agregan queries multi-field sobre `imr_history` (ej. filtrar
por `reason` Y ordenar por `computedAt`), abrir SPEC followup que declare el
compound index correspondiente.

### RF-143-02 — `BiometricHistoryService` como punto único

Nueva clase en `lib/src/features/progress/application/biometric_history_service.dart`:

```dart
/// SPEC-143: punto único de escritura de biometría. Toda mutación de
/// peso, cintura, cuello, %grasa o flag de estimación pasa por aquí.
///
/// Garantiza que `users/{uid}` (estado actual) y
/// `users/{uid}/biometric_history/{yyyy-MM-dd}` (historial) se
/// mantengan en sync atómicamente.
class BiometricHistoryService {
  BiometricHistoryService(this._userProfileRepo, this._biometricRepo);

  final UserProfileRepository _userProfileRepo;
  final BiometricRepository _biometricRepo;

  /// Aplica un update biométrico desde Profile/edición manual.
  /// Versiona en `biometric_history` con source = 'profile_edit'.
  Future<void> updateFromProfileEdit({
    required String userId,
    required BiometricDelta delta,
  });

  /// Aplica un check-in biométrico manual desde el sheet.
  /// Preserva el comportamiento existente (BiometricRepository.saveCheckIn).
  /// Source = 'checkin_sheet'.
  Future<void> updateFromCheckInSheet({
    required String userId,
    required BiometricCheckIn checkin,
  });

  /// Aplica un update desde HealthKit/Health Connect sync.
  /// Source = 'healthkit_sync'. NO dispara escritura si delta es ruido (< 0.5%).
  Future<void> updateFromHealthKitSync({
    required String userId,
    required BiometricDelta delta,
  });

  /// Aplica un recálculo de %grasa desde `BodyFatCalculator` (SPEC-92).
  /// Source = 'bodyfat_recompute'. Solo actualiza `bodyFatPercentage`.
  Future<void> updateFromBodyFatRecompute({
    required String userId,
    required double newBodyFatPercentage,
  });

  /// Aplica el baseline de onboarding. Source = 'onboarding_baseline'.
  /// Diferente porque crea la primera entrada del historial del usuario.
  Future<void> writeOnboardingBaseline({
    required String userId,
    required UserModel user,
  });
}
```

**`BiometricDelta`** es un value object nuevo:

```dart
class BiometricDelta {
  final double? weight;
  final double? waistCircumference;
  final double? neckCircumference;
  final double? bodyFatPercentage;
  final bool? isMeasurementEstimated;

  /// True si al menos un campo varía > 0.5% respecto al baseline.
  bool isSignificant({required UserModel baseline}) { ... }
}
```

### RF-143-03 — Lógica interna del versionado

`BiometricHistoryService` ejecuta dos escrituras por update, en un `WriteBatch`:

1. **Update del doc raíz `users/{uid}`** con los nuevos valores biométricos.
2. **Set del doc `users/{uid}/biometric_history/{yyyy-MM-dd}`** con:
   - El snapshot completo de los 5 campos biométricos (no solo los que cambiaron).
   - `source: String` indicando la procedencia.
   - `recordedAt: serverTimestamp`.
   - `previousValues: Map?` con los valores anteriores de los campos que SÍ cambiaron (audit ligero).

**Múltiples updates en el mismo día:** el doc PK = `yyyy-MM-dd` se sobrescribe con la última edición del día. El `previousValues` apunta a los valores anteriores de esa edición (no a los del día anterior). Si el usuario editó peso 3 veces en un día, el doc final muestra el último valor y el `previousValues` del penúltimo. Decisión consciente: evita explosión de docs y el caso "edito 3 veces" no es clínicamente relevante.

**Schema del doc `biometric_history/{yyyy-MM-dd}` extendido:**

```
{
  date: "2026-06-01",
  recordedAt: Timestamp,
  source: "profile_edit" | "checkin_sheet" | "healthkit_sync" |
          "bodyfat_recompute" | "onboarding_baseline" | "spec_143_backfill",

  // Snapshot del momento
  weight: number,
  waistCircumference: number | null,
  neckCircumference: number | null,
  bodyFatPercentage: number | null,
  isMeasurementEstimated: bool,

  // Audit ligero — campos previos para los que cambiaron
  previousValues: {
    weight: number?,
    waistCircumference: number?,
    neckCircumference: number?,
    bodyFatPercentage: number?,
  } | null,
}
```

Los campos preexistentes (`date`, biométricos) preservan su shape de la `biometric_history` actual. Los campos nuevos (`source`, `recordedAt`, `previousValues`) son opcionales — docs históricos los tienen como null.

### RF-143-04 — Refactor de callers existentes

**Profile screen** (`profile_screen.dart`): la edición de campos biométricos hoy llama a algún método de `UserProfileRepository`. Identificar todos esos callsites y migrarlos a `BiometricHistoryService.updateFromProfileEdit()`.

**Biometric Checkin Sheet** (`biometric_checkin_sheet.dart`): hoy llama a `BiometricRepository.saveCheckIn()` que ya versiona. Migrar a `BiometricHistoryService.updateFromCheckInSheet()` (que internamente puede seguir llamando al repo, pero centraliza el source tag).

**Onboarding completion** (`onboarding_controller.dart` o equivalente): al finalizar onboarding, debe llamar `writeOnboardingBaseline()`. Hoy el `OnboardingController.completeOnboarding` ya escribe el user profile y dispara IMR baseline (SPEC-82). Agregar el escribir baseline biométrico en el mismo flujo.

**BodyFatCalculator (SPEC-92)** — el recálculo automático de `bodyFatPercentage` desde cintura/cuello/altura. Identificar dónde se persiste hoy el resultado (probablemente directo a `userProfileRepository`). Migrar a `BiometricHistoryService.updateFromBodyFatRecompute()`.

**HealthImportService** (`health_sync/application/health_import_service.dart`): este archivo ya existe del trabajo de SPEC-132 nativa (en working directory). Cuando SPEC-141.2 conecte el listener, llamará a `BiometricHistoryService.updateFromHealthKitSync()`. Por ahora SPEC-143 solo expone el método; la conexión real va en SPEC-141.2.

### RF-143-05 — Filtro de ruido para HealthKit sync

`updateFromHealthKitSync` aplica el siguiente filtro antes de escribir:

```dart
final isNoise = delta.weight != null
    && (delta.weight! - baseline.weight).abs() / baseline.weight < 0.005;
// análogo para cintura, cuello

if (!delta.isSignificant(baseline: baseline)) {
  // No escribe nada. Log de telemetría: "healthkit_sync_skipped_as_noise".
  return;
}
```

Threshold: 0.5% de variación por campo individual. Si el sensor manda 75.0 kg cuando ayer era 75.1 kg, es ruido. Si manda 73.5 kg, es señal. Documentado en código con `// SPEC-143.RF-143-05`.

### RF-143-06 — Subir el límite hardcoded a 365 días

`BiometricRepository.watchHistory()` línea ~34 tiene hoy `limit = 90` hardcoded. Cambiar a:

```dart
Stream<List<BiometricCheckIn>> watchHistory({
  int limitDays = 365,
}) { ... }
```

Default 365 días para que SPEC-141 pueda leer tendencia anual sin recargar. Llamadores existentes que pasen `90` siguen funcionando (deprecated marker en el callsite con TODO para subir).

### RF-143-07 — Backfill mínimo al deploy

Una sola Cloud Function de un solo uso (NO permanente) corre tras deploy. Por cada `users/{uid}` activo:

1. Verificar si `biometric_history` tiene al menos 1 doc.
2. Si NO tiene, crear UNA entrada con:
   - `date: yyyy-MM-dd del día del backfill`
   - `recordedAt: serverTimestamp`
   - `source: 'spec_143_backfill'`
   - Snapshot completo de los campos biométricos actuales del user doc raíz.
   - `previousValues: null`.
3. Loguear count de usuarios procesados.
4. Cloud Function se borra a sí misma post-ejecución (o se marca con `disabled: true`).

**Alternativa client-side:** si Carlos prefiere evitar Cloud Functions, el backfill se hace en el `userBootstrapProvider` cuando detecta `biometric_history.isEmpty` al primer login post-deploy. Ventaja: cero infra GCP. Desventaja: el usuario "ghost" (no abre la app en meses) no recibe baseline hasta que vuelva.

**Recomendación:** opción client-side por simplicidad. El usuario ghost no necesita backfill — cuando vuelva, recibe baseline + `WeeklyImrSnapshotService.recomputeIfStale` (SPEC-141).

### RF-143-08 — `BiometricDelta.isSignificant` con baseline contextual

El método `isSignificant` recibe el `UserModel` actual como baseline. Compara cada campo del delta con su valor en el baseline. Retorna `true` si AL MENOS UN campo varía más del threshold:

- Peso: 0.5% (sensible — 0.4 kg en 75 kg)
- Cintura: 0.5%
- Cuello: 1.0% (menos sensible — mediciones manuales son ruidosas)
- BodyFat: absoluta 0.5 puntos porcentuales (el % es más volátil)
- isMeasurementEstimated: cualquier toggle es significativo

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear `BiometricHistoryService` | `lib/src/features/progress/application/biometric_history_service.dart` (nuevo) |
| 2 | Crear `BiometricDelta` value object | `lib/src/features/progress/domain/biometric_delta.dart` (nuevo) |
| 3 | Extender `BiometricCheckIn` con `source` y `previousValues` opcionales | `lib/src/features/progress/domain/biometric_checkin.dart` |
| 4 | Extender mapper de `biometric_history` | `lib/src/features/progress/data/biometric_repository.dart` |
| 5 | Subir limit a 365 + parámetro `limitDays` | `lib/src/features/progress/data/biometric_repository.dart` |
| 6 | Migrar callsite de Profile edit | `lib/src/features/auth/presentation/profile_screen.dart` (o donde estén los handlers) |
| 7 | Migrar callsite de BiometricCheckInSheet | `lib/src/features/progress/presentation/biometric_checkin_sheet.dart` |
| 8 | Migrar callsite de Onboarding completion | `lib/src/features/onboarding/application/onboarding_controller.dart` |
| 9 | Migrar callsite de BodyFatCalculator recompute | identificar archivo via grep `BodyFatCalculator` |
| 10 | Expose API para HealthImportService (sin conectar) | `lib/src/features/health_sync/application/health_import_service.dart` (preparar interface) |
| 11 | Crear `imr_history` security rules | `firestore.rules` |
| 12 | Crear índice compuesto en `firestore.indexes.json` | `firestore.indexes.json` |
| 13 | Backfill client-side al bootstrap | `lib/src/core/orchestrator/user_bootstrap_provider.dart` (o equivalente) |
| 14 | Provider para el servicio | `lib/src/features/progress/application/biometric_history_service.dart` (mismo archivo) |

Archivos NO modificados:

- Shape de los pilares (sleep, fasting, nutrition, exercise, hydration) sin cambios.
- `score_engine.dart` sin cambios.
- `streak_engine.dart` sin cambios.
- Tests existentes de `BiometricRepository` siguen pasando.

## 6. Modelo de datos persistente

### 6.1 — `users/{uid}` (doc raíz)

Sin cambios. Sigue siendo la "fuente de valor actual" de los campos biométricos.

### 6.2 — `users/{uid}/biometric_history/{yyyy-MM-dd}` (extendido)

Shape preexistente + campos opcionales nuevos (`source`, `recordedAt`, `previousValues`). Ver §RF-143-03.

### 6.3 — `users/{uid}/imr_history/{weekISO}` (nuevo — SPEC-143 lo crea, SPEC-141 lo escribe)

Ver §RF-143-01.

## 7. Criterios de aceptación

1. Una edición de peso desde Profile dispara escritura a `biometric_history` con `source: 'profile_edit'` antes de 5s.

2. Un check-in desde el sheet escribe con `source: 'checkin_sheet'` (no regresión del comportamiento actual).

3. Múltiples edits en el mismo día sobrescriben el mismo doc PK `yyyy-MM-dd`. Solo queda el último valor. El `previousValues` del doc final apunta a los valores justo antes del último edit.

4. Onboarding completion deja la primera entrada del usuario en `biometric_history` con `source: 'onboarding_baseline'`.

5. `BodyFatCalculator` recompute escribe con `source: 'bodyfat_recompute'` y solo actualiza el campo `bodyFatPercentage` (preserva los demás).

6. Un usuario sin `biometric_history` al primer login post-deploy recibe entrada inicial con `source: 'spec_143_backfill'` y los valores actuales del doc raíz.

7. `BiometricRepository.watchHistory(limitDays: 365)` retorna correctamente entradas hasta 365 días atrás.

8. `BiometricRepository.watchHistory()` sin argumentos usa default 365 (cambio del 90 anterior).

9. `BiometricDelta.isSignificant` retorna false para deltas dentro del threshold (peso ±0.4 kg en 75 kg). Retorna true para deltas mayores.

10. La subcollection `imr_history` existe en `firestore.rules` con las restricciones correctas (solo dueño lee/escribe, validación del rango 0-100).

11. La query `imr_history.orderBy('computedAt', desc).limit(N)` funciona sin requerir declaración explícita en `firestore.indexes.json` (Firestore auto-crea single-field indexes en ambas direcciones).

12. `flutter analyze` sin nuevos issues.

13. `flutter test` mantiene baseline + ≥ 10 tests nuevos (ver §8).

14. Security rules de `imr_history` rechazan escrituras con `totalScore` fuera del rango 0-100 (verificable con emulator test).

15. La doc `users/{uid}/biometric_history/{date}` con `source: null` (legacy) sigue siendo leíble — backward compat.

## 8. Plan de pruebas

### 8.1 — Tests del servicio

`test/features/progress/application/biometric_history_service_test.dart`:

- `updateFromProfileEdit` escribe a ambos lugares (doc raíz + history) atómicamente.
- `updateFromCheckInSheet` preserva el comportamiento actual del repo (no regresión).
- `updateFromHealthKitSync` con delta < 0.5% NO escribe.
- `updateFromHealthKitSync` con delta significativo SÍ escribe.
- `updateFromBodyFatRecompute` solo actualiza el campo `bodyFatPercentage`.
- `writeOnboardingBaseline` crea entrada con `source: 'onboarding_baseline'`.
- Múltiples updates en el mismo día → un solo doc del día, `previousValues` correcto.

### 8.2 — Tests del repo

`test/features/progress/data/biometric_repository_test.dart`:

- `watchHistory(limitDays: 365)` retorna entradas correctamente paginadas.
- Round-trip Firestore → modelo → Firestore preserva `source` y `previousValues`.
- Docs legacy sin `source` se leen como `null` (backward compat).

### 8.3 — Tests de domain

`test/features/progress/domain/biometric_delta_test.dart`:

- `isSignificant` con peso 75.0 vs 75.3 → false (0.4% < 0.5%).
- `isSignificant` con peso 75.0 vs 75.4 → true (0.53% > 0.5%).
- `isSignificant` con cuello 38.0 vs 38.2 → false (0.5% < 1.0% threshold de cuello).
- `isSignificant` con `isMeasurementEstimated` toggle → true.

### 8.4 — Tests de seguridad (emulator)

`test/integration/firestore_rules_imr_history_test.dart`:

- Usuario autenticado puede leer su propio `imr_history`.
- Usuario A NO puede leer `imr_history` de usuario B.
- Escritura con `totalScore: 150` es rechazada.
- Escritura con `totalScore` faltante es rechazada.
- Escritura sin auth es rechazada.

### 8.5 — Tests de integración

`test/integration/profile_edit_versioning_test.dart`:

- Setup: usuario con peso 80 kg.
- Acción: editar a 78 kg desde Profile.
- Verificar: doc raíz actualizado a 78, `biometric_history/{hoy}` creado con `previousValues.weight = 80`, `source: 'profile_edit'`.

## 9. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | Edits biométricos desde callsites no migrados generan inconsistencia (escriben al doc raíz pero no al historial) | Alta | Grep exhaustivo de todos los callsites de `userProfileRepository.update*()` que tocan campos biométricos. Lista en §RF-143-04. CI rule: linter que detecte writes directos al doc raíz tocando campos biométricos (deuda futura). |
| R-02 | WriteBatch falla a medias: doc raíz se actualiza pero historial no | Media | Firestore garantiza atomicidad de WriteBatch dentro del mismo doc/colección. Para writes cross-collection, usar transaction. Decisión: usar `Transaction` para garantía total. Costo extra mínimo. |
| R-03 | Cliente offline: write queda en cola, historial puede llegar antes que doc raíz | Baja | Transaction garantiza orden. Offline queue preserva ordering. Aceptable. |
| R-04 | Backfill client-side al bootstrap genera doble entrada si dos dispositivos abren a la vez | Baja | Set con merge en `biometric_history/{yyyy-MM-dd}` — múltiples writes al mismo doc del día convergen. Es exactamente el caso de "múltiples updates en el mismo día". |
| R-05 | Subir limit a 365 días aumenta egress de lectura | Baja | El stream filtra client-side a 30 días para vistas comunes. El acceso completo de 365 días solo lo dispara SPEC-141 al recomputar — frecuencia semanal. Costo despreciable. |
| R-06 | Índice compuesto `imr_history.computedAt desc` no se publica antes del primer write | Media | Deploy plan: publicar firestore.indexes.json ANTES de habilitar features flag de SPEC-141. Si índice tarda en construirse, las primeras consultas pueden fallar — feature flag de SPEC-141 da margen. |
| R-07 | Filtro de ruido HealthKit (0.5%) silencia cambios reales pequeños | Baja | El threshold se eligió conservador. Si telemetría revela falsos negativos (usuario nota cambios que la app no), ajustar a 0.3%. No es bloqueante. |
| R-08 | `BodyFatCalculator` se invoca con alta frecuencia (cada cambio de cintura → recálculo) y genera ruido en historial | Media | Throttle: si el último write fue hace < 30 segundos con `source: 'bodyfat_recompute'`, sobreescribir el mismo doc del día sin crear `previousValues` nuevo. Implementación en el servicio. |
| R-09 | Documentación bibliográfica no menciona `imr_history` ni el `source` field | Baja | Actualizar `IMR_BIBLIOGRAPHY.md` agregando referencia cruzada a SPEC-143 desde §12 (métricas canónicas). |

## 10. Plan de rollout

1. **Día 0 (post-aprobación):** crear branch `spec/143-persistencia-historica` desde `mvp-core-clean`.
2. **Día 1:** dominio puro — `BiometricDelta`, extender `BiometricCheckIn`. Tests de dominio.
3. **Día 2 — mañana:** crear `BiometricHistoryService` con los 5 métodos. Tests del servicio. Crear `firestore.rules` para `imr_history`. Publicar `firestore.indexes.json`.
4. **Día 2 — tarde:** migrar callsites uno por uno (Profile, Sheet, Onboarding, BodyFatCalculator). Tests de integración por callsite.
5. **Día 3 — mañana:** subir limit a 365 + backfill client-side al bootstrap. Test de emulator para security rules.
6. **Día 3 — tarde:** smoke test end-to-end. Coordinación con sitio web (no consume `imr_history` por ahora, pero notificar de la subcollection nueva por si quieren leerla).
7. **Deploy:** sin feature flag. Es infraestructura aditiva — no rompe nada existente.
8. **+7 días post-deploy:** abrir SPEC-141 IN_PROGRESS, ya con SPEC-143 cerrada como dependencia.

## 11. Out of scope (explícito)

- Cómputo del IMR longitudinal y su persistencia semanal — SPEC-141.
- UI de visualización del historial biométrico expandido (gráficas, comparativas) — deuda existente, SPEC futura.
- UI de visualización del `imr_history` (tendencia del IMR) — SPEC-142.
- Audit trail GDPR-grade (IP, device, justificación) — SPEC futura si hay requisito regulatorio.
- Versionado de `height` — out of scope por baja sensibilidad clínica.
- Persistencia histórica del Score del Día — SPEC-140 ya tendrá su propio almacenamiento, o reutilizará `streak_entry`.
- Listeners de SPEC-132 (HealthKit/HC) conectados al servicio — SPEC-141.2, cuando SPEC-132 cierre.
- Reescritura de subcollections existentes (`sleep_history`, `nutrition_history`, etc.) — fuera de scope, ya funcionan.

## 12. Aprobación

Esta SPEC requiere:

1. **Visto bueno de Carlos** sobre el alcance, la decisión client-side del backfill (vs Cloud Function) y los thresholds del filtro de ruido.
2. **Sin validación clínica externa** — es infraestructura de datos pura, no cambia ningún cálculo clínico.
3. **Coordinación con el equipo del sitio web Metamorfosis Real** notificándoles que `imr_history` existirá. Por ahora no consumen, pero quedan habilitados para hacerlo cuando quieran.

Hasta los dos primeros confirmados, la SPEC permanece DRAFT.

## 13. Changelog

### v1.0 — 2026-06-01

Documento inicial. Cierra dos gaps de la auditoría de persistencia del 2026-06-01: ausencia de `imr_history` y falta de versionado automático de cambios biométricos directos. Bloqueante de SPEC-141 v1.1.

**Aprobación 2026-06-01 (mismo día):** Carlos aprueba las 3 decisiones abiertas:
1. Backfill **client-side al bootstrap** (no Cloud Function). §RF-143-07 confirmado.
2. Threshold de filtro de ruido HealthKit **0.5% por campo individual**. §RF-143-05 confirmado.
3. Notificación al equipo del sitio Metamorfosis Real como tarea de coordinación, no bloqueante.

SPEC pasa de DRAFT a IN_PROGRESS. Implementación arranca en próximo sprint.
