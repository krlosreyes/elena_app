# SPEC-262 — Gamificación (estrellas, congeladores, niveles, tienda)

**Fecha:** 2026-08-01
**Estado:** Implementado (4 fases). Pendiente: validación + hooks de ganancia
adicionales (sueño, ejercicio, lección, peso, día-calificó) que son
one-liners documentados abajo.

## Objetivo

Benchmark de la gamificación de Fastic (racha grande, Frosties/congeladores,
Estrellas como moneda, XP/Nivel, Tienda, horas de ayuno de por vida) pero
**con datos reales y persistentes**: cada estrella, cada XP y cada hora nace de
una acción que el usuario realmente registró. No hay contadores inventados ni
pagos con dinero real.

## Principio de honestidad

- Las **estrellas** solo se ganan registrando hábitos saludables reales.
- Los **congeladores** se ganan por constancia (cada 6 días que califican para
  la racha) o se canjean con estrellas — nunca con dinero.
- El **nivel** refleja la constancia acumulada (XP total); no se compra.
- La **racha** y su historial ya eran reales (colección `streak_history`, un
  doc por día); esta feature NO la altera, solo enlaza a su pantalla.

## Arquitectura (feature-first, clean)

```
lib/src/features/gamification/
  domain/
    star_action.dart        # enum de acciones + tabla de recompensas (estrellas/XP)
    level_system.dart       # XP total → nivel + título + barra (puro)
    shop_item.dart          # catálogo de la Tienda (bundles de congeladores)
    gamification_state.dart  # value object inmutable + TODAS las transiciones puras
  data/
    sources/gamification_data_source.dart          # interfaz watch/save
    sources/firestore_gamification_v1_source.dart  # doc users/{uid}/gamification/state
    mappers/gamification_mapper.dart                # ↔ Firestore
    gamification_repository.dart                    # repo + provider
  application/
    gamification_notifier.dart  # StateNotifier offline-first + `awardStar(ref, action)`
  presentation/
    gamification_stats_screen.dart  # "Tus estadísticas" + Tienda + explainers
```

### Economía (todo puro y testeado, `GamificationState`)
- `earn(StarAction)` → suma estrellas (saldo + de-por-vida) y XP.
- `onDayQualified()` → bonus del día + contador de constancia; cada
  `daysPerFrosty` (6) días que califican regala 1 congelador.
- `addFastingHours(h)` → horas de ayuno de por vida.
- `purchase(ShopItem)` → descuenta estrellas y suma congeladores (null si no
  alcanza; no muta).
- `useFrosty()` → gasta un congelador (null si no hay).

### Niveles (`LevelSystem`)
- `cumXp(L) = 100·L·(L−1)` → nivel 2 = 200 XP, nivel 8 = 5600 XP.
- Cada nivel cuesta `200·L` XP (crece con el nivel).
- Títulos: Novato → Aprendiz → … → Gurú de la salud (8) → Leyenda (9+).

### Recompensas (`StarAction`, calibrable)
| Acción | Estrellas | XP |
|---|---|---|
| agua | 2 | 5 |
| comida | 3 | 8 |
| ayuno iniciado | 5 | 10 |
| ayuno completado | 15 | 40 |
| sueño | 5 | 12 |
| ejercicio | 5 | 15 |
| lección | 4 | 10 |
| peso | 3 | 8 |
| día calificó (bonus) | 10 | 30 |

### Tienda (`Shop`)
| Paquete | Congeladores | Costo |
|---|---|---|
| Congelador | 1 | 50 ⭐ |
| 3 congeladores | 3 | 125 ⭐ |
| 5 congeladores | 5 | 200 ⭐ |

## Persistencia (offline-first)

Documento único `users/{uid}/gamification/state`. Patrón espejo de
`alcohol_session`: actualización optimista local + persistencia no bloqueante
(nunca `await` un write). El catch-all `/{allPaths=**}` de `firestore.rules`
permite create/update del dueño (colección `gamification` NO excluida,
`withinSizeLimit` < 100 KB, sin campo `id`) → **no requiere regla nueva**.

## Robustez (no romper nada)

La gamificación es **best-effort** y jamás puede tumbar el registro de un
pilar:
- `awardStar(ref, action)` traga cualquier error.
- El cierre de ayuno envuelve las llamadas en `try/catch`.
- `GamificationNotifier._subscribe` y `._persist` se auto-protegen: si Firestore
  no está disponible (tests sin Firebase con usuario activo), no propagan.

## Ganancia enganchada (hooks)

- **Agua** — `HydrationNotifier.addWater` → `StarAction.water`.
- **Comida** — `NutritionNotifier.logMeal` (solo comidas nuevas, no ediciones)
  → `StarAction.meal`.
- **Ayuno completado** — `FastingNotifier.confirmManualFastingEnd` →
  `recordFastingHours` + `StarAction.fastingCompleted`.

### Hooks pendientes (one-liners, mismo patrón `awardStar(_ref, ...)`)
- Sueño: al registrar sueño → `StarAction.sleepLogged`.
- Ejercicio: al registrar ejercicio → `StarAction.exerciseLogged`.
- Lección "Aprende con Elena": al leer → `StarAction.lessonRead`.
- Peso/biometría: al registrar → `StarAction.weightLogged`.
- Día calificó: desde el StreakNotifier al persistir un día que califica →
  `gamificationProvider.notifier.onDayQualified()` (regala congeladores por
  constancia).

## Acceso

Pantalla `/estadisticas` (`GamificationStatsScreen`), accesible desde el ícono
de estadísticas en el AppBar de "Tu racha" (`/analysis/racha`).

## Tests

- `star_action_test`, `level_system_test`, `gamification_state_test`
  (dominio puro, exhaustivos).
- `gamification_mapper_test` (round-trip).
- `gamification_notifier_test` (offline: reward / compra / congelador por
  constancia / horas de ayuno).
