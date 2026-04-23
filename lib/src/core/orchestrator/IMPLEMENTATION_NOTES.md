# SPEC-34: Orquestrador Central de Pilares - Notas de Implementación

## Estado: FASE 1 - Estructura Base Completada

### Archivos Creados ✅

#### 1. **orchestrator_state.dart** (Modelo de Datos)
- Define `OrchestratorState` (Freezed class)
- Campos: currentFastingPhase, currentCircadianPhase, canExerciseNow, canEatNow, etc.
- Métodos helper: `hasSyncViolations`, `isOptimal`
- Serialización JSON para persistencia futura

#### 2. **orchestrator_service.dart** (Lógica de Negocio)
- `calculateState()`: Calcula estado sincronizado completo
- `_canExerciseNow()`: RF-34-02 - Valida si es seguro ejercitar
- `_canEatNow()`: Determina si estamos en ventana circadiana
- `_getExerciseRecommendation()`: Recomienda tipo + intensidad por fase
- `_detectSyncViolations()`: Detecta conflictos entre pilares
- `_calculateMetabolicCoherence()`: Score de sincronización (0-1)
- Multiplicadores de seguridad para ejercicio y nutrición

#### 3. **orchestrator_notifier.dart** (State Management)
- Observa cambios en FastingNotifier, NutritionNotifier, ExerciseNotifier, SleepNotifier, HydrationNotifier
- Recalcula estado completo cuando cualquier pilar cambia
- API pública: `canExerciseNow()`, `canEatNow()`, `getMetabolicCoherence()`, etc.
- Logging de violaciones detectadas

#### 4. **orchestrator_provider.dart** (Riverpod Providers)
- `orchestratorProvider`: Estado principal
- `orchestratorStateProvider`: Selector de estado
- 12 selectores especializados (canExerciseNowProvider, etc.)
- Todos disponibles para ser observados por widgets/notifiers

#### 5. **exercise_validator.dart** (Validador de Ejercicio)
- `validateExercise()`: RF-34-02 - Valida tipo/intensidad contra estado
- Previene HIIT en Autofagia profunda
- Advierte sobre intensidad vs sleep recovery
- Retorna (esSeguro, razonSiNo)

### Archivos Modificados ✅

#### 1. **score_engine.dart**
- Parámetro nuevo: `metabolicCoherence` (default 0.8)
- Bonus de coherencia: +5% máximo si metabolicCoherence > 0.8
- Fórmula: `raw * (1.0 + coherenceBonus)`

### Próximos Pasos: Integración en Notifiers Existentes

#### 1. **fasting_notifier.dart** - PENDIENTE
```dart
// En _updateFastingState():
final orchestrator = ref.read(orchestratorProvider.notifier);
// El cambio en fastingState disparará recálculo automático en OrchestratorNotifier
```

#### 2. **nutrition_notifier.dart** - PENDIENTE
```dart
// En logMeal():
final exerciseSafetyMult = ref.read(exerciseSafetyMultiplierProvider);
final nutritionPhaseMult = ref.read(nutritionPhaseMultiplierProvider);
// Aplicar multiplicadores al cálculo de nutrition score
```

#### 3. **exercise_notifier.dart** - PENDIENTE
```dart
// En logExercise():
final (isValid, reason) = ExerciseValidator.validateExercise(...);
if (!isValid) {
  // Mostrar warning al usuario
}
```

#### 4. **app.dart** - PENDIENTE
```dart
// En build():
ref.watch(orchestratorProvider); // Mantener vivo durante sesión
```

### Cómo Funciona la Sincronización

```
┌─────────────────────────────────────────────────────┐
│  Cambio en cualquier pilar (Fasting, Nutrition, etc)│
└────────────────┬────────────────────────────────────┘
                 │
                 ├─→ Riverpod detecta cambio
                 │
                 └─→ OrchestratorNotifier.listen() se dispara
                    │
                    ├─→ Llama _recalculateState()
                    │
                    ├─→ Lee estados actuales de todos los pilares
                    │
                    ├─→ Llama OrchestratorService.calculateState()
                    │
                    ├─→ Calcula:
                    │   ├─ Fase de ayuno actual
                    │   ├─ Fase circadiana
                    │   ├─ ¿Es seguro comer/ejercitar?
                    │   ├─ Tipo/intensidad de ejercicio recomendado
                    │   ├─ Violaciones de sincronización
                    │   ├─ Score de coherencia metabólica (0-1)
                    │   └─ Multiplicadores de seguridad
                    │
                    └─→ Actualiza state = OrchestratorState
                       │
                       └─→ Todos los widgets observando selectores se reconstruyen
```

### Criterios de Aceptación (RF-34-01 a RF-34-05)

- ✅ **RF-34-01**: OrchestratorNotifier observa todos los pilares en tiempo real
- ✅ **RF-34-02**: ExerciseValidator previene HIIT en Autofagia (validación)
- ✅ **RF-34-03**: circadianAlignment penalty granular + bonus de coherencia en IMR
- ✅ **RF-34-04**: API pública en OrchestratorService (getState, canExerciseNow, etc)
- ⏳ **RF-34-05**: Notificaciones sugiriendo transiciones (fase UI futura)

### Integración en Cálculo de IMR

Cuando NutritionNotifier registra comida:
```
1. Calcula nutritionScore local
2. Obtiene exerciseSafetyMultiplier del orchestratorProvider
3. Obtiene nutritionPhaseMultiplier del orchestratorProvider
4. Al final, ScoreEngine.calculateIMR():
   - Recibe metabolicCoherence = ref.read(metabolicCoherenceProvider)
   - Aplica bonus: raw * (1.0 + coherenceBonus)
   - Score final = +0 a +5 puntos si coherencia >80%
```

### Testing

```bash
# Verificar compilación
flutter pub get
flutter analyze

# Ejecutar tests (requieren setup)
flutter test test/orchestrator_test.dart
```

### Logging en Debug

```
✅ SPEC-34: Orquestrador actualizado. Coherencia: 85.5%
⚠️  Violaciones detectadas:
- Riesgo deshidratación en Autofagia: bebiste 1500mL (objetivo 2200mL)
- Recovery bajo: 35%. Recomendado dormir 22:00-06:00.
```

### Pendiente para v1.0 (Out of Scope)

- ML-based predicción de "óptimo para entrenar en X minutos"
- Persistencia de estado en Firestore para análisis offline
- Integración con wearables para validación en vivo
- Notificaciones proactivas (SPEC-42 futuro)

## Notas de Arquitectura

- **Pattern**: Global Provider (evita ciclos de dependencia)
- **Sincronización**: Automática vía Riverpod listeners
- **Performance**: Solo recalcula cuando pilares cambian (lazy evaluation)
- **Escalabilidad**: Fácil agregar nuevos pilares (solo modificar calculateState)

---

**Próxima Tarea**: Integrar orchestratorProvider en los notifiers existentes (nutrition, exercise, fasting, sleep)
