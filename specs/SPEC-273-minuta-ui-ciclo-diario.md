# SPEC-273 — UI de la Minuta Diaria + ciclo diario (adherencia)

**Estado:** IMPLEMENTED — fábrica + notifier + pantalla + ruta + test. PENDIENTE de `flutter analyze` + `flutter test` + validación en simulador por Carlos.
**Versión:** 1.0
**Fecha:** 2026-08-07
**Autor:** Claude (líder de proyecto / full-stack) + Carlos (aprobación)
**Pilar:** Nutrición
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-270 (intake), SPEC-271 (modelo), SPEC-272 (motor). **Habilita:** SPEC-274 (score), SPEC-275 (variedad).

## 1. Contexto

El increment donde TODO se vuelve visible y usable: la pantalla de la minuta del día y el ciclo diario (§5 de la propuesta). Ata el motor (SPEC-272) con el intake (SPEC-270) y el `UserModel`, genera y persiste el plan (SPEC-271), lo muestra en tarjetas y captura la adherencia con un tap.

## 2. Diseño

- **`MealPlanFactory`** (application, PURA): a partir de biometría (height/gender/pal) + intake, deriva la proteína (ProteinTargetService) y llama al motor (MealPlanGenerator). Testeable sin montar la app. Toma primitivas, no el UserModel.
- **`MealPlanNotifier`** (application, offline-first): escucha usuario + intake; se suscribe al plan de HOY (`mealPlans/{yyyy-MM-dd}`). Si no existe y el intake está completo, lo **genera y persiste una vez** (guard anti-loop). Expone `markAdherence(slot, mark)` (Comí/Cambié/Me salté) y `regenerate()`.
- **`MealPlanScreen`** (presentation): tarjetas por comida con items (nombre + porción de mano + color por rol), el `rationale` del cambio, y los tres botones de adherencia; header con ventana + proteína objetivo + "N/M cumplidas"; acción "Regenerar". Estado vacío (sin intake) → botón "Configurar mi minuta".

## 3. Wiring

- Ruta nueva `/nutrition/minuta` (name `nutrition-minuta`).
- La entry card del Perfil ("Mi minuta diaria") ahora abre `/nutrition/minuta` (antes iba directo al onboarding). La pantalla enruta al onboarding si falta el intake.
- "Día" = fecha calendario (`MealPlan.dateId(DateTime.now())`). Alinear al Día Metabólico se evaluará más adelante.

## 4. Archivos

Nuevos:

- `lib/src/features/nutrition/application/meal_plan_factory.dart`
- `lib/src/features/nutrition/application/meal_plan_notifier.dart`
- `lib/src/features/nutrition/presentation/meal_plan_screen.dart`
- `test/features/nutrition/application/meal_plan_factory_test.dart`
- `specs/SPEC-273-minuta-ui-ciclo-diario.md`

Modificados (wiring mínimo):

- `lib/src/router/app_router.dart` — ruta `/nutrition/minuta`.
- `lib/src/features/nutrition/presentation/widgets/alimentacion_minuta_entry_card.dart` — abre la minuta.

## 5. Tests

`meal_plan_factory_test.dart`: la fábrica reparte la proteína cerca del objetivo derivado de la biometría (hombre 1.85 moderado → ~80 g) y cada comida garantiza proteína + vegetal + grasa. La lógica de adherencia (`markAdherence`, `adherentCount`) ya está cubierta en `meal_plan_test.dart` (SPEC-271); el motor en `meal_plan_generator_test.dart` (SPEC-272). El notifier (orquestación con Firestore) se valida en el simulador.

Verificación (Carlos):

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze
flutter test test/features/nutrition
flutter run
```

Ruta en simulador: **Perfil → "Mi minuta diaria"**. Con el intake completo, la app genera el plan del día; probar Comí/Cambié/Me salté (el borde de la tarjeta se marca) y "Regenerar".

## 6. Siguiente paso

SPEC-274: reconectar el `nutritionScore` a la **adherencia** de la minuta (platos cumplidos / propuestos), conservando el peso 0.18 en el Score del Día y el gate binario de racha.
