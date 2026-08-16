# SPEC-299 — Retos: rediseño moderno + avatares + perlas claras

**Estado:** IMPLEMENTED (falta analyze+tests de Carlos y validar en simulador).
**Fecha:** 2026-08-16
**Rama:** `feat/pilar-alimentacion-minuta`

## 1. Pedido de Carlos

La pantalla de Retos "es un asco", necesita una interfaz moderna y motivadora;
no se entienden las perlas ni cómo se usan; y en el tablero debe aparecer la
foto/avatar de cada usuario para identificarlo y personalizarlo.

## 2. Diagnóstico

- Pantalla plana, sin jerarquía: intro larga, un toggle técnico arriba y una fila
  gris por reto. No comunica qué se gana ni por qué competir.
- Las perlas solo aparecían como "cuesta X perlas" al enviar un zumbido — nunca
  se mostraba el saldo, qué son ni de dónde salen.
- El tablero (`challenge_detail`) mostraba solo rank + nombre + puntos; sin
  avatar. Además, la foto del rival no estaba disponible: `ChallengeScore` no la
  publicaba y `ProfileAvatar` solo lee MI sesión de auth.

## 3. Implementación

### 3.1 Avatares en el tablero
- `ChallengeScore.photoUrl` (String?) nuevo; mapper lo serializa (omitido si
  null). Las reglas de `scores/{uid}` no bloquean campos → sin cambio de rules.
- `challenge_controller._myScoreFor` publica la foto leyendo
  `authStateProvider.photoUrl` (AppAccount), con lectura blindada en try/catch
  (si no hay sesión o en tests sin Firebase, va sin foto y no rompe la
  publicación del puntaje).
- Widget nuevo `ChallengeAvatar` (foto → inicial → icono), independiente de la
  sesión (pinta a cualquier participante desde su score). Se usa en el
  `_LeaderRow` del detalle y en el mini-tablero de la lista.

### 3.2 Rediseño de `challenges_screen`
- Hero: "Compites por constancia" + 5 anillos de los pilares.
- Tarjeta de PERLAS: saldo real (`gamificationProvider.stars`) + una línea de qué
  son; toca → hoja "Qué son las perlas" (ganas cumpliendo / animas rivales /
  proteges tu racha con congeladores). Píldora de saldo también en el AppBar.
- Tarjetas de reto con mini-tablero VIVO: avatar + nombre + 5 anillos de hoy +
  puntos por participante (top 3), tu fila resaltada, barra de progreso del
  período ("Día X de N") y una línea motivadora ("Vas 1º por N pts…").
- El toggle de zumbidos baja al final (ajuste), ya no compite arriba. De paso se
  migró `activeColor` (deprecado) → `activeThumbColor`.

## 4. No-regresión
- `ChallengeScore` sigue construyéndose por named args; `photoUrl` opcional.
- Round-trip del mapper y defaults intactos (test ampliado).
- El test del controller sigue verde: la lectura de auth está blindada.

## 5. Tests
`challenge_mapper_test.dart`: photoUrl round-trip + se omite cuando es null.

## 6. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/challenges test/features/challenges
flutter test test/features/challenges
```

En simulador: abre Retos → hero + tarjeta de perlas con saldo; entra a un reto y
confirma que en el tablero aparece tu foto (si iniciaste con Google) y la inicial
para quien no tenga. La lista debe mostrar el mini-tablero con avatares.
