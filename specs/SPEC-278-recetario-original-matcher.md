# SPEC-278 — Recetario original + motor de cruce

**Estado:** IMPLEMENTED (dominio + matcher + tests). UI (mostrar recetas en la Minuta) = follow-up. PENDIENTE analyze/test de Carlos.
**Fecha:** 2026-08-08
**Rama:** `feat/pilar-alimentacion-minuta`
**Pilar:** Nutrición

## 1. Objetivo

Dar a la Minuta un **recetario propio** y un motor que **cruce las preferencias del usuario** (lo que ya come, según su intake) con recetas que cumplen los parámetros de una buena alimentación, para sugerir platos fáciles y armar la lista de mercado.

## 2. Recetas ORIGINALES (no copia)

Las 24 recetas son escritas para Elena, alineadas al **método metabólico** (proteína magra + muchos vegetales + grasa buena; sin azúcar, sin harinas refinadas, sin ultraprocesados) e ingredientes de uso común en LatAm. Las obras de Jaramillo (*El Milagro Metabólico*) y Suárez (*El Poder del Metabolismo*) se usaron **solo como referencia de principios**, nunca de texto — decisión de Carlos por el tema de derechos de autor.

Cobertura: 6 desayunos, 7 almuerzos, 7 cenas, 4 snacks. Cada receta referencia **ids reales de `FoodCatalog`** en sus ingredientes centrales, para poder cruzarla con el repertorio del usuario y respetar restricciones.

## 3. Archivos

- `lib/src/features/nutrition/domain/recipe_catalog.dart` — `Recipe`, `RecipeIngredient`, `RecipeCatalog.all` (24 recetas), compatibilidad de dieta por receta.
- `lib/src/features/nutrition/domain/recipe_match_service.dart` — `RecipeMatchService.match(...)` (cruza intake + restricciones/dieta/slot → recetas ordenadas por afinidad) y `shoppingList(...)` (lista de mercado sin duplicar).
- `test/.../recipe_catalog_test.dart` — integridad: ids únicos, bien formadas, y **todos los foodId existen en el catálogo**.
- `test/.../recipe_match_service_test.dart` — recomienda por overlap, respeta dieta (vegano sin animal), excluye vetados, filtra por slot, dedup de lista de mercado.

## 4. Cómo cruza

`match` toma los foodIds que el usuario registró en su intake (comidas + snacks), y para cada receta compatible (slot + dieta + sin alimentos vetados) cuenta cuántos de sus ingredientes centrales ya come (`overlap`). Ordena por afinidad, penalizando ingredientes desconocidos y tiempos largos. Así, quien come pollo/aguacate/lechuga ve primero "Pollo a la plancha con ensalada de aguacate".

## 5. Follow-up (no incluido)

- **UI:** en cada comida de la Minuta, un "Recetas para este plato" que llama a `RecipeMatchService.match(intake, slot)` y una pantalla de lista de mercado.
- Persistir favoritos / marcar receta cocinada.
- Ampliar el recetario (más opciones vegetarianas/veganas y por presupuesto/tiempo).

## 6. Verificación

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition/domain/recipe_catalog.dart lib/src/features/nutrition/domain/recipe_match_service.dart test/features/nutrition/domain/recipe_catalog_test.dart test/features/nutrition/domain/recipe_match_service_test.dart
flutter test test/features/nutrition/domain/recipe_catalog_test.dart test/features/nutrition/domain/recipe_match_service_test.dart
```
