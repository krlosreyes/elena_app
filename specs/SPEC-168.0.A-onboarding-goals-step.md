# SPEC-168.0.A — Paso 5 "Tus objetivos" en onboarding

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Integración UX — flujo onboarding
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~2 horas
**Padre:** SPEC-168.0
**Bloqueado por:** SPEC-168.0.C (necesita GoalType Nutrición antes)

---

## 1. Contexto

Hoy onboarding cierra en paso 4 (Habits) con `completeOnboarding(user)` y entra directo al dashboard. Inserción de paso 5 "Tus objetivos" usa la pieza ya construida `GoalSetupScreen` adaptada como step embebido.

## 2. Decisiones de diseño

### 2.1 — Narrativa coaching

El paso debe abrir con un encabezado claro y empático:

```
Tus objetivos personalizados

Calculamos estos objetivos para ti
con base en tu peso, edad y rutina.
Puedes ajustarlos cuando quieras.
```

Sin formularios en blanco. Sin "fija tu meta". Es Elena recomendando.

### 2.2 — Cards con sugerencia + rationale + slider

Cada uno de los 6 GoalType (7 con SPEC-168.0.C → Nutrición) se renderiza como card vertical:

```
⏱️ Días de Ayuno
─────────────────
RECOMENDAMOS PARA TI
5 días/semana

¿Por qué?  [expandible ▼]
Tu adherencia actual es 2.3 días/semana. La
investigación muestra que mantener el protocolo
≥5 días activa adaptaciones metabólicas sostenidas
que no ocurren con menos frecuencia.

Ajustar  [────●────────] 5 días/semana
                              [✓ Activar este objetivo]
```

Reutiliza el widget `_GoalSuggestionCard` existente en `goal_setup_screen.dart`. Lo importante: respetar la jerarquía visual **recomendación → por qué → ajuste**.

### 2.3 — Rationale debe usar números reales del usuario

Auditoría confirma que `GoalSuggestionEngine` YA genera rationales con números del usuario (ej. "Tu masa magra es 65.4 kg", "35 ml × 80 kg = 2.80 L"). En esta SPEC se valida que NO se renderiza copy genérico tipo "es importante hidratarse".

Lista de verificación de rationales personalizados (auditoría manual al implementar):

| Goal | Rationale debe incluir |
|------|------------------------|
| weightTarget | masa magra calculada + peso objetivo |
| bodyFatTarget | %grasa actual + zona ACSM + zona objetivo |
| fastingDaysPerWeek | adherencia actual en días + razón ≥5 |
| exerciseMinPerDay | minutos sugeridos + impacto en IMR |
| sleepHoursPerNight | rango 7-9 + impacto en ayuno |
| hydrationLitersPerDay | fórmula 35 ml × peso real |
| nutritionADominantPercent (nuevo) | adherencia A-dominante reciente + umbral 70 % |

### 2.4 — Estado del paso

`_OnboardingScreenState` actualmente tiene `_activeSteps` con índices 0-3. Agregar índice 4 = "Goals" en `_activeSteps` (si el flujo no se saltó).

Nuevos campos de state:
```dart
Map<GoalType, UserGoal> _draftGoals = {};
bool _goalsLoaded = false;
```

### 2.5 — Cargar sugerencias al entrar al paso

Cuando el PageView llega al índice 4:

```dart
if (!_goalsLoaded) {
  final suggestions = GoalSuggestionEngine.suggest(_buildUserFromState());
  setState(() {
    _draftGoals = {
      for (final s in suggestions.values)
        s.type: UserGoal(
          type: s.type,
          targetValue: s.suggestedTarget,
          startValue: s.currentValue,
          isActive: s.shouldActivate,
          createdAt: DateTime.now(),
        ),
    };
    _goalsLoaded = true;
  });
}
```

Nota: `_buildUserFromState()` ya existe (lo usa `completeOnboarding`) — reutilizable.

### 2.6 — Persistir al avanzar

En `_handleNext()`, cuando el step actual es Goals (último step):

```dart
final user = _buildUserFromState();
await ref.read(onboardingControllerProvider.notifier).completeOnboarding(user);
// NUEVO: guardar goals activos
final activeGoals = _draftGoals.values.where((g) => g.isActive).toList();
if (activeGoals.isNotEmpty) {
  await ref.read(goalsProvider.notifier).saveAll(activeGoals);
}
```

Si el usuario desactiva todo (extremo improbable), el dashboard simplemente no muestra goals — comportamiento legítimo.

### 2.7 — Botón "Omitir por ahora"

Pequeño, debajo del CTA principal:

```
[ Empezar mi plan ]
  Omitir por ahora
```

Si lo toca, igual `completeOnboarding(user)` pero sin `saveAll`. Posteriormente puede entrar a editar desde Perfil (SPEC-168.0.B).

## 3. Cambios concretos

### 3.1 — `onboarding_screen.dart`

- Agregar `_buildStepGoals(bool isDark)` siguiendo el patrón de `_buildStepHabits`.
- Insertar índice 4 en lista `pages` del PageView.
- Actualizar `_activeSteps` para incluir índice 4.
- Cargar `_draftGoals` lazily al entrar al paso.
- Persistir en `_handleNext` cuando step actual es Goals.

### 3.2 — `goal_setup_screen.dart`

- Extraer `_GoalSuggestionCard` como widget reusable público (si no lo es ya).
- Crear constructor alterno `GoalSetupScreen.embedded(...)` que omite AppBar y CTA — usado por onboarding. Modo standalone (con AppBar y CTA "Guardar") sigue existiendo para edición desde Perfil.

### 3.3 — `goal_repository.dart`

- Sin cambios. `saveAll` ya existe.

### 3.4 — Tests

`test/features/onboarding/goal_step_test.dart` (nuevo):
- Step Goals renderiza 7 cards.
- Sugerencias se generan a partir del UserModel parcial del state.
- `saveAll` se llama solo con goals con `isActive=true`.
- "Omitir por ahora" no llama `saveAll`.

## 4. Validación

### 4.1 — Manual en device
Carlos completa onboarding nuevo:
- Paso 5 aparece con título "Tus objetivos personalizados".
- Las 7 cards muestran número recomendado + rationale específico (con sus números).
- Ajustar slider mueve el target sin tocar otros goals.
- Botón "Empezar mi plan" persiste y avanza al dashboard.
- En dashboard, `goalsProgressDashboard` muestra los goals recién creados.

### 4.2 — Backward-compat
Usuarios existentes que NO pasaron por este paso siguen llegando al dashboard sin goals. Pueden entrar manualmente a editarlos (SPEC-168.0.B).

## 5. Riesgo

- **Fatiga del usuario en onboarding**: agregar un paso adicional puede aumentar abandono. Mitigación: copy claro "esto te toma 1 min y configura tu app a tu medida"; opción "Omitir por ahora" siempre visible.
- **Rationale copy duplicado entre pilares**: si el usuario lee 7 razones largas seguidas, fatiga textual. Mitigación: rationale colapsado por default ("¿Por qué?" expandible).

## 6. Cierre

- [ ] `_buildStepGoals` implementado
- [ ] `GoalSetupScreen.embedded` constructor disponible
- [ ] Persistencia en `_handleNext` cuando step = Goals
- [ ] Botón "Omitir por ahora" funciona
- [ ] Tests de step Goals pasando
- [ ] Validación visual Carlos
