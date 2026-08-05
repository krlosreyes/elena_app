# SPEC-264 — Perlas, Anillos, Zumbidos y Retención (implementado)

**Estado:** implementado (v1). SIN compilar/testear en este entorno (sandbox sin
toolchain) → pendiente de `validar` en verde por Carlos.
**Fecha:** 2026-08-05. Extiende SPEC-263 (Retos) y SPEC-262 (gamificación).
**Diseño y decisiones:** ver `PROPUESTA_perlas_y_zumbidos.md` (todo LOCKED).

## Qué se construyó

**Perlas (F1).** "Estrellas" → "perlas" solo de cara al usuario (label + ícono
`blur_circular` + copy). Las claves persistidas en Firestore siguen siendo
`stars`/`totalStarsEarned` (no se rompe data). Se quitó la compra de
congeladores: ahora se ganan SOLO por constancia (1 cada 6 días). La "Tienda"
pasó a un bloque informativo de la economía. `GamificationState.spend(perlas)` +
`GamificationNotifier.spendPerlas(...)` para gastar en interacciones.

**Puntaje por pilar + anillos (F2a).** `ChallengeScoring.pillarPoints` suma los
pilares cerrados por día en la ventana (máx 5/día) — reemplaza el conteo binario
de días como métrica del reto (`consistencyPoints` se conserva para su test).
`ChallengeRings` (5 pilares del día). `ChallengeScore` ahora lleva `todayRings`
+ `qualifiedToday`; el controlador los publica desde la racha real.

**Zumbidos (F2b).** Catálogo CERRADO y positivo (`NudgeCatalog`: porra 2, fuego
3, zumbido 5 perlas), sin texto libre. Modelo `Nudge` + fuente/mapper/repo
Firestore en `challenges/{code}/nudges/{autoId}`. Reglas: solo creas a nombre
tuyo (`fromUid==tú`) dirigido a otro (`toUid!=tú`); sin update; el destinatario
puede borrar las suyas. `sendNudge` en el controlador gasta perlas
(optimista). `incomingNudgesProvider` alimenta la recepción in-app.

**Insignias + récord + revancha (F2c).** El récord vive en el wallet existente
(`retosJoined/Finished/Won/Rematches` + `retosCountedCodes` para idempotencia).
`RetoBadges.earnedIds(...)` (pura) decide qué insignias corresponden; se otorgan
por el sistema de insignias existente (categoría nueva `retos` en
`BadgeCategory` + whitelist de `firestore.rules` + definiciones en
`BadgeCatalog`). `rematch(old)` clona el reto (7 días). `recordOutcome(code,
didWin)` es idempotente por código.

**UI (F3).** Tablero con los 5 anillos por competidor + puntos; botón "animar"
por rival (resalta a quien "va colgado hoy"); hoja de envío de interacción con
costo en perlas; recepción in-app por SnackBar (con baseline para no spamear el
histórico); banner de cierre con ganador + "Otra vuelta (revancha)".

## Límites de la v1 (deliberados)
- **Sin push:** los zumbidos aparecen in-app (al abrir el reto), no como
  notificación del sistema. El push (Cloud Function + FCM) es una fase posterior.
- **Rate-limit / opt-out:** el catálogo cerrado + `fromUid/toUid` en reglas
  evita forjar y auto-zumbarse, pero el cooldown/cap por par y el opt-out de
  recepción quedan para la fase de push (donde el server puede imponerlos).
- **Cierre del reto:** se detecta en cliente al abrir un reto terminado (no hay
  cron). El resultado se cuenta una sola vez (idempotente por código).

## Tests
Dominio: `challenge_rings_test`, `nudge_test`, `reto_badges_test`,
`challenge_scoring_test` (pillarPoints), `challenge_mapper_test`. Aplicación:
`challenge_controller_test` (puntaje por pilar). Reglas: bloque
`SPEC-264 — nudges` en `firestore-tests/rules.test.mjs`.

## Pendiente para Carlos
`./scripts/validar.sh --reglas` en verde → `firebase deploy --only
firestore:rules` (nuevas subcolecciones nudges + categoría de insignia) →
commit + push.
