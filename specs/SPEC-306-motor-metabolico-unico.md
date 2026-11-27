# SPEC-306 — Motor metabólico único app + sitio

Estado: IMPLEMENTED (27-nov-2026) · Versión: Elena 1.0.1

## Problema
La app y metamorfosisvital.com.co daban cifras distintas a la misma persona:
- % de grasa en mujeres: la app usaba cintura+15 o una tabla por ICE; el sitio la fórmula US Navy con cadera.
- Edad metabólica: la app usaba `edad + 20·(1 − bloque Estructura)`; el sitio `edad + (grasa − referencia ACSM) + 0,6·max(0, IMC − 22)`.
- Cortes del índice cintura-estatura: la app 0,43/0,50/0,56/0,63; el sitio NICE NG246 (0,40/0,50/0,60).
- Sin medidas, la app inventaba valores (15/25 % de grasa, cintura = peso × 0,48).

## Decisión
1. Una sola fórmula: `lib/src/core/engine/metabolic_formulas.dart` (motor `spec-118-v1`, igual a `src/lib/imr/engine.ts`).
2. Mujeres sin cadera: no se calcula el % de grasa (null). No se estima la cadera.
3. Casos compartidos `test/fixtures/metabolic_cases.json` (copia idéntica en el sitio), probados en los dos repos.
4. Sin medida real se muestra "—" / "Sin medir", nunca una cifra inventada.
5. Etiquetas de grasa del American Council on Exercise: Esencial, Atletas, Fitness, Promedio, Obesidad.

## Cambios
- `UserModel.hipCircumference` (+ `bio.hipCm` en el shape canónico, mapper y adapter).
- `BodyFatCalculator`, `SizeMapperService.calculateBodyFat`, `BiometryRecalc` delegan en `MetabolicFormulas`.
- `ScoreEngine`: edad metabólica con la fórmula del sitio cuando hay % de grasa.
- Composición corporal (tarjeta y pantalla), `BodyZone`, `GoalSuggestionEngine`: cortes NICE y etiquetas ACE.
- Check-in semanal: campo de cadera para mujeres; `BiometricDelta`/`BiometricCheckIn` llevan la cadera.
- Usuarios existentes: `functions/scripts/spec306_recalcular_grasa.js` (ensayo por defecto, respaldo JSON, `--aplicar` para escribir) + aviso único `CalcUpdateNoticeCard` en Hoy.

## Criterio de salida
- `test/core/engine/metabolic_formulas_test.dart` y `src/lib/imr/sharedFixtures.test.ts` verdes con los mismos 8 casos.
- `node scripts/spec306_recalcular_grasa.selftest.js` verde.
