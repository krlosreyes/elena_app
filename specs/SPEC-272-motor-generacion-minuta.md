# SPEC-272 — Motor de generación de la Minuta (reemplazo suave, determinístico)

**Estado:** IMPLEMENTED — motor (dominio puro) + tests. PENDIENTE de `flutter analyze` + `flutter test` por Carlos.
**Versión:** 1.0
**Fecha:** 2026-08-07
**Autor:** Claude (líder de proyecto / full-stack) + Carlos (aprobación)
**Pilar:** Nutrición
**Rama:** `feat/pilar-alimentacion-minuta`
**Depende de:** SPEC-270 (intake), SPEC-271 (modelo mealPlan). **Habilita:** SPEC-273 (UI/ciclo diario), SPEC-274 (score).

## 1. Contexto

El corazón de la reestructuración: convertir el retrato dietético (`NutritionIntake`) en un `MealPlan` del día por **reemplazo suave** — partir de lo que el usuario ya come y corregir el eslabón más débil, sin imponer un menú ajeno. Decisión de Carlos (§9): **100% determinístico**, sin IA en la decisión; snacks **no** se proponen (se retiran gradualmente).

## 2. Diseño

`MealPlanGenerator` es **Dart puro** (sin Riverpod / Firestore / Flutter) → altamente testeable. Entrada: `intake` + `targetProteinG` (lo deriva el llamador del `UserModel` vía `ProteinTargetService`) + ventana + `phase` + `dateId`. Salida: `MealPlan` (SPEC-271).

Algoritmo por comida (§7.3 de la propuesta):

1. **Base** = items del intake que están en `FoodCatalog` (los de texto libre no se puntúan; el plan es prescriptivo con alimentos conocidos).
2. **Reemplazo suave**: se corrige UN item —el peor de la fase— por la mejor alternativa de su misma categoría (mayor `qualityScore`, desempate por id → determinismo), respetando exclusiones. Umbral de "debilidad" por fase: fase 1 solo NOVA 4 o `qualityScore < 15`; fases mayores endurecen (35/50/65).
3. **Reglas del plato** (Jaramillo cap. 10): garantiza ≥1 proteína, ≥1 vegetal (carbo de `qualityScore ≥ 70`) y ≥1 grasa buena, sin duplicar lo que ya hay.
4. **Salida**: `PlanItem`s con rol (protein/veg/fat/other) y porción de mano (palma/puño/pulgar), `swappedFrom`, y un `rationale` humano por plantilla determinística.

`targetProteinG` se reparte entre comidas con pesos por slot (desayuno 0.25 · almuerzo 0.40 · cena 0.35), normalizados.

## 3. Alcance / límites conocidos

- **Diet-aware (vegano/vegetariano):** en v1 solo se aplican las exclusiones EXPLÍCITAS (`excludes` + `allergies`). Filtrar por régimen requiere etiquetas planta/animal en el catálogo (no existen aún) → se refina cuando se agreguen. Se documenta como límite, no como bug.
- **Rotación/variedad** (no repetir el mismo reemplazo N días): es SPEC-275; aquí el motor es determinístico puro.
- **Orquestación generar+persistir** (leer intake+user, generar, guardar en `mealPlans`) vive en SPEC-273 (la UI la dispara). Este SPEC entrega el motor puro + tests.

## 4. Archivos

Nuevos:

- `lib/src/features/nutrition/domain/meal_plan_generator.dart`
- `test/features/nutrition/domain/meal_plan_generator_test.dart`
- `specs/SPEC-272-motor-generacion-minuta.md`

No se modificó ningún archivo existente.

## 5. Tests

`meal_plan_generator_test.dart` (descubre alimentos reales del catálogo por propiedad, no por id):

- **Determinismo**: misma entrada ⇒ misma minuta (`jsonEncode` idéntico).
- **Reemplazo suave**: el peor carbo se reemplaza (`swappedFrom` lo contiene; ya no aparece en el plato).
- **Reglas del plato**: la comida garantiza proteína + vegetal + grasa; la proteína lleva porción de palma.
- **Exclusiones**: al prohibir la mejor proteína, el motor elige otra y nunca propone la excluida.
- **Reparto de proteína**: la suma por comida ≈ objetivo del día; el almuerzo pesa más que el desayuno.

Verificación pendiente (Carlos):

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze
flutter test test/features/nutrition
```

## 6. Siguiente paso

SPEC-273: UI de la Minuta + ciclo diario (tarjetas, "Comí esto/Cambié/Me salté"), que dispara la generación (este motor) y persiste/lee el `MealPlan` (SPEC-271).
