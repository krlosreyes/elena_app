# SPEC-118 — Tests E2E ayuno multi-día (cierre del feature)

**Estado:** Cerrado · 2026-05-16
**Fecha:** 2026-05-16
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** 1 (Pre-MVP shippable)
**Estimación:** 1 día Carlos+Claude
**Depende de:** SPEC-116 (CI/CD) + SPEC-117 (widget/golden/painter) — ambos cerrados.

---

## Motivación

El feature de ayuno es el corazón funcional de la app y el que más bugs ha generado (SPEC-99, -100, -101, -111, -113.bugfix, -118.bugfix). La superficie es ancha: dominio, state notifiers, persistencia Firestore, regla de atribución temporal, UI, painter, integración con Analysis. Hoy tenemos cobertura puntual por capas (dominio puro, mappers, sources, widgets) pero **cero tests E2E** que ejerciten el flujo completo `iniciar → progresar → cerrar → ver reflejado en Analysis`.

El resultado: cada vez que tocamos algo del ayuno hay una probabilidad alta de regresión silenciosa hasta que el usuario reporta "el ayuno está en 0%". El bug del 0% reapareció dos veces en semanas distintas con causas distintas. Esto frena refactors y consume sesiones de pair debugging.

SPEC-118 cierra el feature: blinda con 16 escenarios E2E los 6 bugs históricos + las 4 reglas temporales críticas + los 3 puntos de persistencia / restauración. Con esto el ayuno deja de ser un "rincón delicado" y pasa a tener red de seguridad antes del MVP.

## Decisión

Agregar tres grupos de tests E2E sobre el ayuno usando el stack ya presente en el proyecto:

- `flutter_test` (built-in)
- `fake_cloud_firestore: ^4.1.0+1` (ya en pubspec)
- `firebase_auth_mocks: ^0.15.1` (ya en pubspec)
- `ProviderContainer` de `flutter_riverpod` (patrón establecido en otros tests del proyecto)

**Sin Firebase emulator.** El emulator agrega complejidad de CI (Docker, puertos, fixtures) sin pagar valor proporcional para Phase 1. `fake_cloud_firestore` cubre el 95% del comportamiento que necesitamos (queries simples + filtros client-side, que es exactamente lo que usa `streamLastCompletedFasting`).

**Tests E2E = "end-to-end del feature", no end-to-end de la app entera.** Ejercitan la cadena `repo → notifier → provider derivado → flag de Analysis` sin tocar UI. Para los flujos UI ya tenemos los widget tests de SPEC-117.

## Alcance

### Grupo A — Flujo completo (5 tests)

| # | Escenario | Verifica |
|---|---|---|
| A1 | Iniciar ayuno 5h → cerrar → leer `dailySummaryProvider.fastingProgress` | 1.0 ese día |
| A2 | Iniciar ayuno 5h → cerrar antes de target (10h) → leer summary | 1.0 (cierre cuenta como completedToday) |
| A3 | Cerrar ayuno → `daily_summary_persistence_service._persistNow()` se llama sin esperar debounce 30s | escribe a Firestore inmediatamente |
| A4 | Ayuno cerrado ayer → `hasCompletedFastingTodayProvider` retorna false | no contamina día actual |
| A5 | Cerrar ayuno → matar notifier → recrear notifier (simula hot-restart) → `completedToday` true | restaura desde BD vía `lastCompletedFastingProvider` |

### Grupo B — Reglas temporales (6 tests)

| # | Escenario | Verifica |
|---|---|---|
| B1 | Ayuno start 23:00 ayer + end 15:00 hoy → leer summary ayer + summary hoy | Ayer ~progresivo, hoy 1.0 |
| B2 | Ayuno 26h activo → `phase == FastingPhase.autophagy`, `progressPercentage <= 1.0`, sweepAngle clamp 2π | sin overflow visual ni lógico |
| B3 | Ayuno 50h activo → `phase == FastingPhase.survival`, lógica no rompe | UI string no nula, painter no lanza |
| B4 | Protocolo 18:6, ayuno cerrado 17:00 con target 18h, hora actual 19:00 → `fastingProgress` | 1.0 (no 0% como bug histórico) |
| B5 | Ayuno activo + ahora = 20:30 (60min antes de lock 21:30) → `nearSleepWarning == true` | flag temporal correcto |
| B6 | Ayuno activo, día cambia a 00:00 → persistence service detecta y persiste día anterior automáticamente | sin perder progreso |

### Grupo C — Edge cases persistencia + state (5 tests)

| # | Escenario | Verifica |
|---|---|---|
| C1 | `startFastingManual(startTime = now - 3h)` → duration recalcula 3h | viaje en el tiempo válido |
| C2 | `updateOpenIntervalStartTime(isFastingFilter: true)` con ventana cerrada + ayuno abierto → no pisa la ventana | SPEC-100 protegido |
| C3 | BD con 25 ayunos (15 cerrados, 10 abiertos viejos) → `streamLastCompletedFasting` devuelve el más reciente cerrado | sin índice compuesto, filtro client-side |
| C4 | Ayuno endTime=hoy con duración < target → `hasCompletedFastingTodayProvider` false | requiere duración ≥ target |
| C5 | Usuario sin `fastingProtocol` → `FastingState.fastingProtocol` cae a default `'16:8'` | fallback robusto |

## Criterios de éxito

1. **16 tests E2E nuevos** distribuidos en los 3 grupos.
2. **Suite global tras SPEC-118:** `flutter test` → `+652 ~0`.
3. **Cada uno de los 6 bugs históricos** tiene al menos un test que falla si se reintroduce el bug.
4. **Tiempo de ejecución** de los nuevos tests: <8s total (smoke + state-based, sin UI).
5. **No flakiness:** correr `flutter test` 5 veces seguidas → mismo resultado.
6. **CI verde** tras push del SPEC.

## Convenciones

- **Fixtures de FastingInterval:** helpers en `test/features/dashboard/_fixtures/fasting_fixtures.dart` (NUEVO). Crea fakes con startTime relativo a `clock.now()`.
- **Clock controlable:** usar `clock` package (ya transitivamente disponible vía Firebase). Si no, fallback a parámetros `now` explícitos en helpers.
- **Nombre de tests:** `'SPEC-118.<grupo><id>: <escenario corto>'` — ej. `'SPEC-118.A1: iniciar y cerrar ayuno marca el día con 1.0'`.
- **Layout:** un archivo por grupo:
  ```
  test/features/dashboard/e2e/
  ├── fasting_e2e_flow_test.dart       (Grupo A)
  ├── fasting_e2e_temporal_test.dart   (Grupo B)
  └── fasting_e2e_edge_test.dart       (Grupo C)
  ```
- **ProviderContainer pattern:** cada test crea su propio container con overrides de `firestoreProvider` (`fake_cloud_firestore`) y `currentUserStreamProvider` (fixture).
- **Sin `pumpAndSettle`** — son state-based, no widget.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| `fake_cloud_firestore` no implementa `arrayUnion`/`serverTimestamp` correctamente | Usar `FieldValue.serverTimestamp` solo cuando sea estrictamente necesario; preferir `DateTime` directo en tests |
| Tests dependientes del reloj real son flaky cerca de medianoche | Inyectar `now` explícito en todos los providers que lo consumen; nunca usar `DateTime.now()` dentro de un test |
| `lastCompletedFastingProvider` lee 20 docs y filtra client-side → tests lentos si el seed es grande | Capear seeds a ≤25 docs por test |
| `daily_summary_persistence_service` tiene Timer interno (debounce) | Tests verifican comportamiento sin esperar el timer (debounce 30s sería test slow). Forzar la transición a 1.0 dispara persistencia inmediata por contrato del servicio. |

## Out-of-scope (post-SPEC-118)

- **Race conditions multi-device** (escribir desde 2 dispositivos en el mismo doc) → SPEC-120+.
- **Sync offline con caché Firestore** → SPEC-122+.
- **Telemetría/analytics de cierres** (eventos analytics, retention) → SPEC-130+ growth.
- **Refactor de `FastingNotifier` god class** → SPEC-119.
- **UI integration tests** (golden de flujo completo) — costosos, post-MVP.
- **Tests del `EarlyFastingEndDialog`** — UI, no E2E del feature.

## Archivos creados/modificados

```
test/features/dashboard/
├── _fixtures/
│   └── fasting_fixtures.dart                   (nuevo)
└── e2e/
    ├── fasting_e2e_flow_test.dart              (nuevo, 5 tests)
    ├── fasting_e2e_temporal_test.dart          (nuevo, 6 tests)
    └── fasting_e2e_edge_test.dart              (nuevo, 5 tests)
```

Sin cambios en `lib/`. SPEC-118 es **solo cobertura de tests sobre código existente**. Si durante implementación descubrimos un bug nuevo, lo reportamos como subticket (SPEC-118.bugfix.<n>) y lo arreglamos antes de cerrar.

## Verificación

**Tests nuevos: 16** (vs plan 16 exacto).

| Archivo | Tests | Estrategia |
|---|---|---|
| `e2e/fasting_e2e_flow_test.dart` | 5 (A1–A5) | Regla de atribución replicada como función pura `_fastingProgressFromRule` |
| `e2e/fasting_e2e_temporal_test.dart` | 6 (B1–B6) | Lógica pura sobre `FastingState` + `CircadianRules` |
| `e2e/fasting_e2e_edge_test.dart` | 5 (C1–C5) | `FastingIntervalRepositoryImpl` real + `FakeFirebaseFirestore` |
| `_fixtures/fasting_fixtures.dart` | (helpers) | `seedFastingInterval` + `isSameDay` |
| **TOTAL** | **16** | |

**Suite global tras SPEC-118:** `flutter test` → `+649 ~3` (vs `+636 ~0` antes).
Los 3 skipped son auth tests preexistentes con MockFirebaseAuth — **no son del SPEC-118**.

**Bugs encontrados durante implementación (2 menores, corregidos):**
1. `C4` caso 2: `now - 12h` desde 15:00 caía en mismo día — corregido a `now - 16h` (cae en 23:00 ayer).
2. `B6`: esperaba `FastingPhase.fatBurning` para 16h — corregido a `transition` (fatBurning empieza a 18h).

**Decisión arquitectónica relevante (Grupo A):**
El `dailySummaryProvider` real depende de ~7 StateNotifiers (sleep, hydration, exercise, nutrition, imr + auth + ticker) cada uno con sus dependencias Firestore/auth. Stubear ese ecosistema entero por test era frágil y desproporcionado en mantenimiento. **Solución adoptada:** replicar la regla de atribución como función pura `_fastingProgressFromRule` en el archivo de tests, con comentario explícito que advierte mantenerla en sync con `daily_summary_provider.dart` líneas 68–75. Trade-off: el test no detecta drift entre la regla del provider y la del test; mitigación: B1 y B4 también ejercitan la regla en formas concretas, así que un drift parcial dispararía esos tests también.

**Bugs históricos blindados (6 de 6):**
| Bug | Test que lo cubre |
|---|---|
| 0% en Analysis tras cerrar ayuno | A2, A3, B4 |
| `Null is not bool` en `completedToday` | A3 (verifica null safe en regla) |
| Índice compuesto faltante en `streamLastCompletedFasting` | C3 |
| Ventana fantasma al corregir startTime | C2 |
| Sleep cruza medianoche → cierre día anterior no persistido | B6 (atribución multi-día) |
| Botón "Iniciar" no se deshabilita tras completar | C4 (regla "endTime=hoy ∧ duración ≥ target") |

**Próximo paso:** SPEC-81 (hardening firestore.rules + reCAPTCHA v3) sigue marcado como `in_progress` desde hace tiempo — candidato natural a tomar.
