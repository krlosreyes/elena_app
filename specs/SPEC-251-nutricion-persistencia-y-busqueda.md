# SPEC-251 — Sistema de registro de alimentación: pérdida silenciosa de datos y ranking de búsqueda

**Estado:** IMPLEMENTED
**Versión:** 1.0
**Fecha:** 2026-07-08
**Autor:** Claude (líder de proyecto) + Carlos (aprobación de alcance)
**Pilar:** Nutrición

## 1. Contexto

Carlos reportó: "Revisa a fondo todo el sistema de registro de alimentación, esta fallando. Analiza y propon la solución." Se hizo una auditoría completa del pilar Nutrición (notifier, repositorio, catálogo de alimentos, reglas de intervalo entre comidas, UI de plato) sin modificar código, y se presentaron 3 hallazgos con severidad y propuesta de fix. Carlos aprobó implementar los 3 (AskUserQuestion: "Sí, implementa todo ahora" + "Actualizar el test al número real (157)").

## 2. Hallazgos

### Fix 1 (crítico) — Pérdida silenciosa de comidas registradas/borradas

**Causa raíz:** en `NutritionNotifier.logMeal()` y `NutritionNotifier.deleteMealById()`, la lectura de `_ref.read(fastingProvider).isActive` — necesaria solo para decidir si agendar/cancelar la notificación de "próxima comida" — ocurría **antes** de despachar la llamada esencial `repo.saveMeal()` / `repo.deleteMealById()`.

`fastingProvider` es un `StateNotifierProvider<FastingNotifier, FastingState>` cuya inicialización (`_init()`) escucha `authStateProvider`, que a su vez construye `FirebaseAuth.instance` a través de `authRepositoryProvider`. Cualquier fallo en esa cadena (por ejemplo Firebase no inicializado, o un error de estado del propio `FastingNotifier`) lanzaba una excepción **antes** de que el código llegara a la línea de `repo.saveMeal`/`repo.deleteMealById`.

Como el estado local optimista (SPEC-206 offline-first) ya se había actualizado unas líneas antes, el resultado era una comida "fantasma": el usuario la veía en pantalla como guardada/borrada, pero la operación real contra Firestore **nunca se ejecutaba**. Al re-sincronizar el stream de Firestore, la comida desaparecía (si era un log nuevo) o reaparecía (si era un borrado) sin ningún error visible para el usuario.

Este mismo patrón es lo que hacía fallar 8 tests de `nutrition_notifier_test.dart` en el entorno de test (`[core/no-app] No Firebase App '[DEFAULT]'` al leer `fastingProvider` sin Firebase inicializado) — los tests estaban exponiendo el bug real, no solo un gap de configuración de test.

**Solución:** en `logMeal()` y `deleteMealById()` (`lib/src/features/nutrition/application/nutrition_notifier.dart`), la llamada esencial a `repo.saveMeal()` / `repo.deleteMealById()` ahora se despacha **primero** (no bloqueante, patrón offline-first ya existente). La lectura de `fastingProvider` y el agendado/cancelado de notificación quedaron en un bloque **después**, envuelto en `try/catch` — si falla, se loguea con `AppLogger.warning` y no afecta la persistencia ya disparada. Se aplicó el mismo `try/catch` defensivo a `removeLastMeal()` por consistencia, aunque su orden ya era seguro.

### Fix 2 (medio) — Ranking de búsqueda: coincidencia exacta pierde contra substring

**Causa raíz:** `FoodCatalog.search()` ordenaba primero por `qualityScore` (descendente) y, en empate, alfabéticamente por nombre. "Aguacate" y "Aceite de aguacate" comparten `qualityScore: 100`, y alfabéticamente "Ac..." precede a "Ag...", así que buscar "aguacate" devolvía primero el aceite — un resultado contraintuitivo para el usuario que busca el alimento, no un derivado.

**Solución:** se agregó `Food.matchSpecificity(String normalizedQuery)`, que clasifica la coincidencia en 5 niveles (0 = nombre exacto, 1 = nombre empieza-con, 2 = alias exacto, 3 = alias empieza-con, 4 = substring). `FoodCatalog.search()` ahora usa esta especificidad como criterio de desempate **entre** el score y el orden alfabético. No se tocó el criterio primario (score), por lo que el test existente que exige orden no-creciente de score para la query `'p'` sigue pasando sin cambios.

### Fix 3 (bajo, deuda de test) — Test de tamaño de catálogo desactualizado

**Causa raíz:** el catálogo (`FoodCatalog.all`) creció orgánicamente a 157 alimentos (proteínas 34, grasas 34, carbohidratos 89) a través de varias SPECs anteriores, pero el test `'catalogo entre 70 y 120 alimentos'` nunca se actualizó y quedaba en rojo.

**Solución (decisión de Carlos):** actualizar el rango del test al número real, con margen para crecimiento futuro: `'catalogo entre 130 y 180 alimentos'`, aserciones `greaterThanOrEqualTo(130)` / `lessThanOrEqualTo(180)`.

## 3. Archivos modificados

- `lib/src/features/nutrition/application/nutrition_notifier.dart` — reorden + try/catch en `logMeal()`, `deleteMealById()`, `removeLastMeal()`.
- `lib/src/features/nutrition/domain/food_catalog.dart` — nuevo método `Food.matchSpecificity()`; `FoodCatalog.search()` usa especificidad como desempate secundario.
- `test/features/nutrition/domain/food_catalog_test.dart` — rango de tamaño de catálogo actualizado a 130-180; nuevo test de regresión para el ranking de búsqueda (`'aguacate'` debe devolver el alimento antes que `'aceite_aguacate'`).
- `test/features/nutrition/application/nutrition_notifier_test.dart` — nuevo grupo de tests `'NutritionNotifier resiliente a fallos en fastingProvider (SPEC-251)'`: override de `fastingProvider` que lanza una excepción al leerse, verificando que `logMeal`, `removeLastMeal` y `deleteMealById` igual invocan al repositorio.

## 4. Tests

Nuevos/modificados:
1. `SPEC-251: coincidencia exacta de nombre gana sobre substring aunque ambos tengan el mismo score` — `food_catalog_test.dart`.
2. `catalogo entre 130 y 180 alimentos` (actualizado) — `food_catalog_test.dart`.
3. `logMeal invoca repo.saveMeal aunque fastingProvider lance excepción` — `nutrition_notifier_test.dart`.
4. `removeLastMeal invoca repo.removeLastMeal aunque fastingProvider lance excepción` — `nutrition_notifier_test.dart`.
5. `deleteMealById invoca repo.deleteMealById aunque fastingProvider lance excepción` — `nutrition_notifier_test.dart`.

Los 8 tests preexistentes que fallaban por `[core/no-app] No Firebase App` en el grupo original (`'logMeal invoca repo.saveMeal...'`, `'removeLastMeal invoca...'`, `'SPEC-210-01/02/03'`, etc.) deberían pasar sin modificación adicional, dado que el fallo ahora ocurre dentro del `try/catch` nuevo y ya no aborta la ejecución antes del `repo.saveMeal`/`removeLastMeal`.

Verificación pendiente por Carlos (sin Flutter SDK en el sandbox):

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze
flutter test test/features/nutrition
```

## 5. Riesgos

- El `try/catch` alrededor de la notificación de próxima comida significa que, si `fastingProvider` falla de forma persistente, el usuario dejará de recibir esa notificación silenciosamente (se loguea con `AppLogger.warning`, no se muestra al usuario). Se considera aceptable: es una notificación de conveniencia, no un dato del pilar.
- `matchSpecificity` compara contra `searchAliases`, que es una lista mantenida a mano por alimento — un alimento sin aliases seguirá funcionando (cae a nivel 0/1/4 según nombre) pero no se beneficia de los niveles 2/3.

## 6. Criterios de aceptación

- [x] `logMeal()` invoca `repo.saveMeal` incluso si `fastingProvider` lanza excepción.
- [x] `deleteMealById()` invoca `repo.deleteMealById` incluso si `fastingProvider` lanza excepción.
- [x] Buscar "aguacate" devuelve el alimento "Aguacate" antes que "Aceite de aguacate".
- [x] Test de tamaño de catálogo refleja el número real (157) con margen de crecimiento.
- [ ] Validación en device/simulador por Carlos: registrar y borrar comidas sin ver "fantasmas" tras reconexión.
- [ ] `flutter analyze` y `flutter test` corridos por Carlos sin regresiones.

## 7. Resultado

Código completo, tests nuevos escritos, verificación de balance de paréntesis/llaves/corchetes en los 4 archivos modificados vía script Python (sin Flutter SDK disponible en el sandbox) — todos OK. Pendiente: `flutter analyze`/`flutter test` por Carlos y validación manual en device.
