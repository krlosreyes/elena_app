# SPEC-289 — Onboarding de alimentación por checklists (no por comida)

**Estado:** EN CURSO por partes. 289.1 IMPLEMENTED (catálogo). 289.2/.3 pendientes.
**Fecha:** 2026-08-12
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Problema (feedback de Carlos + pantallas)

Capturar "qué comes en cada comida" (buscar alimento por comida + poco/normal/bastante) es tedioso y feo. El usuario no debería asignar alimentos a comidas: solo marcar lo que consume; el motor decide cuándo.

## 2. Decisiones (Carlos)

- Alimentos agrupados por macro: **Proteínas / Carbohidratos / Grasas** + **Comidas y antojos** (4ª categoría para compuestos: perro caliente, sándwich, empanada, pizza, hamburguesa, tacos…).
- Selección por **check** (marcado = lo como; sin marcar = no lo como). Igual para **snacks**.
- **Alergias** como lista aparte (filtro duro de seguridad).
- Se mantienen **régimen** (omnívoro/vegano…) y **ventana de comidas**.
- Ampliar la base con comidas del día a día.

## 3. Partes

### 289.1 — Catálogo (IMPLEMENTED)
- `food_catalog.dart`: enum `UserFoodGroup {protein, carb, fat, combo}` + `label`; `FoodCatalog.groupOf(food)`, `byUserGroup(group)`, `comboIds`.
- Los everyday que ya existían (hamburguesa, sándwich, empanada, pizza, salchipapa, patacón, buñuelo, pandebono, arepa, salchicha, chorizo) se marcan `combo` vía `comboIds` — no se duplican en su macro.
- 11 everyday nuevos: perro caliente, tacos, tamal, wrap, nuggets, pollo frito, papas fritas, mortadela, salchichón, helado, chocolatina.
- Test: `test/features/nutrition/domain/food_catalog_groups_test.dart`.

### 289.2 — Intake = repertorio plano (IMPLEMENTED, dominio)
- `nutrition_intake.dart`: nuevo campo `repertoire: List<IntakeItem>` (+ JSON + copyWith + `repertoireFoodIds`). `isComplete` = ≥3 en repertorio **o** (legacy) alguna comida con item. `meals` se conserva para intakes viejos.
- `meal_plan_generator.dart`: `_sourceMeals(intake)` — si hay repertorio y no `meals`, genera desayuno/almuerzo/cena con el repertorio completo por slot.
- `recipe_match_service.dart`: `_userFoods` incluye el repertorio.
- `alimentacion_minuta_entry_card.dart`: subtítulo cuenta alimentos del repertorio.
- Test: `meal_plan_generator_repertoire_test.dart`.
- Pendiente 289.3: `IntakeDraft` que escribe `repertoire` (lo hace la UI nueva).

### 289.3 — UI de checklists (IMPLEMENTED)
- `intake_draft.dart`: reescrito a modelo de repertorio (`Set<String> repertoire`, `snackIds`, `diet`, `allergies`; `toggle`/`build`/`fromIntake`). `fromIntake` levanta foodIds de intakes viejos por comida.
- `intake_onboarding_screen.dart`: reescrito a **4 pasos** — Régimen → Marca lo que comes (4 secciones por grupo con chips seleccionables) → Snacks → Alergias. Se retiran los pasos viejos (estructura, captura por comida, bebidas, contexto) y el `_FoodPickerSheet`/poco-normal-bastante.
- Tests: `intake_draft_test.dart` reescrito.

## 5. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition test/features/nutrition
flutter test test/features/nutrition
```

Simulador: Perfil → Alimentación → nuevo onboarding de checklists (marcar por macro, snacks, alergias) → guardar → la Minuta se regenera desde el repertorio.

## 4. Verificación 289.1 (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition/domain/food_catalog.dart test/features/nutrition/domain/food_catalog_groups_test.dart
flutter test test/features/nutrition/domain/food_catalog_groups_test.dart
```
