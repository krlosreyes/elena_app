# SPEC-168.0.C — GoalType.nutritionADominantPercent

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Extensión de dominio Goals
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~1 hora
**Padre:** SPEC-168.0
**Bloquea:** SPEC-168.0.A (onboarding necesita rationale), SPEC-168.2 (chart Nutrición)

---

## 1. Contexto

`GoalType` cubre los 5 pilares + composición corporal pero **Nutrición no tiene meta operacional**. Hoy el "objetivo nutricional" se mide implícitamente como `cocienteA` semanal y se compara contra un hard-code (`0.80`). No hay forma para el usuario de ajustar este threshold ni de ver "voy 60 % vs mi meta 70 %".

Esta SPEC agrega el `GoalType` faltante y el cálculo de sugerencia en `GoalSuggestionEngine`.

## 2. Decisiones de diseño

### 2.1 — Nuevo enum value

```dart
enum GoalType {
  weightTarget,
  bodyFatTarget,
  fastingDaysPerWeek,
  exerciseMinPerDay,
  sleepHoursPerNight,
  hydrationLitersPerDay,
  nutritionADominantPercent, // NUEVO
}
```

### 2.2 — Metadata en `UserGoal`

| Propiedad | Valor |
|-----------|-------|
| label | `Nutrición A-dominante` |
| unit | `%` |
| emoji | `🥦` |
| sliderMin | 50.0 |
| sliderMax | 90.0 |
| sliderDivisions | 8 (paso 5 %) |
| pillarColor | `0xFFE74C3C` o reutilizar pillar nutrición SPEC-140 |
| isReductionGoal | `false` |

Rango 50-90 % decidido conservadoramente:
- < 50 % no es coaching útil (todos podemos llegar a la mitad).
- > 90 % es muy estricto y desmotiva en early days.

### 2.3 — Cálculo de `progress`

Como `isReductionGoal=false`, usa la fórmula estándar `(current - start) / (target - start)`. El `currentValue` lo aporta el dashboard de Análisis al llamar `progress(currentCocienteAPct)`.

### 2.4 — Sugerencia en `GoalSuggestionEngine`

Nueva función `_nutritionSuggestion(UserModel user)`:

```dart
// Si el UserModel no trae histórico de cocienteA reciente, usamos
// 50% como baseline poblacional. Cuando el usuario tenga registros,
// el engine se recalcula con el dato real (SPEC-168.0.E).
final double current = user.recentCocienteAPct ?? 50.0;
final double target;
final bool outOfRange;

if (current < 60.0) {
  target = 70.0;
  outOfRange = true;
} else if (current < 75.0) {
  target = 80.0;
  outOfRange = true;
} else if (current < 85.0) {
  target = 85.0;
  outOfRange = false;
} else {
  target = current; // Ya excelente — mantener
  outOfRange = false;
}

return GoalSuggestion(
  type: GoalType.nutritionADominantPercent,
  currentValue: current,
  suggestedTarget: target,
  rationale:
      'Hoy tus comidas son ${current.toStringAsFixed(0)}% A-dominantes. '
      'El sistema metabólico se vuelve más eficiente cuando llegas a '
      '${target.toStringAsFixed(0)}%: la insulina baja, el ayuno '
      'siguiente se sostiene mejor y la flexibilidad metabólica se consolida.',
  shouldActivate: outOfRange,
  currentStatusLabel: _nutritionStatusLabel(current),
);

String _nutritionStatusLabel(double pct) {
  if (pct < 50) return 'Calidad baja';
  if (pct < 70) return 'Calidad media';
  if (pct < 85) return 'Buena calidad';
  return 'Calidad alta';
}
```

### 2.5 — `recentCocienteAPct` en UserModel

Verificar si existe. Si no, agregar campo derivado opcional en `UserModel` que `OnboardingController` o el bootstrap del dashboard pueblan con el promedio de las últimas 2 semanas (o `null` si no hay data suficiente). Si sigue null al momento de sugerir, fallback a 50 %.

Si agregar el campo a `UserModel` es invasivo, alternativa: pasar `recentCocienteAPct` como parámetro opcional a `GoalSuggestionEngine.suggest(user, {recentCocienteAPct})`. Decidir en implementación cuál genera menos cambios.

## 3. Cambios concretos

### 3.1 — `user_goal.dart`

- Agregar `nutritionADominantPercent` al enum.
- Agregar casos en `label`, `unit`, `emoji`, `sliderMin`, `sliderMax`, `sliderDivisions`, `pillarColor`, `isReductionGoal`.

### 3.2 — `goal_suggestion_engine.dart`

- Nuevo método `_nutritionSuggestion`.
- Incluirlo en el mapa de `suggest()`.
- Helper `_nutritionStatusLabel`.

### 3.3 — `goal_repository.dart`

- Sin cambios. La deserialización via `firstWhere((e) => e.name == json['type'])` ya maneja el nuevo enum value.
- **Backward-compat**: usuarios con map de goals sin `nutritionADominantPercent` siguen cargando — simplemente no tienen ese goal.

### 3.4 — Tests

`test/features/goals/nutrition_goal_test.dart` (nuevo):
- Suggestion con `current=50` → target 70, `shouldActivate=true`, label "Calidad baja".
- Suggestion con `current=80` → target 85, `shouldActivate=false`, label "Buena calidad".
- Suggestion con `current=null` → fallback 50, target 70.
- `UserGoal.progress(70)` con start=50 target=70 → 1.0.
- `UserGoal.progress(60)` con start=50 target=70 → 0.5.
- Serialización round-trip preserva el nuevo type.

## 4. Validación

### 4.1 — Unit
Suite de tests pasa.

### 4.2 — Manual
En onboarding paso 5 (SPEC-168.0.A) aparece card "🥦 Nutrición A-dominante" con sugerencia personalizada.

### 4.3 — No-regresión
Goals existentes en Firestore de usuarios actuales se cargan sin error.

## 5. Riesgo

- **Coexistencia con cocienteAGoal hard-coded**: hoy SPEC-137/158 usan threshold 0.80 fijo para evaluación interna. Mientras `UserGoal.nutritionADominantPercent` no esté activo para un usuario, seguir usando 0.80 como fallback. SPEC-168.0.D maneja la conversión chart↔goal.

## 6. Cierre

- [ ] enum extendido
- [ ] metadata UserGoal completa
- [ ] `_nutritionSuggestion` con rationale personalizado
- [ ] tests verdes
- [ ] backward-compat verificado con goals existentes
