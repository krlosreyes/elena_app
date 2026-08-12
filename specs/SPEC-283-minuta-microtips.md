# SPEC-283 — Micro-tips por alimento en la Minuta

**Estado:** IMPLEMENTED (UI). PENDIENTE analyze/simulador de Carlos.
**Fecha:** 2026-08-12
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-281 (metadatos del Atlas en el catálogo).

## 1. Objetivo

Micro-educar sin ruido: bajo cada alimento del plato, una línea corta con el dato más útil (calidad, uso ideal, subgrupo de vegetal o micros) tomado de los metadatos del `FoodCatalog`.

## 2. Cambio

`meal_plan_screen.dart` → `_PlanItemRow`: helper `_foodTip(Food)` con prioridad `qualityNote` > `idealUse` > `vegGroup.label` > primeros micros. Se renderiza en un renglón pequeño ámbar bajo el nombre. Solo aparece si el alimento tiene metadatos (los que no, se ven igual que antes).

Ejemplos: salmón → "Omega-3 · Vitamina D"; aceite de oliva → "Crudo (ensaladas, terminación)"; res → "Prioriza grass-fed"; brócoli → "Crucífera"; cebolla → "Prebiótico".

## 3. Archivos

- `lib/src/features/nutrition/presentation/meal_plan_screen.dart`

Solo display; los datos ya están testeados en SPEC-281.

## 4. Verificación

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition/presentation/meal_plan_screen.dart
```
