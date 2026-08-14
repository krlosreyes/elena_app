# SPEC-291 — La materia prima principal del plato es lo que el usuario eligió

**Estado:** IMPLEMENTED (dominio + tests). PENDIENTE analyze/test de Carlos.
**Fecha:** 2026-08-13
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-284/289.

## 1. Problema (feedback de Carlos)

Con receta-primero (SPEC-284) el motor podía sugerir un plato cuya proteína/ingrediente principal el usuario NO seleccionó (p. ej. salmón cuando solo marcó pollo). Los platos deben construirse alrededor de lo que él escogió.

## 2. Regla

Una receta es **elegible** solo si su **materia prima principal** está en el repertorio del usuario:
- Todas las **proteínas** de la receta deben estar seleccionadas; o
- si la receta no tiene proteína, su **ingrediente central** (primero de catálogo) debe estarlo.

Los acompañamientos (vegetales, grasas, condimentos) pueden variar (así seguimos empujando verduras y variedad, y el usuario puede cambiarlos con SPEC-280).

Si **ninguna receta** califica para una comida, se cae al **plato armado** (`_buildEntry`), que se construye con el repertorio del usuario.

## 3. Cambios

- `recipe_match_service.dart`: `match(..., requirePrincipal)` + helper `_principalInRepertoire` (import `food_catalog`).
- `meal_plan_generator.dart`: la generación usa `requirePrincipal: true`.
- `meal_plan_screen.dart`: el sheet "Cambiar plato" también exige el principal.
- Tests: nuevo `meal_plan_generator_principal_test.dart` (nunca sirve una proteína no elegida). Ajustados `meal_plan_generator_test`, `meal_plan_factory_test` y `meal_plan_generator_cautions_test` (con repertorios que sí traen la proteína; si el usuario elige un alimento con cautela, ahora se respeta su elección).

## 4. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition
flutter test test/features/nutrition
```

## 5. Nota / posible ajuste

Hoy la regla exige el **principal** (proteína) del usuario, pero permite acompañamientos (vegetal/grasa) que no marcó. Si quieres que sea aún más estricto (que TODO ingrediente del plato esté seleccionado), lo endurecemos — pero eso hará que más comidas caigan al "plato armado" en vez de recetas.
