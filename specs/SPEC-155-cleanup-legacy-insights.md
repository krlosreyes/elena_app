# SPEC-155 — Limpieza: eliminar InsightCards legacy de Análisis

**Estado:** CLOSED
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Limpieza Ola 2 — eliminación de duplicación visual
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 15 min
**Marco normativo:** `CONSTITUTION.md`. Elimina componentes de SPEC-113 que quedaron obsoletos tras SPEC-153 y SPEC-154.

---

## 1. Contexto

Validación visual 2026-06-02: Carlos identificó que los 4 `InsightCard` al pie de Análisis "sobran" porque duplican información que ya muestran widgets más potentes.

### 1.1 — Análisis card por card

| Card legacy | Diagnóstico |
|---|---|
| "Tu pilar más constante" | Duplica `WeeklyCoachingCard` (SPEC-153) que ya identifica patrones por pilar con acción y cita. |
| "Tu pilar a trabajar" | Duplica `WeeklyCoachingCard` — éste último es más narrativo (insight + acción + cita) vs. dato crudo. |
| "Tu mejor día" | Información narrativamente débil. "2 jun — IMR 42" no es accionable, es vanidad. |
| "IMR promedio del período" | Duplica `PeriodHeroCard` arriba de la pantalla. |

Decisión Carlos: **eliminar los 4** sin reemplazo (opción A). Análisis queda limpio.

## 2. Cambios técnicos

### 2.1 — `analysis_screen.dart`

- Remover imports de `InsightsService` y `InsightCard`.
- Remover el header `"INSIGHTS"` con su padding.
- Remover el `...InsightsService.generate(mergedDocs).map(...)` que renderiza las 4 cards.

### 2.2 — Archivos huérfanos eliminados

Los siguientes archivos quedaron sin uso tras el cambio y se eliminan del disco:

- `lib/src/features/analysis/application/insights_service.dart`
- `lib/src/features/analysis/presentation/widgets/insight_card.dart`
- `lib/src/features/analysis/domain/insight.dart`
- `test/features/analysis/application/insights_service_test.dart`

Auditoría previa: grep confirmó cero referencias externas. Solo se usaban entre ellos y desde `analysis_screen.dart`.

## 3. Estado final de la pantalla Análisis

5 bloques sin duplicación:

1. `PeriodHeroCard` — IMR del período con delta y mejor/peor día.
2. `ImrTrendChart` — tendencia del IMR.
3. `WeeklyCoachingCard` (SPEC-153) — pilar débil + acción + cita.
4. `GoalsProgressDashboard` (SPEC-154) — plan + progreso por objetivo.
5. `BodyCompositionTrendChart` (SPEC-152) — composición corporal con selector.

## 4. Criterios de aceptación

1. Análisis no muestra header `"INSIGHTS"` ni los 4 cards legacy.
2. Los 4 archivos huérfanos no existen en disco.
3. `flutter analyze` no reporta imports sin resolver.
4. `flutter test` no reporta tests faltantes.

## 5. Out of scope

- `PillarsHeatmap` widget legacy (SPEC-113) — también sin uso pero en archivo separado, decisión de limpieza en SPEC-153.1 si se desea.
- Refactor del orden o spacing de los 5 bloques restantes.

## 6. Rollout

Push directo a `mvp-core-clean`. Validación visual confirmará pantalla limpia.

## 7. Changelog

### v1.0 — 2026-06-02

Limpieza propuesta y ejecutada el mismo día tras validación de Carlos.
