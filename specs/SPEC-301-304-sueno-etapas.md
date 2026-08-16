# SPEC-301 + 304 — Etapas de sueño: capturarlas y mostrar su impacto metabólico

**Estado:** IMPLEMENTED (falta analyze/tests de Carlos y validar en simulador con un dispositivo que mida etapas).
**Fecha:** 2026-08-16
**Rama:** `feat/pilar-alimentacion-minuta`

## Contexto (pedido de Carlos, parte 3)

"Si el usuario tiene un dispositivo que mide su calidad del sueño, el pilar debe
mostrar las etapas que registró, su duración y cómo eso afectó positiva o
negativamente su metabolismo."

## Diagnóstico

El servicio YA pedía las etapas (`SLEEP_DEEP/LIGHT/REM` en iOS; las de HC en
Android) pero `_consolidateSleepByNight` las **colapsaba a una sola cifra** de
minutos, y `SleepLog` no tenía dónde guardarlas. Se leían y se tiraban.

## SPEC-301 — Datos end-to-end

- `SleepStages` (VO puro): minutos por etapa (deep/rem/light/awake), fracciones,
  `hasData`, `fromHealthMap`, toMap/fromMap.
- `HealthSample`: `sleepStage` (muestra individual) + `sleepStages` (mapa de la
  noche consolidada).
- `health_sync_service`: se pide también `SLEEP_AWAKE` (fragmentación; comparte
  el permiso READ_SLEEP, sin prompts nuevos). `_toSample` etiqueta la etapa de
  cada muestra; `_consolidateSleepByNight` **suma minutos por etapa** en vez de
  tirarlos.
- `SleepLog.stages` (opcional) + mapper Firestore (omit-if-null). El import de
  sueño (HealthKit/HC) sella las etapas en el `SleepLog`.
- Tests: `sleep_stages_test.dart` + round-trip de etapas en el mapper.

## SPEC-304 — UI + impacto metabólico con ciencia citada

- `sleep_stage_science.dart`: por etapa, un impacto metabólico con cita
  verificable:
  - Profundo ↔ hormona de crecimiento + sensibilidad a la insulina —
    Tasali et al., PNAS 2008 (suprimir sueño profundo 3 noches bajó ~25% la
    sensibilidad a la insulina).
  - REM ↔ apetito (leptina/grelina) — Spiegel et al., Ann Intern Med 2004.
  - Fragmentación (despertares) ↔ cortisol + insulina — Stamatakis & Punjabi,
    Chest 2010.
  - Ligero — contexto (Carskadon & Dement, 2011).
- `SleepStagesView`: barra proporcional apilada + duración/%% por etapa + un
  **veredicto** derivado de los datos (poco profundo → a cuidar; buen profundo +
  poca fragmentación → positivo) con su cita, y un desplegable "qué significa
  cada etapa". Se cablea en `sleep_pillar_card` bajo el benefit chip y se
  **autooculta** cuando no hay etapas (iPhone sin reloj, manual, estimado).

## SPEC-305 (descartado)
El auto-sync al despertar ya funciona: `resume` → `runNow`; y en arranque en
frío `lastRunAt` es null, así que `runIfDue` ya sincroniza de inmediato. No hace
falta cambio.

## SPEC-302 — Procedencia (fuente) del registro de sueño

Aclaración que quitó riesgo: la regla de Carlos ("Health gana salvo edición
manual") ya se cumple sola — un `SleepLog` manual solo existe si el usuario lo
ingresó (= una edición), así que el guard "manual gana sobre auto" del import ya
respeta la edición manual y deja que el dispositivo mande en el resto. NO se
invierte el guard (lógica de persistencia auditada).

Lo que faltaba era ETIQUETAR la fuente: `SleepSource {device, manual, estimated}`
(`sleep_source.dart`), `SleepLog.source` (default `manual`), mapper (omit-if-
manual), el import de HealthKit/HC/Samsung marca `device`, y un chip
`_SleepSourceChip` en el pilar ("Sincronizado desde tu dispositivo" / "Registro
manual" / "Estimado de tu perfil"). Test de round-trip en el mapper.

Ejercicio ya está etiquetado sin campo nuevo: `ImportedActivitiesSection` muestra
"Importado desde Apple Health" y el pilar tiene su chip de entrada manual —
`ExerciseLog.sourceName` (SPEC-296) ya distingue la fuente.

## Pendiente (siguiente iteración)
- SPEC-303: onboarding pregunta "horas típicas de sueño" → estimado del pilar
  (`SleepSource.estimated`) cuando no hay Health ni registro. Necesita
  `build_runner` (UserModel es Freezed) + tocar el onboarding.

## Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/sleep lib/src/features/health_sync test/features/sleep
flutter test test/features/sleep
```

En simulador/dispositivo con Apple Watch (o datos de etapas en Health): abre el
pilar de Sueño y confirma la barra de etapas + duraciones + el veredicto con
cita. Sin dispositivo de etapas, la sección no aparece (correcto).
