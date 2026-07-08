# SPEC-255 — Tests de ayuno seteaban datos en un path de Firestore stale (pre-SPEC-217)

**Estado:** IMPLEMENTED — pendiente verificación de Carlos (`flutter test`)
**Fecha:** 2026-07-08
**Relacionado:** SPEC-217 (migración de colección plana a subcolección por uid), SPEC-254

## 1. Resumen

Al correr `flutter test test/features/dashboard`, 12 tests fallaban con
errores del tipo `Bad state: No hay intervalo abierto que corregir` o
`Expected: not null, Actual: <null>`, todos en:

- `test/features/dashboard/data/firestore_fasting_interval_v1_source_test.dart`
  (grupos SPEC-97, SPEC-99, SPEC-100, SPEC-101)
- `test/features/dashboard/e2e/fasting_e2e_edge_test.dart` (C1, C2, C3)

Ninguno de estos archivos fue tocado en las sesiones de SPEC-251 a SPEC-254
(que trabajaron sobre nutrición y el diálogo de aviso de ayuno), así que no
eran una regresión de ese trabajo. Se investigó por separado a pedido de
Carlos ("corrigelos, no mas rodeos").

## 2. Causa raíz

`SPEC-217` (2026-06-14) migró `FirestoreFastingIntervalV1Source` de la
colección plana `fasting_history/{docId}` a la subcolección
`users/{uid}/fasting_history/{docId}` (ver comentario de cabecera en
`firestore_fasting_interval_v1_source.dart`, líneas 3-11). El código de
producción se actualizó correctamente en su momento.

Pero **tres archivos de test nunca se migraron** y seguían sembrando datos
en `firestore.collection('fasting_history')` (el path plano viejo):

- `test/features/dashboard/_fixtures/fasting_fixtures.dart` — helper
  `seedFastingInterval()`, usado por `fasting_e2e_edge_test.dart` (caso C3).
- `test/features/dashboard/data/firestore_fasting_interval_v1_source_test.dart`
  — 8 `.add()` directos en distintos grupos de tests.
- `test/features/dashboard/e2e/fasting_e2e_edge_test.dart` — 2 `.add()`
  directos (casos C2 y verificación de C1).

Como el source real ya lee de `users/{uid}/fasting_history`, cualquier test
que sembrara en el path plano quedaba con el `FakeFirebaseFirestore` "vacío"
desde el punto de vista del código bajo prueba — de ahí los `StateError` de
"no hay intervalo abierto" y los `null` inesperados. La lógica de negocio
(`updateOpenIntervalStartTime`, `streamLatest`, `streamLastCompletedFasting`)
nunca estuvo rota; era puramente un desfase de fixtures de test respecto a
una migración de hace ~3 semanas que no arrastró sus tests.

Un dato que lo confirma: el test `'sin intervalo abierto → lanza StateError'`
(SPEC-97) SÍ pasaba antes del fix — porque esperaba exactamente el error que
la fuga de path producía igual, aunque por la razón equivocada (sembraba en
el path viejo y esperaba fallo real; el resultado coincidía con el bug).

## 3. Fix

Cambiar los 3 archivos para sembrar en
`firestore.collection('users').doc(userId).collection('fasting_history')`,
igual que ya hacía `firestore_sleep_v1_source_test.dart` (que sí se había
migrado correctamente en su momento y sirvió de referencia).

Caso especial: en el test `'NO toca intervalos abiertos de OTRO usuario'`
(SPEC-97), el documento del otro usuario debe sembrarse en
`.doc('OTHER')` — no en `.doc(userId)` — para preservar el aislamiento por
path que el test intenta verificar.

Sin cambios en código de producción: el bug era 100% de fixtures de test.

## 4. Verificación

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
rm -f .git/index.lock .git/refs/remotes/origin/mvp-core-clean.lock
git push origin mvp-core-clean
flutter test test/features/dashboard
```

Se espera que los 12 tests que fallaban ahora pasen. Los 5 fallos restantes
de `nutrition_notifier_test.dart` (logMeal/removeLastMeal/SPEC-210-*) son un
gap de infraestructura distinto y ya documentado (tests que no mockean
`fastingProvider` y pegan contra Firebase real en el entorno de test) — no
se tocan en este SPEC.
