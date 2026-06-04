# SPEC-168.0.D — goalForChartProvider (helper puente)

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Application layer — provider Riverpod nuevo
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~1 hora
**Padre:** SPEC-168.0
**Bloquea:** SPEC-168.2 (línea de objetivo), SPEC-168.8 (color por estado)

---

## 1. Contexto

Los charts de Análisis muestran cada métrica en una **unidad de visualización** que no siempre coincide con la **unidad de meta** del usuario:

| Pilar | Unidad chart | Unidad goal | Conversión |
|-------|--------------|-------------|------------|
| Ayuno | días cumplidos/semana | días/semana | identidad |
| Nutrición | % A-dominante | % (SPEC-168.0.C) | identidad |
| Hidratación | % vs 2.5 L meta | L/día | `goal × 100 / 2.5` |
| Ejercicio | min/día | min/día | identidad |
| Sueño | h/noche | h/noche | identidad |
| Peso | kg | kg | identidad |
| IMR | score 0-100 | no editable | hard-code 75 |

SPEC-168.2 (línea de objetivo) y SPEC-168.8 (color por estado) necesitan un único punto de acceso al target del usuario en la **unidad del chart**, no del goal. Este SPEC crea ese puente.

## 2. Decisiones de diseño

### 2.1 — API del provider

```dart
/// SPEC-168.0.D: devuelve el target del usuario para una métrica de chart,
/// expresado en la unidad de visualización (no en la unidad del UserGoal).
/// Si el usuario no activó el goal correspondiente, devuelve null
/// (los charts no pintarán línea de objetivo).
final goalForChartProvider = Provider.family<double?, ChartMetric>((ref, metric) {
  final goals = ref.watch(goalsProvider).valueOrNull ?? const [];
  return _goalForMetric(metric, goals);
});
```

### 2.2 — Enum `ChartMetric`

Pure Dart, vive en `lib/src/features/analysis/domain/chart_metric.dart`:

```dart
enum ChartMetric {
  imr,
  weight,
  fastingDays,
  nutritionAPct,
  hydrationPct,
  exerciseMin,
  sleepHours,
}
```

Identificadores estables — los charts del Análisis los referencian de forma simbólica.

### 2.3 — Lógica de conversión

```dart
double? _goalForMetric(ChartMetric m, List<UserGoal> goals) {
  UserGoal? find(GoalType t) =>
      goals.where((g) => g.type == t && g.isActive).firstOrNull;

  switch (m) {
    case ChartMetric.imr:
      return 75.0; // hard-code SPEC-141, no editable
    case ChartMetric.weight:
      return find(GoalType.weightTarget)?.targetValue;
    case ChartMetric.fastingDays:
      return find(GoalType.fastingDaysPerWeek)?.targetValue;
    case ChartMetric.nutritionAPct:
      return find(GoalType.nutritionADominantPercent)?.targetValue;
    case ChartMetric.hydrationPct:
      // Conversión clave: goal es L/día, chart es % vs 2.5L
      final goal = find(GoalType.hydrationLitersPerDay)?.targetValue;
      return goal == null ? null : (goal * 100 / 2.5).clamp(0.0, 200.0);
    case ChartMetric.exerciseMin:
      return find(GoalType.exerciseMinPerDay)?.targetValue;
    case ChartMetric.sleepHours:
      return find(GoalType.sleepHoursPerNight)?.targetValue;
  }
}
```

### 2.4 — Label formateado del objetivo

Helper paralelo para el texto que aparece junto a la línea dashed (SPEC-168.2):

```dart
final goalLabelForChartProvider =
    Provider.family<String?, ChartMetric>((ref, metric) {
  final goal = ref.watch(goalForChartProvider(metric));
  if (goal == null) return null;
  switch (metric) {
    case ChartMetric.imr:        return goal.toStringAsFixed(0);
    case ChartMetric.weight:     return '${goal.toStringAsFixed(1)} kg';
    case ChartMetric.fastingDays:return '${goal.toStringAsFixed(0)} d/sem';
    case ChartMetric.nutritionAPct: return '${goal.toStringAsFixed(0)} %';
    case ChartMetric.hydrationPct:  return '${goal.toStringAsFixed(0)} %';
    case ChartMetric.exerciseMin:   return '${goal.toStringAsFixed(0)} min';
    case ChartMetric.sleepHours:    return '${goal.toStringAsFixed(1)} h';
  }
});
```

### 2.5 — Defaults para hidratación (constante)

`2.5` litros se mantiene como meta hard-coded de hidratación 100 % en los providers (`hydrationHabitSeriesProvider` ya lo usa). Si en futuro el usuario configura litros/día y los charts también deben ajustarse, refactorizamos. Por ahora: dual — el goal del usuario manda la línea de objetivo, pero la escala del chart sigue en 2.5 L base.

## 3. Cambios concretos

### 3.1 — Nuevo archivo `chart_metric.dart`

Enum + ningún método.

### 3.2 — Nuevo archivo `goal_for_chart_provider.dart`

Bajo `lib/src/features/analysis/application/`. Importa `goalsProvider` y `UserGoal`. Provider family.

### 3.3 — `analysis_screen.dart`

Cada llamada a `BarChartCard` o `LineChartCard` (cuando SPEC-168.2/.8 las extiendan con `targetValue`) hace:

```dart
final target = ref.watch(goalForChartProvider(ChartMetric.fastingDays));
final targetLabel = ref.watch(goalLabelForChartProvider(ChartMetric.fastingDays));
BarChartCard(..., targetValue: target, targetLabel: targetLabel);
```

### 3.4 — Tests

`test/features/analysis/goal_for_chart_provider_test.dart` (nuevo):
- Sin goals activos → todos los chart metrics devuelven null (excepto IMR=75).
- Goal `hydrationLitersPerDay=2.0` → `ChartMetric.hydrationPct` = 80.0.
- Goal `fastingDaysPerWeek=5` → `ChartMetric.fastingDays` = 5.0.
- Goal con `isActive=false` → devuelve null.

## 4. Validación

Tests pasan. SPEC-168.2 cablea sin tocar lógica de cálculo.

## 5. Riesgo

- **Conversión inconsistente hidratación**: si el chart usa 2.5 L como denominador pero el goal del usuario es 3 L, la línea de objetivo daría 120 %. Ya está clampeada a 200 % pero visualmente sale del rango "normal". Mitigación: SPEC-168.2 expande yMax si target > maxV; aceptable.

## 6. Cierre

- [ ] enum ChartMetric creado
- [ ] goalForChartProvider + goalLabelForChartProvider implementados
- [ ] Tests verdes
- [ ] analysis_screen lo cablea en SPEC-168.2/.8
