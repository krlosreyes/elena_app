# SPEC-282 — El motor respeta las cautelas del Atlas

**Estado:** IMPLEMENTED (dominio + tests). PENDIENTE analyze/test de Carlos.
**Fecha:** 2026-08-12
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-281 (metadatos `cautions` en el catálogo).

## 1. Objetivo

Que el motor de la Minuta **no introduzca** alimentos con cautela de medicina funcional (histamina / inflamación) cuando sugiere para completar un plato o cuando propone una "mejora suave" — pero **sin sacar** los que el usuario ya come (respeta su elección).

## 2. Cambio

En `meal_plan_generator.dart`:
- `_pickNew` (rellenar rol faltante): excluye `f.cautions.isNotEmpty`.
- `_bestUpgrade` (objetivo de la mejora suave): excluye `f.cautions.isNotEmpty`.

La selección desde el repertorio del usuario NO se toca: si el usuario come cerdo (cautela histamina/inflamación), sigue en su plato como `fromUser`.

## 3. Archivos

- `lib/src/features/nutrition/domain/meal_plan_generator.dart`
- `test/features/nutrition/domain/meal_plan_generator_cautions_test.dart` — respeta el alimento del usuario, la sugerencia nueva nunca tiene cautela, invariante sobre newSuggestion/upgrade.

## 4. Verificación

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition/domain/meal_plan_generator.dart test/features/nutrition/domain/meal_plan_generator_cautions_test.dart
flutter test test/features/nutrition/domain
```
