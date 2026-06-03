# SPEC-154 — GoalsProgressDashboard: progreso visible de objetivos en Análisis

**Estado:** CLOSED (pendiente validación visual en device)
**Versión:** 1.0
**Fecha:** 2026-06-02
**Tipo:** Pieza de Ola 2 — resuelve dolor "no clear plan"
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 2 — Convertir app en coach
**Estimación:** 1-2 sesiones
**Marco normativo:** `CONSTITUTION.md`. Consume `goalsProvider` (SPEC-14) y `periodDataProvider` (SPEC-113).

---

## 1. Contexto

Durante el reporte del 2026-06-02 Carlos identificó **"no clear plan"** como uno de los 7 problemas críticos. La infraestructura de objetivos (`SPEC-14`) está completa:
- `UserGoal` domain con `progress()` calculado.
- `GoalNotifier` reactivo persistido en Firestore.
- `GoalSuggestionEngine` con base científica para 6 tipos.
- `GoalSetupScreen` para configurar.

**Lo que falta es la superficie de coaching visible** que le diga al usuario "este es tu plan, así vas". Esta SPEC añade `GoalsProgressDashboard` debajo del `WeeklyCoachingCard` en Análisis.

## 2. Decisión de diseño

### 2.1 — Layout

```
┌─────────────────────────────────────────────┐
│ TUS OBJETIVOS                       Editar →│ ← header + CTA setup
│                                              │
│ ⚖️ Peso Objetivo            ▓▓▓▓░░░ 47%     │
│    84.5 → 78.0 kg                            │
│    3.1 kg recorridos                         │
│                                              │
│ 🌙 Sueño                    ▓▓▓░░░░ 38%     │
│    6.3 → 7.5 h/noche                         │
│    1.2h promedio bajo el target              │
│                                              │
│ 💧 Hidratación              ▓▓▓▓▓▓░ 87%    │
│    2.1 → 2.5 L/día                           │
│    Casi llegás. Sumá 400ml más.              │
└─────────────────────────────────────────────┘
```

### 2.2 — Empty state

Si el usuario no tiene objetivos activos:

```
┌─────────────────────────────────────────────┐
│ TUS OBJETIVOS                                │
│                                              │
│  🎯 Definí tu plan                          │
│                                              │
│  Sin objetivos no hay ruta clara.            │
│  Elena puede sugerirte 6 basados en          │
│  tu estado actual.                           │
│                                              │
│  [Configurar mis objetivos] →                │
└─────────────────────────────────────────────┘
```

CTA navega al `GoalSetupScreen` existente.

### 2.3 — Mapeo de `currentValue` por tipo

| GoalType | Fuente del currentValue |
|---|---|
| `weightTarget` | `UserModel.weight` (directo) |
| `bodyFatTarget` | `UserModel.bodyFatPercentage` (directo) |
| `fastingDaysPerWeek` | Count de docs con `fastingProgress ≥ 0.95` en últimos 7 días |
| `exerciseMinPerDay` | Promedio de `exerciseProgress * user.exerciseGoalMinutes` en últimos 7 días, convertido a minutos |
| `sleepHoursPerNight` | Promedio de `sleepProgress * 8` en últimos 7 días (8h es la base del cálculo en `dailySummaryProvider`) |
| `hydrationLitersPerDay` | Promedio de `hydrationProgress * dailyGoalLiters` en últimos 7 días |

### 2.4 — Mensaje de progreso

Bajo cada barra, una línea derivada del progreso:

- **Si `progress < 0.10`** y goal recién creado: "Estás arrancando. El primer paso es lo más difícil."
- **Si `progress < 0.50`**: "Llevás X% del camino" (ej: "47% recorrido").
- **Si `progress >= 0.50` y `< 0.85`**: "Más de la mitad. Seguí así."
- **Si `progress >= 0.85`**: "Casi llegás. [acción concreta para cerrar gap]."
- **Si `progress >= 1.0`**: "✅ Objetivo alcanzado. Considerá uno nuevo."

Para los del 4to caso, la "acción concreta" sale del gap:
- Peso: "Faltan X kg."
- Cintura/grasa: "Faltan X cm/%."
- Sleep/Exercise/Hydration: "Sumá X más."

### 2.5 — Ordenamiento

Los goals se ordenan por progreso descendente (los más cercanos a la meta arriba) — refuerza la sensación de logro. Empate por `type.index`.

## 3. Cambios técnicos

### 3.1 — Nuevo dominio `GoalProgressSnapshot`

`lib/src/features/goals/domain/goal_progress_snapshot.dart`:

```dart
class GoalProgressSnapshot {
  final UserGoal goal;
  final double currentValue;
  final double progress; // 0..1
  final String motivationalMessage;
  
  bool get isAchieved => progress >= 1.0;
}
```

### 3.2 — `GoalProgressComputer` (pure Dart)

`lib/src/features/goals/application/goal_progress_computer.dart`:

Función estática `compute(goal, currentValue) → GoalProgressSnapshot` que aplica:
- `goal.progress(currentValue)` (ya existe).
- `motivationalMessage` según §2.4.

Función `buildCurrentValues(user, weekDocs) → Map<GoalType, double>` que aplica los mapeos de §2.3.

### 3.3 — Provider `goalsProgressProvider`

`lib/src/features/goals/application/goals_progress_provider.dart`:

- Combina `goalsProvider` + `currentUserStreamProvider` + `periodDataProvider(AnalysisPeriod.week)`.
- Por cada goal activo, computa snapshot.
- Devuelve `AsyncValue<List<GoalProgressSnapshot>>` ordenado por progreso descendente.

### 3.4 — Widget `GoalsProgressDashboard`

`lib/src/features/goals/presentation/goals_progress_dashboard.dart`:

- ConsumerWidget que watchea `goalsProgressProvider`.
- Empty state si no hay goals activos con CTA al `GoalSetupScreen`.
- Para cada snapshot: emoji + label + barra discreta (7 niveles) + % + "start → target unit" + mensaje motivacional.

### 3.5 — Integración

En `analysis_screen.dart`, montar debajo del `WeeklyCoachingCard`.

## 4. Criterios de aceptación

1. La pantalla Análisis muestra `GoalsProgressDashboard` debajo del WeeklyCoachingCard.
2. Si el usuario no tiene goals activos, ve el empty state con CTA que navega al `GoalSetupScreen`.
3. Si tiene goals, ve cada uno con: emoji, label, barra de 7 niveles, %, "start → target unit", mensaje.
4. Los goals se ordenan por progreso descendente.
5. El currentValue se calcula correctamente según §2.3 (peso/grasa del UserModel; ayuno/ejercicio/sueño/hidratación del periodData semanal).
6. Si una métrica del periodData no tiene 7 días de data, se promedia con lo que haya.
7. Tests cubren: `buildCurrentValues` (los 6 tipos), `motivationalMessage` (las 5 ramas), ordenamiento.

### 4.1 — Sobre tests

Computer es pure Dart → tests cubren los 6 mapeos + las 5 ramas del mensaje motivacional. Widget test NO (frágil). Validación visual.

## 5. Out of scope (explícito)

- **Notificaciones de progreso** ("vas al 70% de tu objetivo de peso"): SPEC separada futura.
- **Múltiples objetivos del mismo tipo** (peso a 80 ahora, peso a 75 después): el `UserGoal` actual asume uno por tipo.
- **Edición inline desde el dashboard**: solo redirige al `GoalSetupScreen`.
- **Histórico de progreso por goal**: no se persiste, se recalcula en cada watch.

## 6. Rollout

Sin breaking changes. Sin migración. Push directo a `mvp-core-clean` + validación visual.

## 7. Changelog

### v1.0 — 2026-06-02

Aprovecha infraestructura existente de SPEC-14 para resolver el dolor "no clear plan" reportado el 2026-06-02. Tercera pieza de Ola 2 después de SPEC-152 y SPEC-153.
