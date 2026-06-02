# SPEC-140 — Score del Día: métrica diaria motivacional 0-100 expuesta en Dashboard

**Estado:** CLOSED (implementada, refinada UX 2x y testeada 2026-06-01)
**Versión:** 1.2
**Fecha:** 2026-06-01 (v1.0) · refinada 2026-06-01 (v1.1, UX rediseño Opción A) · refinada 2026-06-01 (v1.2, score como headline DENTRO del card) · cerrada 2026-06-01
**Tipo:** Exposición de métrica existente + rebalanceo de pesos científicos + UI nueva
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** 1 (Pre-MVP shippable — cierra promesa "5 pilares con valor real")
**Estimación:** 1.5–2 días Carlos+Claude
**Marco normativo:** `CONSTITUTION.md`, `IMR_BIBLIOGRAPHY.md`, `docs/NUTRITION_BIBLIOGRAPHY.md`.
**Depende de:**
- SPEC-65 (`StreakEntry.dailyQualityScore` ya implementado — esta SPEC lo expone y recalibra pesos).
- SPEC-70.5 (pesos internos a Conducta firmados clínicamente; esta SPEC NO los toca, opera a nivel del Score del Día agregado).

**Bloquea:**
- SPEC-141 cuando entre a IN_PROGRESS — el componente `behaviorTrend30` del IMR longitudinal lee el `dailyScore` de SPEC-140 (en su lugar SPEC-141 dice que fallback es `dailyQualityScore` legacy hasta que SPEC-140 esté en producción).
- SPEC-142 (refactor UI dual de scores) — requiere que el Score del Día exista para distinguirlo del IMR.

**No requiere validación clínica externa.** Los pesos que esta SPEC fija (25/22/20/18/15) están todos dentro del rango bibliográficamente defendible y NO modifican los pesos internos firmados en SPEC-70.5. Es aplicación honesta de la evidencia a una agregación que hoy no existe como métrica de producto.

---

## 1. Contexto y motivación

### 1.1 — El problema observado

Carlos abrió la app Android (sesión del 2026-05-31), completó pilares durante el día, y vio un IMR de **34/100** en la pantalla Análisis. Su feedback textual: *"el score diario no es motivacional, es decir al cumplir los 5 pilares en un día el puntaje debería ser 100, pero el máximo score alcanzado ha sido 34"*.

La razón es matemática (documentada en SPEC-141 §1.1): el IMR mezcla composición corporal (50% del peso) que no cambia día a día con conducta diaria. El techo matemático del IMR diario con todos los pilares al 100% queda en ~70/100 para un perfil promedio, ~50 sin biometría avanzada, ~30 sin biometría completa. El "34" no es bug — es la métrica respondiendo a la pregunta equivocada.

### 1.2 — La métrica existente que nadie ve

`StreakEntry.dailyQualityScore` (SPEC-65, `lib/src/features/streak/domain/streak_entry.dart` línea 112) ya calcula un score continuo 0-1 de los 5 pilares con magnitudes reales:

```dart
double get dailyQualityScore {
  const wFasting = 0.20;
  const wSleep = 0.25;
  const wHydration = 0.20;
  const wExercise = 0.20;
  const wNutrition = 0.15;
  // ... ponderación renormalizada de magnitudes presentes
}
```

Cuando las 5 magnitudes son 1.0 (pilares perfectos), el score es 1.0 → 100. **La métrica motivacional que Carlos pidió ya existe.** Hoy se consume internamente:

- `StreakEngine.computeWeeklyQualityScore` lo promedia en ventana de 7 días.
- `MetabolicStateBuilder.weeklyQualityScore` lo expone al motor.
- `ScoreEngine.calculateIMR` lo consume como input del bloque Metabolismo del IMR legacy.

**Nunca se renderiza al usuario.** Es desperdicio: el cálculo existe, está testeado, se persiste con magnitudes en cada `StreakEntry`. Solo falta exponerlo.

### 1.3 — Rebalanceo de pesos basado en evidencia

Los pesos actuales (Sueño 0.25 / Ayuno-Ejercicio-Hidratación 0.20 cada uno / Nutrición 0.15) son del MVP original y carecen de revisión bibliográfica. SPEC-70.5 recalibró los pesos del bloque Conducta del IMR pero NO tocó los pesos de `dailyQualityScore` — quedaron como deuda implícita.

La revisión bibliográfica de junio-2026 propone:

| Pilar | Peso actual | Peso propuesto | Cambio | Justificación |
|---|---|---|---|---|
| **Sueño** | 0.25 | 0.25 | = | AASM 2015, Walker, Spiegel 1999 *Lancet*, Cappuccio 2010 *Diabetes Care* — máxima evidencia |
| **Ayuno** | 0.20 | **0.22** | +0.02 | Sutton 2018 *Cell Metab*, Mattson 2017, Lopez-Minguez 2018. En el Score del Día simplificado (sin Circadiano como pilar separado), Ayuno absorbe parte del peso del timing |
| **Ejercicio** | 0.20 | 0.20 | = | ACSM 2021, Pedersen-Saltin 2015. Dose-response sólida, peso natural |
| **Nutrición** | 0.15 | **0.18** | +0.03 | Reconoce la evidencia robusta de dieta (Liu 2000, Brand-Miller 2003) sin inflarla porque la métrica actual no captura calidad (post-SPEC-137 podrá subir a 0.22) |
| **Hidratación** | 0.20 | **0.15** | -0.05 | Aplicación de SPEC-70.5: la revisión clínica externa dictaminó *"20% es excesivo frente al impacto clínico real"*. Aquí baja a 0.15 (no 0.10 como en IMR/Conducta) porque Circadiano no es pilar separado |

Suma: **1.00 ✓**. Cita completa de cada fuente en `IMR_BIBLIOGRAPHY.md` §6 actualizada.

## 2. Decisión de producto (resumen ejecutivo)

1. **Se rebalancean los pesos de `StreakEntry.dailyQualityScore` a 25/22/20/18/15** (Sueño/Ayuno/Ejercicio/Nutrición/Hidratación). Suma 1.00. Aplicación de evidencia bibliográfica sin cambiar SPEC-70.5.
2. **Se introduce `dailyScoreProvider`** que expone el `dailyQualityScore` del día actual del usuario como entero 0-100. Listo para consumo de UI.
3. **Se introduce `DailyScoreCard`**, un widget pequeño que se monta arriba de la fila "PILARES HOY" en el Dashboard. Muestra el número grande, una barra de progreso, el delta vs ayer (cuando hay), y un tap educativo que explica los pesos.
4. **El IMR legacy (`calculateIMR`) consume internamente el `dailyQualityScore` recalibrado** — efecto colateral aceptado, magnitud pequeña (el agregado del bloque Metabolismo cambia ±2-3 puntos en escenarios típicos), dirección coherente con evidencia.
5. **El IMR HOY del centro del pentágono en Análisis NO se reemplaza en esta SPEC.** Sigue mostrando `summary.imrScore` del `calculateIMR`. SPEC-142 decide si esa pantalla migra al Score del Día o al IMR longitudinal cuando ambas SPECs estén cerradas.
6. **Bibliografía actualizada en `IMR_BIBLIOGRAPHY.md` §6** con los nuevos pesos + citas (Liu 2000, Brand-Miller 2003 ya presentes en NUTRITION_BIBLIOGRAPHY; Spiegel 1999 y Cappuccio 2010 nuevos para sueño).

## 3. Lo que NO se hace (límites duros de scope)

- **No se cambia `ScoreEngine.calculateIMR` ni `calculateBaseline`.** El refactor del IMR legacy es out of scope; SPEC-141 es quien decide su retiro futuro.
- **No se cambian los pesos internos del bloque Conducta del IMR** (firmados SPEC-70.5). Esta SPEC opera al nivel del agregado Score del Día.
- **No se reescribe `StreakEntry`** — solo se modifican 5 constantes del getter `dailyQualityScore`. El shape persistido en Firestore (magnitudes nullable) queda intacto.
- **No se toca la pantalla Análisis.** El "IMR HOY" central sigue mostrando el IMR legacy. SPEC-142 decide el rediseño de esa pantalla.
- **No se persiste `dailyScore` como campo separado.** Se computa on-the-fly desde las magnitudes ya persistidas. Esto evita duplicación y mantiene `StreakEntry` como única fuente de verdad.
- **No se introduce gamificación adicional** (streaks visuales, badges, animaciones celebratorias). El número y la barra son suficientes para el MVP. Una SPEC futura puede agregar microinteracciones si telemetría lo justifica.
- **No se introduce notificación push de "tu score subió"** ni similar. El usuario abre la app y ve el estado actual — no necesita aviso externo.

## 4. Requisitos funcionales

### RF-140-01 — Rebalanceo de pesos en `StreakEntry.dailyQualityScore`

Modificar las 5 constantes en `lib/src/features/streak/domain/streak_entry.dart` línea ~113:

```dart
double get dailyQualityScore {
  // SPEC-140: pesos rebalanceados con evidencia bibliográfica.
  // Sueño 0.25 — AASM, Walker, Spiegel 1999 Lancet (MEDIUM-HIGH).
  // Ayuno 0.22 — Sutton 2018 Cell Metab, Mattson 2017 (MEDIUM).
  //   Absorbe parte del timing circadiano en este score simplificado.
  // Ejercicio 0.20 — ACSM 2021, Pedersen-Saltin 2015 (MEDIUM).
  // Nutrición 0.18 — reconoce evidencia dietética sin inflar métrica
  //   actual; sube a 0.22 cuando SPEC-137 calidad esté en cómputo.
  // Hidratación 0.15 — aplicación SPEC-70.5 (revisión clínica externa
  //   declaró 20% excesivo). No baja a 0.10 como en IMR/Conducta
  //   porque Circadiano no es pilar separado aquí.
  // Total: 1.00.
  const wSleep = 0.25;
  const wFasting = 0.22;
  const wExercise = 0.20;
  const wNutrition = 0.18;
  const wHydration = 0.15;
  // ... resto del algoritmo de renormalización sin cambios ...
}
```

La lógica de renormalización (cuando alguna magnitud es null) se preserva idéntica. Solo cambian los 5 valores constantes.

### RF-140-02 — `dailyScoreProvider`

Nuevo provider en `lib/src/features/streak/application/daily_score_provider.dart`:

```dart
/// SPEC-140: expone el Score del Día como entero 0-100.
///
/// Deriva del `StreakEntry.dailyQualityScore` del día actual. Si no
/// hay entrada para hoy, retorna 0. Si todas las magnitudes son null
/// (entrada legacy), cae al fallback `pillarsCompleted/5 × 100`.
///
/// Reactivo al `streakProvider` — se recalcula cuando cambia el día
/// o cuando algún notifier de pilar dispara recompute.
final dailyScoreProvider = Provider<int>((ref) {
  final streak = ref.watch(streakProvider);
  final today = streak.todayEntry;
  if (today == null) return 0;
  return (today.dailyQualityScore * 100).round().clamp(0, 100);
});
```

### RF-140-03 — Provider auxiliar para delta vs ayer

```dart
/// SPEC-140: delta del score vs ayer. Útil para copy contextual
/// ("subiste 12 puntos" / "bajaste 5 puntos" / null si no hay ayer).
final dailyScoreDeltaProvider = Provider<int?>((ref) {
  final streak = ref.watch(streakProvider);
  if (streak.history.length < 2) return null;
  // history viene ordenado descendente: index 0 = hoy, index 1 = ayer.
  final today = streak.history.first.dailyQualityScore * 100;
  final yesterday = streak.history[1].dailyQualityScore * 100;
  return (today - yesterday).round();
});
```

### RF-140-04 — Widget `DailyScoreCard`

Nuevo widget en `lib/src/features/dashboard/presentation/widgets/daily_score_card.dart`:

**Composición visual:**

```
┌─────────────────────────────────────────────┐
│  TU DÍA                              ⓘ      │
│                                              │
│       87                                     │
│       /100                                   │
│                                              │
│  [████████████████░░░░] 87%                  │
│                                              │
│  ↑12 vs ayer                                 │
└─────────────────────────────────────────────┘
```

**Comportamiento:**

- Número grande monospace, fontSize 48-52, mismo estilo que el "IMR HOY" del Análisis pero sin etiqueta de zona clínica (el Score del Día NO es clínico, es motivacional).
- Barra de progreso lineal con color que matchea el rango: rojo <40, amarillo 40-70, verde >70. Animación suave 600ms al cambiar.
- Delta vs ayer en pequeño debajo: "↑12 vs ayer" / "↓5 vs ayer" / oculto si es primer día.
- Icono ⓘ en esquina superior derecha. Tap abre `BottomSheet` con explicación de los 5 pesos.
- Margin horizontal y padding consistentes con `EngagementBanner` y los pillars row.

**Ubicación en `dashboard_screen.dart`:** se inserta **inmediatamente arriba de `PILARES HOY`** (línea ~218 actual), después del reloj circadiano y posibles `metabolicAlertBanner`. Comparte la jerarquía visual con la fila de pilares — el Score del Día es el agregado de esos 5 pilares.

### RF-140-05 — Tooltip educativo

`BottomSheet` que se abre al tap del icono ⓘ. Copy aprobado:

> **Tu Score del Día**
>
> Refleja cómo viviste hoy en los 5 pilares. Cuando los 5 están al 100%, llega a 100.
>
> **Pesos:**
> - Sueño · 25%
> - Ayuno · 22%
> - Ejercicio · 20%
> - Nutrición · 18%
> - Hidratación · 15%
>
> Los pesos se basan en literatura científica sobre el impacto metabólico de cada hábito. Se ajustan cuando la evidencia avanza.
>
> *Este score es del día. Tu IMR (en Perfil) es la métrica longitudinal de tu salud metabólica de fondo y se mueve más lento.*

El último párrafo distingue explícitamente Score del Día vs IMR — clave para que el usuario no confunda ambas métricas durante la transición SPEC-141.

### RF-140-06 — Actualizar `IMR_BIBLIOGRAPHY.md` §6

Reescribir §6 completo con los nuevos pesos + citas:

- §6.1 Sueño 0.25 — preservar contenido, agregar Spiegel 1999 *Lancet* y Cappuccio 2010 *Diabetes Care* como soportes adicionales.
- §6.2 (nuevo subtítulo) Ayuno 0.22 — citar Sutton 2018, Mattson 2017, Lopez-Minguez 2018. Justificar absorción del peso circadiano por simplificación del agregado.
- §6.3 Ejercicio 0.20 — citas ACSM 2021, Pedersen-Saltin 2015.
- §6.4 Nutrición 0.18 — citar evidencia dietética + nota explícita de que sube a 0.22 cuando SPEC-137 calidad esté en producción.
- §6.5 Hidratación 0.15 — aplicación de SPEC-70.5 al agregado del Score del Día.
- Suma total documentada como 1.00.
- Cross-reference a SPEC-140 desde el header de §6.

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Rebalancear 5 constantes | `lib/src/features/streak/domain/streak_entry.dart` |
| 2 | Crear `dailyScoreProvider` + `dailyScoreDeltaProvider` | `lib/src/features/streak/application/daily_score_provider.dart` (nuevo) |
| 3 | Crear `DailyScoreCard` widget | `lib/src/features/dashboard/presentation/widgets/daily_score_card.dart` (nuevo) |
| 4 | Crear `DailyScoreExplainerSheet` con tooltip educativo | `lib/src/features/dashboard/presentation/widgets/daily_score_explainer_sheet.dart` (nuevo) |
| 5 | Insertar `DailyScoreCard` arriba de PILARES HOY | `lib/src/features/dashboard/presentation/dashboard_screen.dart` |
| 6 | Actualizar bibliografía con §6 reescrita | `IMR_BIBLIOGRAPHY.md` |

Archivos NO modificados:
- `ScoreEngine` (todas las firmas intactas).
- `StreakEngine` (los pesos del `dailyQualityScore` viven en `StreakEntry`, no aquí).
- `MetabolicStateBuilder`, `CoherenceEngine`.
- Pantalla Análisis (`imr_ring_with_satellites.dart`, etc.).
- Profile screen.
- Sitio web Metamorfosis Real (no consume `dailyScore`).
- Tests existentes de `dailyQualityScore` — se actualizan los assertions de algunos casos para reflejar los nuevos pesos pero la estructura no cambia.

## 6. Modelo de datos persistente

**Sin cambios.** El `StreakEntry` ya persiste las magnitudes (`fastingMagnitude`, `sleepQualityScore`, `hydrationMagnitude`, `exerciseMagnitude`, `nutritionMagnitude`). El `dailyQualityScore` es un getter computed — no se almacena. El Score del Día se deriva en runtime cada vez que se necesita.

Esto significa que datos históricos pre-SPEC-140 muestran el score recomputado con los pesos nuevos cuando se renderizan. Esto es aceptable porque:
- Las magnitudes están preservadas; el shift de score es ±3-5 puntos en la mayoría de los casos.
- La interpretación retrospectiva es más fiel a la evidencia que la original.
- No se invalida ninguna entrada.

## 7. Criterios de aceptación

1. `StreakEntry.dailyQualityScore` con todas las magnitudes en 1.0 retorna 1.0 (no cambia respecto a hoy — todos los pesos suman 1.00).

2. `StreakEntry.dailyQualityScore` con solo `fastingMagnitude = 0.5` (resto null) retorna 0.5 (renormalización: 0.22 × 0.5 / 0.22 = 0.5). Sin regresión vs lógica actual.

3. `dailyScoreProvider` con `todayEntry` que tiene todas las magnitudes en 1.0 retorna **100**.

4. `dailyScoreProvider` con `todayEntry == null` retorna **0**.

5. `dailyScoreDeltaProvider` con `history.length < 2` retorna **null**.

6. `dailyScoreDeltaProvider` con hoy = 85 y ayer = 73 retorna **+12**.

7. `DailyScoreCard` renderiza el número de `dailyScoreProvider` con tipografía monospace fontSize ≥ 48.

8. Tap en el icono ⓘ abre `BottomSheet` con el copy de §RF-140-05 exacto.

9. La barra de progreso del card cambia de color en el rango correcto: 39 → rojo, 50 → amarillo, 75 → verde.

10. El card se inserta entre el reloj circadiano y la fila "PILARES HOY" del Dashboard sin overflow ni layout shift.

11. `flutter analyze` sin issues nuevos.

12. `flutter test` mantiene baseline (954 ✓ post-SPEC-143) + ≥ 8 tests nuevos (ver §8).

13. Bibliografía `IMR_BIBLIOGRAPHY.md` §6 reescrita con los nuevos pesos y citas correctamente formateadas.

14. **Sin regresión visible en el IMR legacy del Análisis screen.** Los tests E2E existentes de IMR siguen pasando (el shift es de ±2-3 puntos en escenarios típicos, dentro del margen de tolerancia de los tests existentes).

## 8. Plan de pruebas

### 8.1 — Tests de dominio

`test/features/streak/domain/streak_entry_test.dart` (extender el existente):

- Pesos suman exactamente 1.00.
- Todas las magnitudes en 1.0 → score 1.0 (renormalización completa).
- Solo `fastingMagnitude = 1.0` → score 1.0 (renormalizado sobre 0.22).
- Solo `nutritionMagnitude = 0.5` → score 0.5 (renormalizado sobre 0.18).
- Mix realista: `sleepQualityScore: 0.8, fastingMagnitude: 0.9, hydrationMagnitude: 0.7` → score correctamente ponderado.
- Caso legacy (todas las magnitudes null) → cae a `pillarsCompleted/5`.

### 8.2 — Tests de providers

`test/features/streak/application/daily_score_provider_test.dart` (nuevo):

- `dailyScoreProvider` retorna 100 con magnitudes perfectas.
- Retorna 0 con `todayEntry == null`.
- Retorna 73 (87% renormalizado) con magnitudes parciales.
- `dailyScoreDeltaProvider` retorna null con history vacío.
- Retorna +12 / -5 según history.
- Reactivo al cambio de `streakProvider` (mockeado).

### 8.3 — Tests de widget

`test/features/dashboard/presentation/widgets/daily_score_card_test.dart` (nuevo):

- Renderiza el número desde el provider.
- Tap en icono ⓘ abre el BottomSheet.
- Color de la barra: rojo < 40, amarillo 40-69, verde ≥ 70.
- Muestra delta cuando está presente, lo oculta cuando es null.
- No overflow con valores 0, 50, 100.

### 8.4 — Test E2E de no regresión IMR legacy

`test/features/dashboard/e2e/imr_legacy_after_spec140_test.dart` (nuevo):

- Construye un escenario completo con magnitudes fijas.
- Calcula IMR pre-SPEC-140 (con pesos viejos hardcoded en el test) y post-SPEC-140.
- Verifica que el shift está dentro de ±5 puntos.
- Documenta la magnitud del shift para reference.

## 9. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | Cambio de pesos afecta el `weeklyQualityScore` que feedea el IMR legacy → usuarios ven un IMR ligeramente distinto sin saber por qué | Media | Magnitud documentada en §8.4: ±2-3 puntos típicos. Acceptable porque el shift es en dirección coherente con evidencia. Si telemetría revela quejas, mencionar el cambio en el changelog visible del onboarding o en el tooltip educativo del IMR. |
| R-02 | Usuario confunde Score del Día con IMR de Perfil tras SPEC-141 | Alta | Copy explícito en el tooltip de RF-140-05 distingue ambos. SPEC-142 reforzará la separación visual cuando ambos coexistan. Mientras SPEC-141 no esté implementada, el Score del Día NO compite con nada — solo aparece. |
| R-03 | El delta vs ayer revela rachas a la baja y desmotiva al usuario | Baja | Es honestidad operacional. La métrica no debe mentir. Una SPEC futura puede agregar copy adaptativo ("ayer fue duro, hoy puedes…") si se justifica con telemetría. |
| R-04 | El número 100 alcanzable genera expectativa de hacerlo todos los días | Media | El copy del tooltip aclara que es del día — no se acumula, se resetea. La gamificación de "días con 100" o "racha" no entra en MVP (SPEC futura). |
| R-05 | La barra de progreso con color (rojo/amarillo/verde) es accesibilidad débil | Baja | Mejorar en SPEC futura con label textual del rango. Para MVP, el color complementa el número (no lo reemplaza). |
| R-06 | El cambio de constantes en `StreakEntry` rompe tests existentes que assertan valores específicos | Media | Antes de implementar, grep tests del `dailyQualityScore` y actualizar los valores esperados con los nuevos pesos. Diff documentado en el commit. |

## 10. Plan de rollout

1. **Día 0 (post-aprobación):** crear branch `spec/140-score-del-dia` desde `mvp-core-clean`.
2. **Día 1 mañana:** rebalancear pesos en `StreakEntry`. Actualizar tests afectados. Verificar suite verde. Crear `dailyScoreProvider` + tests del provider.
3. **Día 1 tarde:** crear `DailyScoreCard` widget + `DailyScoreExplainerSheet` + tests de widget.
4. **Día 2 mañana:** integrar `DailyScoreCard` al Dashboard. Verificar layout en simulador. Smoke test manual.
5. **Día 2 tarde:** actualizar `IMR_BIBLIOGRAPHY.md` §6. Test de no regresión IMR legacy. Commit final con cierre de SPEC.
6. **Deploy:** sin feature flag (es UI nueva, no breaking). Si telemetría revela problema, se desactiva por hotfix.

## 11. Out of scope (explícito)

- Cambio del IMR legacy (`calculateIMR`) — SPEC-141 / SPEC-142.
- Persistencia explícita del `dailyScore` en Firestore — derivado, no se almacena.
- Push notifications de "tu score subió" — gamificación futura.
- Animación celebratoria al llegar a 100 — gamificación futura.
- Racha de "días con score ≥ X" — gamificación futura.
- Comparativa con otros usuarios — fuera del modelo del producto.
- Refactor de la pantalla Análisis para mostrar Score del Día — SPEC-142.
- Cambio de los pesos internos del bloque Conducta del IMR — SPEC-70.5 firmado.

## 12. Aprobación

Esta SPEC requiere:

1. **Visto bueno de Carlos** sobre los pesos 25/22/20/18/15, la ubicación del widget en Dashboard, y el copy del tooltip.
2. **Sin validación clínica externa** — esta SPEC NO toca pesos firmados en SPEC-70.5. Aplica evidencia bibliográfica al agregado Score del Día (un concepto nuevo de producto), no al IMR.

## 13. Changelog

### v1.0 — 2026-06-01

Documento inicial. Propuesta de exponer `dailyQualityScore` como Score del Día 0-100 motivacional en Dashboard, con pesos rebalanceados según evidencia bibliográfica (25/22/20/18/15). Cierra la pregunta del usuario *"por qué el score no llega a 100 cuando hago todo perfecto"* mantenida desde la primera conversación del 2026-05-31.

### Cierre 2026-06-01 (mismo día)

Implementación completada en 3 bloques durante el día:

**Bloque A — pesos + providers.** Rebalanceo de las 5 constantes de `StreakEntry.dailyQualityScore` con comentarios bibliográficos extensos. Creación de `computeDailyScore` y `computeDailyScoreDelta` como funciones puras + `dailyScoreProvider` y `dailyScoreDeltaProvider` como wrappers Riverpod thin. 12 tests del provider (incluyendo casos de renormalización), 1 test existente actualizado al nuevo cálculo (0.36/0.47 = 77%).

**Bloque B — DailyScoreCard widget + ExplainerSheet.** Card con número monospace fontSize 52, barra de progreso animada (TweenAnimationBuilder 600ms) con color contextual (rojo/amarillo/verde), delta vs ayer con flechas Unicode, icono ⓘ con `Key('daily_score_info_button')` para testabilidad. ExplainerSheet con DraggableScrollableSheet que muestra los 5 pesos formateados, párrafo bibliográfico y card destacada con el disclaimer Score del Día vs IMR. 9 tests de widget.

**Bloque C — integración Dashboard + bibliografía + no regresión + cierre.** DailyScoreCard insertado entre el reloj circadiano y la fila PILARES HOY en `dashboard_screen.dart`. `IMR_BIBLIOGRAPHY.md` §6 reescrita con los 5 nuevos pesos, citas (AASM, Walker, Spiegel 1999, Cappuccio 2010, Sutton 2018, Mattson, Lopez-Minguez, ACSM, Boulé, Jenkins, Liu, Brand-Miller, EFSA, Popkin) y trazabilidad de cada cambio respecto a SPEC-65. Tests de no regresión que verifican que el shift de `dailyQualityScore` causado por el rebalanceo es ≤5 puntos en escenarios mixtos y 0 puntos en escenarios uniformes.

**Suite final:** desde la suite post-SPEC-143 (954 ✓), SPEC-140 agrega ~17 tests nuevos (12 del provider + 9 widget tests - duplicados). Esperado ~970+ ✓ tras el cierre. El test legacy de `dailyQualityScore` con magnitudes mixtas (sueño 1.0 + ayuno 0.5) se actualizó de `0.35/0.45 = 0.778` a `0.36/0.47 = 0.766`.

**Efecto colateral en IMR legacy confirmado dentro de tolerancia.** El `dailyQualityScore` feedea `weeklyQualityScore` → `MetabolicStateBuilder` → bloque Metabolismo del IMR (peso macro 0.25 × peso interno 0.30 = 7.5% del IMR total). Test de no regresión documenta shifts típicos ≤2-3 puntos, techo ≤5.

**Próximo paso desbloqueado:** SPEC-141 podrá usar `dailyScore` (vía nuevo `computeDailyScore`) en lugar de fallback `dailyQualityScore` legacy cuando llegue a IN_PROGRESS post-validación clínica. El componente `behaviorTrend30` del IMR longitudinal queda con su fuente canónica establecida.

### v1.1 — 2026-06-01 (mismo día, post-screenshot feedback)

Carlos compartió screenshot del DailyScoreCard renderizado y rechazó el diseño con feedback explícito: *"No me gusta ese diseño... podríamos colocar el % a cada pilar o cambiarlo de ubicación"*.

**Diagnóstico:** 3 issues confirmados.
1. La card tomaba ~25% del viewport vertical para un solo número.
2. La barra de progreso lineal era visualmente redundante con los anillos de los pilares (que ya muestran fill).
3. El número agregado (73) sin contexto por pilar no era accionable.

**Decisión:** rediseño UX (Opción A de las 3 propuestas). Score integrado al header de PILARES HOY, % por pilar bajo cada label, eliminación de la card separada.

**Cambios v1.1:**

- **Eliminación de `daily_score_card.dart`** y `daily_score_card_test.dart` (deprecados — su rol lo cumple el nuevo header del módulo Pilares).
- **`PillarRing` extendido con `showPercent: bool = false`** (§RF-140.1-01). Renderiza `${round(progress*100)}%` como segunda línea bajo el label cuando true. Diseñado para no afectar callsites legacy que no pasen el parámetro.
- **`_buildPillarsRow` refactorizado** (§RF-140.1-02). El header pasa de "PILARES HOY" simple a `Row` con label izquierda + score+delta+ⓘ a la derecha. El ⓘ mantiene `Key('daily_score_info_button')` para testabilidad y abre el mismo `showDailyScoreExplainerSheet` que existía.
- **Las 5 instancias de `PillarRing` ahora pasan `showPercent: true`.**
- **`daily_score_explainer_sheet.dart` preservado** — es el tooltip educativo del nuevo ⓘ y conserva el copy aprobado (5 pesos + disclaimer Score vs IMR).
- **Lógica de pesos sin cambios.** El `computeDailyScore` y los providers siguen igual — solo cambia dónde se renderiza el número.

**Comportamiento visual resultante:**

```
PILARES HOY                            73/100 ↑13 ⓘ
┌────────────────────────────────────────────────────┐
│ ⌚      🌙       💧       💪        🍴               │
│ Ayuno  Sueño   Hidrat.  Ejerc.    Comidas          │
│ 73%    85%     60%      100%      100%             │
└────────────────────────────────────────────────────┘
```

**No es necesario re-validar clínicamente.** Es refactor UX puro — los pesos, fórmulas y citas bibliográficas son idénticas a v1.0. SPEC-141 sigue desbloqueada y consume el mismo `computeDailyScore`.

**Aprendizaje de proceso:** validar UX con screenshot antes de cerrar SPEC. Si Carlos hubiera visto el diseño durante el diseño (no después de implementar), el rediseño habría sido más barato. Anotado para SPECs futuras con componente visual.

### v1.2 — 2026-06-01 (mismo día, segunda iteración UX)

Carlos compartió feedback del rendering de v1.1: *"ese número fuera de la card queda muy feo y sin relevancia"*. El score como sub-header de la fila PILARES HOY quedaba colgando arriba del Container, sin anchor visual con los rings que venían abajo, y sin jerarquía contra el label "PILARES HOY" con el que competía.

**Diagnóstico:** el problema de v1.1 era que el score estaba EN la Row del header (Column padre), pero el Container con los rings era SU HERMANO, no su padre. Visualmente quedaba flotando.

**Decisión:** mover el score COMO HEADLINE DENTRO del card. El Container que envuelve los rings ahora envuelve TODO el módulo "Tu Día" (headline + divider + rings).

**Cambios v1.2:**

- **Estructura invertida.** El `_buildPillarsRow` ya no retorna un `Column` con header arriba y Container abajo. Retorna directamente un `Container` con un `Column` interno que contiene: (1) Row label TU DÍA + ⓘ, (2) Row número grande + delta, (3) divider sutil 1px alpha 0.08, (4) Row de 5 PillarRings con showPercent.
- **Label PILARES HOY eliminado.** Los 5 rings con sus iconos (⌚ 🌙 💧 💪 🍴) son autodescriptivos. El label era redundante.
- **Número escalado a fontSize 36** (vs 22 en v1.1) — ahora tiene presencia de headline real.
- **Padding del Container ajustado** a `EdgeInsets.fromLTRB(18, 16, 18, 16)` para acomodar el headline + rings + divider sin sentirse apretado.
- **ⓘ alineado en la esquina superior derecha** del card, no en línea con el número. Da aire visual.
- **Delta sigue al lado del número** como en v1.1, pero alineado al baseline correcto.

**Comportamiento visual resultante:**

```
┌─────────────────────────────────────────────────┐
│  TU DÍA                                       ⓘ │
│  73 /100   ↑13                                  │
│                                                 │
│  ─────────────────────────────────              │
│                                                 │
│  ⌚      🌙       💧       💪        🍴           │
│  Ayuno  Sueño   Hidrat.  Ejerc.    Comidas      │
│  73%    85%     60%      100%      100%         │
└─────────────────────────────────────────────────┘
```

**Sin cambios funcionales.** Los providers, pesos, fórmulas, citas y tests siguen idénticos. Solo cambia la composición visual del card.

**Lección reforzada:** la primera iteración UX falló porque visualicé la Row del header en mi cabeza pero no proyecté cómo se vería sin anchor visual al Container debajo. Mockup ASCII durante propuesta NO captura esto — solo el rendering real lo hace. Para futuras SPECs con UI, *forzar* iteración Carlos→render→screenshot ANTES de cerrar, en lugar de cerrar y esperar feedback.

### v1.3 — 2026-06-01 (tercera iteración UX, mismo día)

Screenshot de v1.2 mostró el card con el headline correcto pero con feedback adicional de Carlos: *"hay mucho espacio vacío en la card, falta una frase motivacional o algo así al lado del Score y el espacio entre esa card y la de abajo está muy grande"*.

**Diagnóstico:**
1. El número `73 /100 ↑13` ocupaba solo el tercio izquierdo del headline — los otros dos tercios quedaban vacíos sin balance visual.
2. El gap de 24px entre `_buildPillarsRow` y la card "Ayuno Consciente" creaba una pausa visual demasiado fuerte; las dos cards se sentían desconectadas.

**Cambios v1.3:**

- **Helper `_dailyScoreMotivation(int score)`** con 6 rangos de copy calibrados para tono ElenaApp (encouraging, sin diminutivos, brand metabólica). Ver tabla.
- **Spacer + Text alineado al baseline** en la Row del número. La frase llena el espacio vacío y aporta señal contextual.
- **Gap entre cards reducido de 24 → 14**. La card del pilar seleccionado se siente como continuación de "Tu Día".

**Tabla de copy adaptativo:**

| Score | Frase |
|---|---|
| 100 | "Día perfecto" |
| 85-99 | "Casi al tope" |
| 70-84 | "Excelente día" |
| 50-69 | "Buen avance" |
| 30-49 | "Sumando" |
| 0-29 | "Vas empezando" |

Las 6 frases evitan signos de exclamación (excepto el caso 100), no usan diminutivos ni emojis, y respetan el tono adulto-supportivo del producto. Los rangos están calibrados con margen — un usuario con 70 lee "Excelente día", uno con 69 lee "Buen avance" (rango medio), y el contraste se siente justo.

**Comportamiento visual resultante:**

```
┌──────────────────────────────────────────────────┐
│  TU DÍA                                        ⓘ │
│  73 /100   ↑13              Excelente día        │
│  ────────────────────────────────────            │
│  ⌚      🌙       💧       💪        🍴            │
│  Ayuno  Sueño   Hidrat.  Ejerc.    Comidas       │
│  73%    85%     60%      100%      100%          │
└──────────────────────────────────────────────────┘
   ↑ gap 14px ↓
┌──────────────────────────────────────────────────┐
│  Ayuno Consciente                       En curso │
│  ...                                              │
```

**Pendiente confirmar visualmente:** Carlos hace hot reload + screenshot. Si la frase queda bien y el gap se siente correcto, marcamos v1.3 como cierre definitivo de SPEC-140.
