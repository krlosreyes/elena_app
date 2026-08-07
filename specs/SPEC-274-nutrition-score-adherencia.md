# SPEC-274 — nutritionScore desde la adherencia a la Minuta

**Estado:** IMPLEMENTED (parcial, seguro) — calculador puro + tests + anillo "Tu avance de hoy" cableado. La racha (nutritionMagnitude) y las otras cards del Dashboard quedan como paso siguiente **test-gated** (§6). PENDIENTE de `flutter analyze` + `flutter test` + simulador por Carlos.
**Versión:** 1.0
**Fecha:** 2026-08-07
**Autor:** Claude (líder de proyecto / full-stack) + Carlos (aprobación)
**Pilar:** Nutrición
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-271 (adherencia en el modelo), SPEC-273 (captura de adherencia).

## 1. Contexto

Decisión de Carlos (§9): la Minuta reemplaza al MealRatio como métrica visible. SPEC-274 traduce la adherencia diaria (Comí/Cambié/Me salté) a un score 0..1 y lo enchufa en el pilar, conservando invariantes (peso 0.18 en el Score del Día, gate binario de racha, IMR intacto).

## 2. Definición del score (puro)

`MinutaAdherenceScore` (dominio, PURO):

- `adherence(plan)` = comidas cumplidas / propuestas. "Comí" y "Cambié" cuentan (`AdherenceMark.isAdherent`, SPEC-271); "Me salté" no. Ponderación por ventana implícita (todas las comidas de la minuta están dentro de la ventana por construcción, SPEC-272).
- `effective({fallbackScore, plan})` — **guardarraíl de no-regresión**: usa la adherencia SOLO si hay minuta con ≥1 comida marcada; si no, devuelve el `fallbackScore` (score actual por calidad de plato) sin cambios.

## 3. Integración de esta entrega (segura)

Se cableó el anillo **"Tu avance de hoy" → Nutrición** (`todays_progress_section.dart`): la barra ahora refleja `effective(fallbackScore: nutrition.nutritionScore, plan: minuta de hoy)`. Es la métrica visible que la decisión prioriza. Esta pantalla NO tiene tests de widget (verificado), así que el cambio es seguro y se valida en el simulador.

## 4. Mapa de NO-REGRESIÓN (qué cuido)

- **No adoptantes (sin minuta):** `effective` → fallback → valor byte-idéntico. Cero cambio en el anillo, la racha o el IMR.
- **Minuta generada pero sin marcar:** también fallback (no penaliza a quien aún no interactúa).
- **`nutritionScoreRaw` / metabolic_state / score_engine / orchestrator (IMR y Análisis):** NO se tocan.
- **`streak_notifier` (nutritionMagnitude) y gate binario de racha:** NO se tocan en esta entrega (ver §6).
- **`NutritionScoreCalculator` (0.60/0.20/0.20):** sigue siendo el fallback; no se modificó.

## 5. Archivos

Nuevos:

- `lib/src/features/nutrition/domain/minuta_adherence_score.dart`
- `test/features/nutrition/domain/minuta_adherence_score_test.dart`
- `specs/SPEC-274-nutrition-score-adherencia.md`

Modificados:

- `lib/src/features/auth/presentation/widgets/todays_progress_section.dart` — la barra de Nutrición usa `effective()`.

## 6. Paso siguiente (SPEC-274.2, test-gated)

Cablear la **racha** (`streak_notifier.dart` línea ~497: `nutritionMagnitude = effective(...)`) y las otras superficies del Dashboard (`comidas_pillar_card`, `dashboard_pillars_row`). **Por qué no ahora:** ambos leerían `mealPlanNotifierProvider`, que instancia la cadena de la minuta (auth incluido); los tests de racha existentes construyen `StreakNotifier` sin override de ese provider, así que el cambio exige tocar el setup de esos tests. Es un cambio de alto riesgo sobre el pipeline del Score del Día que NO conviene hacer a ciegas — se hace con el suite de racha corriendo. El guardarraíl `effective()` garantiza que el resultado sea idéntico cuando no hay minuta, así que la lógica no cambia para los tests; solo hay que darles el override del provider.

Verificación (Carlos):

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze
flutter test test/features/nutrition
flutter run
```

En simulador: marca comidas en la minuta (Perfil → Mi minuta diaria) y verifica que la barra "Tu avance de hoy → Nutrición" (pantalla Objetivos) sube con la adherencia.
