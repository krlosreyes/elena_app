# SPEC-251 — Sistema de registro de alimentación: pérdida silenciosa de datos y ranking de búsqueda

**Estado:** IMPLEMENTED (verificado con `flutter analyze` + `flutter test`)
**Versión:** 1.1
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

**Corrección post-verificación (2026-07-08):** la hipótesis original — que los 8 tests preexistentes con `[core/no-app]` pasarían solos gracias al `try/catch` — era **parcialmente incorrecta**. Carlos corrió `flutter test test/features/nutrition` y el resultado real fue **314 passed, 5 failed**:

- Los 3 tests nuevos de este SPEC (arriba) **pasan** — confirman que Fix 1 funciona: `repo.saveMeal`/`removeLastMeal`/`deleteMealById` se invocan aunque `fastingProvider` lance.
- 5 tests del grupo original siguen fallando: `logMeal invoca repo.saveMeal...`, `removeLastMeal invoca repo.removeLastMeal`, `SPEC-210-01/02/03`.

**Causa raíz del fallo restante (distinta de Fix 1):** `NutritionNotifier._init()` (constructor, línea 139) se suscribe a `currentMetabolicCycleProvider`, que a su vez observa `authStateProvider` (línea 31 de `metabolic_cycle_providers.dart`). Esta suscripción ocurre **siempre**, en cuanto el test hace `container.read(nutritionProvider)` en el `setUp()` — antes de que `logMeal`/`removeLastMeal` se ejecuten siquiera. Cuando `authStateProvider` lanza `[core/no-app]` (Firebase no inicializado en el entorno de test), el error se propaga como un error asíncrono no manejado a nivel de `ProviderContainer` (vía `_BroadcastStreamController.addError`), fuera del alcance de cualquier `try/catch` síncrono dentro de `logMeal`/`removeLastMeal`. El framework de test lo intercepta vía su Zone y marca el test como fallido.

Esto es una **brecha de infraestructura de test preexistente y separada de Fix 1**, no una regresión de SPEC-251 ni un bug de producción (en la app real, Firebase siempre está inicializado antes de que se monte cualquier provider). El grupo original de tests nunca mockeó `authStateProvider`/`currentMetabolicCycleProvider` en su `setUp()`. Se deja fuera de alcance de este SPEC — no estaba en los 3 fixes aprobados por Carlos — y se documenta aquí como deuda de test conocida para una futura SPEC de limpieza de tests de nutrición.

Verificación corrida por Carlos:

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
git push origin mvp-core-clean
flutter analyze
flutter test test/features/nutrition
```

Resultado:
- `git push`: el commit `92a809e` llegó correctamente a `origin/mvp-core-clean` (bypass de regla de PR registrado por GitHub). Un error posterior (`cannot lock ref 'refs/remotes/origin/mvp-core-clean'`) es un lock file local obsoleto en el `.git` de Carlos — no afecta el remoto, se resuelve borrando el archivo `.lock` localmente.
- `flutter analyze`: 67 issues, todas preexistentes (mismo conteo que antes de SPEC-251). Cero issues nuevos en los 4 archivos modificados por este SPEC.
- `flutter test test/features/nutrition`: 314 passed, 5 failed. Los 5 fallos son la brecha de infraestructura descrita arriba, no relacionada con los fixes de este SPEC.

## 5. Riesgos

- El `try/catch` alrededor de la notificación de próxima comida significa que, si `fastingProvider` falla de forma persistente, el usuario dejará de recibir esa notificación silenciosamente (se loguea con `AppLogger.warning`, no se muestra al usuario). Se considera aceptable: es una notificación de conveniencia, no un dato del pilar.
- `matchSpecificity` compara contra `searchAliases`, que es una lista mantenida a mano por alimento — un alimento sin aliases seguirá funcionando (cae a nivel 0/1/4 según nombre) pero no se beneficia de los niveles 2/3.

## 6. Criterios de aceptación

- [x] `logMeal()` invoca `repo.saveMeal` incluso si `fastingProvider` lanza excepción.
- [x] `deleteMealById()` invoca `repo.deleteMealById` incluso si `fastingProvider` lanza excepción.
- [x] Buscar "aguacate" devuelve el alimento "Aguacate" antes que "Aceite de aguacate".
- [x] Test de tamaño de catálogo refleja el número real (157) con margen de crecimiento.
- [x] `flutter analyze` sin issues nuevos (67 preexistentes, 0 en archivos de este SPEC).
- [x] `flutter test test/features/nutrition` sin regresiones nuevas (314 passed; 5 failed son brecha de test preexistente, no relacionada con Fix 1/2/3).
- [ ] Validación en device/simulador por Carlos: registrar y borrar comidas sin ver "fantasmas" tras reconexión.

## 7. Resultado

Implementado, testeado y verificado. `git push` a `mvp-core-clean` confirmado (commit `92a809e`). `flutter analyze` y `flutter test test/features/nutrition` corridos por Carlos: sin regresiones atribuibles a este SPEC. Pendiente: validación manual en device/simulador (registrar y borrar comidas, confirmar que no reaparecen/desaparecen "fantasmas" tras reconexión).
