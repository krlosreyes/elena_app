# SPEC-166 — Nutrición en Análisis: indicador dual calidad + adherencia

**Estado:** PROPOSED (pendiente implementación)
**Versión:** 1.0
**Fecha:** 2026-06-03
**Tipo:** Refinamiento del card de Nutrición en pantalla Análisis (no toca Hoy)
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~1.5 horas
**Bibliografía:** Frank Suárez §A/E + Biological Dial §RF-137 (calidad), Habit Tracking Lit (adherencia)

---

## 1. Contexto y diagnóstico

Carlos reportó el 2026-06-02: "Nutrición sigue sin mostrar registros en la gráfica" del Análisis, pese a haber registrado platos en el día.

Diagnóstico técnico (líder de proyecto, 2026-06-03):

- El pipeline de datos funciona. `nutritionHabitSeriesProvider` ya llama `watchSinceLogs(uid, since, until: hoy+1d)` y `NutritionRepositoryImpl` respeta el `until` (SPEC-149.2 bugfix aplicado). La query Firestore filtra `timestamp ∈ [since, end)` con índice presente (SPEC-145 §3 verificado).
- La gráfica no es un bug — es un **falso negativo perceptual**. El indicador actual es `% A-dominante`: solo cuenta como "1.0" los platos `Todo A`, `3 a 1`, `2 a 1`. Los platos `1 a 1` y `Todo E` cuentan como `0.0`. Si Carlos registró 2 platos `1 a 1` un día, el promedio es 0 % y la barra se ve plana — visualmente indistinguible de "no registré".

Conclusión: el código mide lo que prometió medir (calidad nutricional según Frank Suárez), pero el usuario espera ver **evidencia de adherencia** (registré → debe aparecer algo). Son dos cosas distintas mezcladas en una sola métrica.

## 2. Decisión

Separamos calidad de adherencia en un card dual que coexiste en el mismo bloque visual:

1. **Indicador primario — Calidad A-dominante (%)**
   Métrica existente. Barra Apple Fitness al estilo SPEC-163. Headline: "Promediaste X % de comidas A-dominantes." Liga directa al IMR (mantiene fundamento científico).

2. **Sub-indicador — Adherencia al registro (# platos/día)**
   Línea pequeña debajo del header del card, antes de la gráfica: "Registraste un promedio de X platos/día." Si X = 0, el copy cambia a "No registraste platos en este rango." Esto da feedback inmediato de adherencia sin ensuciar la lectura científica.

3. **Estado vacío real**
   Si no hay ningún `NutritionLog` en el rango: card muestra el copy de "No registraste platos…" y omite la barra (en vez de barra plana en 0 %). Evita la ambigüedad actual.

## 3. Razón (Why)

- **Frank Suárez y Biological Dial**: el pilar Nutrición pondera al IMR por **calidad A-dominante**, no por conteo. Romper esto invalidaría la trazabilidad del IMR longitudinal (SPEC-141). Por eso la métrica primaria no se mueve.
- **Habit science (Fogg, Clear)**: la **visibilidad inmediata del registro** es lo que sostiene el hábito. Si el usuario registra y "no ve nada", abandona. Por eso agregamos la línea de adherencia.
- **Coherencia con Hoy**: la línea de "platos/día" es review-mode (promedio del rango), no compite con el contador en vivo de Hoy.

## 4. Cambios concretos

### 4.1 — Provider nuevo (application)

`lib/src/features/analysis/application/analysis_series_providers.dart`:

Agregar `nutritionAdherenceSeriesProvider` paralelo al existente `nutritionHabitSeriesProvider`. Mismo stream subyacente (`watchSinceLogs`), pero:

```dart
valueOf: (l) => 1.0,          // cada log cuenta 1
aggregation: TemporalAggregation.sum,  // suma por bucket temporal
```

En modo daily → "platos hoy". En weekly → "platos/semana" (luego dividir entre 7 para promedio diario). En monthly → idem /30.

### 4.2 — Widget (presentation)

`lib/src/features/analysis/presentation/widgets/nutrition_card.dart` (nuevo o extensión del existente):

- Header `Nutrición` 22pt como otros cards
- Línea 1 — `headline calidad` (lo actual): "Promediaste 62 % de comidas A-dominantes."
- Línea 2 — **sub-headline adherencia** (nuevo): "Registraste 2.4 platos/día." Color `Colors.white.withOpacity(0.55)`, 13pt.
- BarChart de calidad % (SPEC-163, sin cambios)

### 4.3 — Estado vacío

Si `nutritionAdherenceSeriesProvider` total = 0:
- Headline: "Aún no registras platos en este rango."
- Sub-headline: "Toca Nutrición en Hoy para empezar."
- Sin barra (placeholder con icono ilustrativo opcional, sin números).

### 4.4 — IMR no se toca

Esta SPEC es solo presentational. El IMR longitudinal (SPEC-141) sigue leyendo `cocienteA` semanal del `daily_summary`. **No hay cambio de fundamento científico.**

## 5. Cómo aplica

- **Cuándo:** próximo sprint de Ola 2 (active coaching), después de cerrar el bugfix de Ayuno (ya en código).
- **Dónde:** solo Análisis. Hoy no se toca (regla preservada de Carlos).
- **A quién afecta:** todos los usuarios que vean Análisis con < 3 platos A-dominantes/día. Hoy, ese es el caso de Carlos en testing.

## 6. Validación

### 6.1 — Test de unidad
`test/features/analysis/application/nutrition_adherence_series_provider_test.dart`:
- 3 logs en 1 día (modo daily) → 1 punto con valor 3.0
- 0 logs en rango → series vacía
- 7 logs en 7 días distintos (modo weekly) → 1 punto con valor 7.0

### 6.2 — Test visual (manual en device)
- Registrar 2 platos `1 a 1` hoy. Verificar:
  - Sub-headline dice "Registraste 2 platos/día."
  - Barra de calidad muestra 0 % (no vacío).
- No registrar nada en los últimos 7 días. Verificar:
  - Card muestra estado vacío con copy correcto, sin barra plana confusa.

### 6.3 — Verificación de no-regresión
- IMR longitudinal del mismo período no cambia (es el mismo `cocienteA` subyacente).
- Pantalla Hoy del pilar Nutrición sin cambios.

## 7. Riesgos

- **Ruido visual:** si la sub-headline pesa demasiado, compite con el headline principal. Mitigación: 13pt + opacidad 0.55, separación 4pt.
- **Confusión "registré 5 platos pero 0 %":** justamente lo que queremos que el usuario sienta. Es coaching pasivo (ves la brecha entre "registré" y "calidad"). Si genera frustración, evaluar copy: "Estás registrando — el siguiente paso es elegir más A."

## 8. Decisión pendiente del líder

Carlos: confirmar antes de implementar:

- [ ] Aprobar SPEC-166 v1.0 → pasar a IN_PROGRESS
- [ ] Confirmar copy de la sub-headline ("Registraste X platos/día." vs otras opciones)
- [ ] Confirmar prioridad vs SPEC-132.next (HealthKit observers, sigue BLOCKED)

---

**Próximo paso si se aprueba:** Implementación en 1 commit, con tests, sin tocar Hoy ni el cálculo de IMR.
