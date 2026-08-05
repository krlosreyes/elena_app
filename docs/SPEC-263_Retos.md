# SPEC-263 — Retos de constancia (competencia social sana)

**Estado:** implementado (pendiente de `analyze` + tests en verde por Carlos).
**Fecha:** 2026-08-05.
**Depende de:** SPEC-262 (gamificación), sistema de racha (`streak_history`).

## Qué es y por qué

Los usuarios quieren competir con amigos igual que en una apuesta real de
"quién baja más de peso en un mes". Elena traslada esa motivación a un terreno
sano: la métrica del reto es **CONSTANCIA**, no peso.

> **Decisión de salud (explícita):** competir por peso incentiva conductas de
> riesgo (restricción, báscula obsesiva, TCA). El reto premia el hábito
> sostenido: cuántos días del período **califican para la racha**
> (`StreakEntry.qualifiesForStreak` = ≥3 pilares con ancla). Sale del
> historial REAL y persistido del usuario; no se puede inflar registrando agua
> 50 veces.

## Modelo de datos

Dos documentos por reto, **cada uno con un solo escritor**, para que las reglas
de Firestore sean simples y a prueba de balas:

```
challenges/{code}                 → metadata del reto
challenges/{code}/scores/{uid}    → puntaje de cada miembro (solo lo escribe él)
```

- `{code}` es el **id del documento** y a la vez el **código de invitación**.
  Resuelve el problema del huevo y la gallina (para unirte necesitas leer, para
  leer necesitas ser miembro): conocer el código es la capacidad de acceso, así
  que `read: if signedIn()`. Los códigos son aleatorios (alfabeto de 31
  símbolos sin `0/O/1/I`), enumerarlos es inviable.
- "Mis retos" = query `challenges where memberIds array-contains uid`. Es un
  índice de **campo único automático** (no toca `firestore.indexes.json`)
  porque no se combina con ningún `orderBy` — el orden se hace en cliente.

### Por qué cada quien publica su propio puntaje

Las reglas solo dejan a cada usuario **leer su propio `streak_history`**. Por
eso el puntaje no se puede calcular "del lado del que mira": cada miembro
calcula SU puntaje localmente (desde su racha real) y lo publica en
`scores/{uid}`. El tablero se arma leyendo esos puntajes ya publicados. Nadie
ve datos de salud crudos de otro — solo un nombre y un número de días.

## Reglas de Firestore (invariante clave: "unirse")

El caso más delicado es la actualización. Un miembro puede **agregarse solo a
sí mismo** a `memberIds`; nada más puede cambiar:

```
allow update: if signedIn()
  && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['memberIds'])
  && !(request.auth.uid in resource.data.memberIds)
  && (request.auth.uid in request.resource.data.memberIds)
  && request.resource.data.memberIds.hasAll(resource.data.memberIds)
  && request.resource.data.memberIds.size() == resource.data.memberIds.size() + 1;
```

Esto bloquea: renombrar el reto al unirse, mover fechas, robar la propiedad,
agregar a un tercero, echar a otro miembro y "re-unirse" sin cambios. Cada uno
tiene su test en `firestore-tests/rules.test.mjs` (16 casos nuevos). El patrón
`.diff().affectedKeys().hasOnly()` ya estaba probado en `metamorfosis_posts`.

> Se cuidó la trampa **FIX-DELETE**: ni `withinSizeLimit()` ni
> `request.resource` en reglas de `delete` (en un DELETE `request.resource` no
> existe y la regla fallaría).

## Capas

- **Dominio** (`domain/`): `Challenge` (value object inmutable, `statusOn`),
  `ChallengeScore`, `ChallengeScoring` (puro: `consistencyPoints`,
  `leaderboard`, `winner`, `generateInviteCode`).
- **Datos** (`data/`): `ChallengeDataSource` + `FirestoreChallengeV1Source`,
  `ChallengeMapper`, `ChallengeScoreMapper`, `ChallengeRepository` (+ provider).
- **Aplicación** (`application/`): `ChallengeController` (crear / unirse /
  publicar puntaje / borrar), providers de lectura (`myChallengesProvider`,
  `challengeProvider`, `challengeLeaderboardProvider`) y el seam
  `challengeStreakHistoryProvider` (inyectable en tests).
- **Presentación** (`presentation/`): `ChallengesScreen` (lista + hojas de
  crear/unirse) y `ChallengeDetailScreen` (código + tablero). Rutas `/retos` y
  `/retos/:code`. Acceso desde "Tus estadísticas" (`_RetosCard`).

## Invariante de ventana (≤ 30 días)

El puntaje se calcula desde `streakProvider.history`, que mantiene **30 días**
en memoria. La UI de creación ofrece 7 / 14 / 30 días para no salir de esa
ventana. Si a futuro se quieren retos más largos, hay que leer `streak_history`
directo por rango en vez de la historia en memoria.

## Tests

- `challenge_test.dart`, `challenge_scoring_test.dart` — dominio puro.
- `challenge_mapper_test.dart` — round-trip de mappers.
- `challenge_controller_test.dart` — crear/unirse/errores con repo en memoria.
- `firestore-tests/rules.test.mjs` — 16 casos de seguridad del reto.

## Pendiente / futuro

- Compartir el código con `share_plus` (hoy: copiar al portapapeles).
- "Salir del reto" para no-dueños (hoy las reglas solo permiten agregarse, no
  quitarse de `memberIds`; se puede borrar el propio `scores/{uid}`).
- Notificación al cierre del reto anunciando al ganador.
