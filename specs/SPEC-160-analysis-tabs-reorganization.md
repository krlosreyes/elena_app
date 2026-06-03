# SPEC-160 — Reorganización de Análisis con tabs por intención

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Reorganización UX — cero lógica nueva
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 1-2 horas
**Marco normativo:** `CONSTITUTION.md`. NO modifica widgets existentes — solo los reorganiza.

---

## 1. Contexto

Tras cerrar SPEC-152 a SPEC-159 (8 SPECs hoy), la pantalla Análisis acumuló 8 cards verticales:

```
1. PeriodHeroCard
2. ImrTrendChart
3. WeeklyCoachingCard
4. GoalsProgressDashboard
5. CyclesHistoryCard
6. MealsRatioCard
7. SleepQualityCard
8. BodyCompositionTrendChart
```

Carlos identificó el problema el 2026-06-02: "es complicada — sería más fluido en un solo espacio con pestañas para navegar". Diagnóstico técnico de por qué falla:

1. **Sin jerarquía narrativa.** Resumen y deep dive contiguos compiten al mismo volumen.
2. **Scroll largo.** ~3-4 scrolls completos en iPhone Pro Max.
3. **Sin foco al abrir.** El usuario no sabe qué mirar primero.
4. **Mezcla de dimensiones.** Ayuno, Nutrición, Sueño, Composición consecutivos como si fueran lo mismo.
5. **Sin retorno fácil al "punto importante".**

Investigación de patrones (Apple Health, Whoop, Levels, Oura) confirma: **un tab muestra UNA cosa con foco**.

## 2. Decisión de diseño

### 2.1 — 3 tabs por intención narrativa

```
┌────────────────────────────────────┐
│  ANÁLISIS                  📅      │ ← AppBar existente
├────────────────────────────────────┤
│  [Resumen]  Pilares   Tendencia    │ ← TabBar
├────────────────────────────────────┤
│  (contenido del tab activo)        │
└────────────────────────────────────┘
```

**Tab 1 — Resumen (default).** Lo motivacional, vista por defecto.
- `PeriodSelector` (Semana / Mes / 3 Meses)
- `PeriodHeroCard`
- `WeeklyCoachingCard`
- `GoalsProgressDashboard`

**Tab 2 — Pilares.** Deep dive con chip-selector interno.
- `[Ayuno] Nutri Sueño Cuerpo` chips
- Una sola card visible según chip seleccionado:
  - Ayuno → `CyclesHistoryCard`
  - Nutri → `MealsRatioCard`
  - Sueño → `SleepQualityCard`
  - Cuerpo → `BodyCompositionTrendChart`

**Tab 3 — Tendencia.** Longitudinal del IMR.
- `PeriodSelector`
- `ImrTrendChart`

### 2.2 — Selector global vs local

El `PeriodSelector` aparece **dentro** de Resumen y Tendencia, no en el AppBar global. Razón: en Pilares no aplica (cada card tiene su propio período interno: 30/60/90 para composition, 7d fijo para meals/sleep/cycles). Selector global generaría confusión: "¿por qué cambié a 3 meses y mi distribución A:E sigue siendo semanal?".

### 2.3 — Persistencia del tab activo

**NO se persiste entre sesiones.** Cada vez que abrís Análisis arrancás en Resumen. Razón: la mayoría de visitas son "¿cómo voy?" → Resumen sirve para eso. Si querías ir a Pilares > Sueño, 2 taps no es fricción real.

El chip activo dentro de Pilares también arranca siempre en Ayuno (orden de pilares del producto). Coherente con el patrón.

### 2.4 — Animación de transición

`TabBarView` con `physics: PageScrollPhysics()` permite swipe horizontal entre tabs. Slide horizontal estándar Material. Familiar para todo usuario Android/iOS. Coherente con bottom nav existente.

### 2.5 — `KeepAlive` para no perder suscripciones

Cada tab envuelve su contenido en `AutomaticKeepAliveClientMixin` para que los `StreamProvider` y estado local (chip activo, período seleccionado) no se desmonten al cambiar de tab. Cambio rápido sin re-fetch ni flash visual.

Trade-off: más memoria. Aceptable porque los providers son `autoDispose` — se liberan cuando el usuario sale de Análisis.

### 2.6 — Calendario mensual sigue accesible

El icon `calendar_month_rounded` del AppBar abre `MonthlyCalendarScreen` como hoy. Es navegación lateral, no compite con los tabs.

## 3. Cambios técnicos

### 3.1 — 3 widgets nuevos de tab

`lib/src/features/analysis/presentation/tabs/analysis_summary_tab.dart`:
- ConsumerStatefulWidget con `AutomaticKeepAliveClientMixin`.
- State local: `AnalysisPeriod _period`.
- Renderiza PeriodSelector + PeriodHeroCard + WeeklyCoachingCard + GoalsProgressDashboard.

`lib/src/features/analysis/presentation/tabs/analysis_pillars_tab.dart`:
- ConsumerStatefulWidget con `AutomaticKeepAliveClientMixin`.
- State local: enum `_ActivePillar { fasting, nutrition, sleep, body }`.
- Chip selector + switch que muestra una card según pillar activo.

`lib/src/features/analysis/presentation/tabs/analysis_trend_tab.dart`:
- ConsumerStatefulWidget con `AutomaticKeepAliveClientMixin`.
- State local: `AnalysisPeriod _period`.
- Renderiza PeriodSelector + ImrTrendChart con la lógica de merge existente.

### 3.2 — Refactor de `analysis_screen.dart`

- Pasa de `ConsumerStatefulWidget` con scroll vertical a `ConsumerStatefulWidget with TickerProviderStateMixin`.
- `TabController` con 3 tabs y `initialIndex: 0`.
- AppBar mantiene título + icon calendario.
- `TabBar` material debajo del AppBar.
- `TabBarView` con los 3 widgets de §3.1.
- BottomNavigationBar mantiene como está.

### 3.3 — Cero cambios en los 8 widgets de cards

`PeriodHeroCard`, `WeeklyCoachingCard`, etc. quedan intactos. SPEC-160 es puramente de orquestación visual.

### 3.4 — Lógica de merge live → re-ubicación

El `_mergeWithLive` actual de `analysis_screen.dart` (que mezcla `dailySummaryProvider` con los docs persistidos para no esperar el debounce de 30s del día actual) se mueve a `analysis_summary_tab.dart` y `analysis_trend_tab.dart` — ambos lo usan.

Alternativa más limpia: extraer `_mergeWithLive` a un helper compartido en `lib/src/features/analysis/application/merge_with_live.dart`. **Sí lo extraemos** para no duplicar.

## 4. Criterios de aceptación

1. Al abrir Análisis, el usuario ve el tab Resumen activo con las 3 cards motivacionales.
2. Swipe horizontal o tap en tab cambia la vista sin flash de loading.
3. Tab Pilares muestra 4 chips (Ayuno default) y una card según selección.
4. Tab Tendencia muestra el ImrTrendChart con selector temporal.
5. Calendario sigue accesible desde el icon del AppBar.
6. Bottom nav (Hoy / Análisis / Perfil) no cambia.
7. Cambiar de tab y volver mantiene el período / chip seleccionado (KeepAlive).
8. Salir de Análisis y volver arranca en Resumen + chip Ayuno (no persiste entre sesiones).

### 4.1 — Sobre tests

Reorganización visual sin lógica nueva. Tests existentes de los widgets siguen aplicando. Validación visual en device confirma navegación.

## 5. Out of scope

- **Persistir tab activo entre sesiones.** Descartado en §2.3.
- **Bottom navigation interna estilo Oura** (rechazada por chocar con bottom nav global).
- **Selector global de período en AppBar** (rechazado en §2.2).
- **Sub-tabs de Pilares con más niveles** — si emerge otro pilar (HRV / estrés), se agrega otro chip, no otro nivel.
- **Animación custom** entre tabs — se usa el Material default.

## 6. Rollout

Sin breaking changes. Sin migración. Push directo + validación visual.

## 7. Changelog

### v1.0 — 2026-06-02

Reorganización tras feedback honesto de Carlos. Convierte 8 cards verticales en 3 tabs con foco narrativo.
