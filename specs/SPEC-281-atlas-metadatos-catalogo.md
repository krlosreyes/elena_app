# SPEC-281 — Metadatos del Atlas Nutricional en el FoodCatalog

**Estado:** IMPLEMENTED (dominio + datos + tests). PENDIENTE analyze/test de Carlos.
**Fecha:** 2026-08-12
**Rama:** `feat/pilar-alimentacion-minuta`
**Fuente:** El Atlas Nutricional + Metabolic Architecture (guías de medicina funcional; se usan los DATOS nutricionales como hechos, no el texto/imágenes). Ver memoria [[reference-atlas-metabolic-architecture]].

## 1. Objetivo

Subir la resolución del `FoodCatalog` con metadatos del Atlas, base para el resto (regla del plato explícita, micro-educación, evitar alimentos con cautela). No cambia la arquitectura ni el score existente.

## 2. Qué se agregó

Al modelo `Food` (todos opcionales, con defaults → los alimentos previos siguen compilando):

- `proteinFraction` (double?): proteína efectiva por gramo (regla del Atlas: ~0.25 carnes blancas, ~0.30 rojas; valores por tabla donde se conocen).
- `micros` (List<String>): micronutrientes/beneficios destacados.
- `qualityNote` (String?): ej. "Prioriza grass-fed", "De campo / orgánico".
- `idealUse` (String?): ej. "Crudo (ensaladas)", "Ideal para cocinar".
- `cautions` (List<FoodCaution>): `histamine` / `inflammation` (para evitar según intake).
- `vegGroup` (VegGroup?): `cruciferous` / `leafyGreen` / `prebiotic` / `other`.

Enums nuevos: `FoodCaution` y `VegGroup` (con `label`).

## 3. Alimentos enriquecidos (27)

Proteínas: carne_res, cerdo (cautela histamina+inflamación), pollo, muslo_pollo, salmon, pescado, atun, trucha, tilapia, sardinas, huevo, clara_huevo. Grasas: aguacate, aceite_oliva, aceite_coco, coco, ghee, almendras, nueces. Vegetales (subgrupo): brocoli/coliflor (crucíferas), espinaca/acelga/kale/lechuga (hojas verdes), cebolla/ajo (prebióticos).

## 4. Archivos

- `lib/src/features/nutrition/domain/food_catalog.dart` — enums `FoodCaution`/`VegGroup`, 6 campos nuevos en `Food`, 27 entradas enriquecidas.
- `test/features/nutrition/domain/food_catalog_metadata_test.dart` — defaults, proteinFraction en (0,1), micros/calidad/uso, cautelas del cerdo, subgrupos, labels.

## 5. Siguiente (habilitado por esto)

- SPEC-282: motor aplica regla del plato (50% vegetal, 35–50% grasa), evita `cautions` si el usuario declara inflamación/alergia, rationale por `vegGroup`.
- SPEC-283: micro-educación en la Minuta desde `micros`/`qualityNote`/`idealUse`.
- SPEC-284: `ProteinTargetService` usa `proteinFraction` para porciones más precisas.

## 6. Verificación

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/nutrition/domain/food_catalog.dart test/features/nutrition/domain/food_catalog_metadata_test.dart
flutter test test/features/nutrition/domain
```
