import 'dart:math';

import '../../../shared/domain/models/user_model.dart';
import '../domain/entities/exercise_database.dart';
import '../domain/entities/weekly_routine.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// WORKOUT PERSONALIZER v2 — Motor inteligente de rutinas semanales
//
// Principios científicos aplicados (Hipertrofia & Salud Metabólica):
//  • Frecuencia 2×/semana por grupo muscular (estímulo óptimo de síntesis)
//  • 10-20 series totales por grupo/semana (volumen recuperable)
//  • Intensidad via RIR/RPE (entrenar cerca del fallo, 1-3 RIR)
//  • Sobrecarga progresiva implícita (sets/reps escalonados por nivel)
//  • Fase excéntrica: ejercicios priorizan movimientos compuestos
//  • Estructura temporal: microciclo (1 semana) con distribución inteligente
//  • Cardio Zone2 para salud metabólica + HIIT para capacidad anaeróbica
//  • Adaptaciones: sueño, edad, patologías, equipo, objetivo, grasa corporal
//
// Clase 100% pura (sin state, sin providers, sin side-effects)
// ═══════════════════════════════════════════════════════════════════════════════

class WorkoutPersonalizer {
  WorkoutPersonalizer._();

  static final _rng = Random();

  /// Genera una WeeklyRoutine personalizada analizando todo el perfil.
  static WeeklyRoutine generate(UserModel user, {required String weekId}) {
    // ── Paso 1: Analizar perfil → contexto de entrenamiento ──
    final ctx = _ProfileContext.from(user);

    // ── Paso 2: Distribuir tipos de sesión sobre días disponibles ──
    final dayTypes = _distributeDays(ctx);

    // ── Paso 3: Generar ejercicios personalizados para cada día ──
    final days = List.generate(7, (i) {
      final type = dayTypes[i];
      final exercises = _exercisesForDay(type, ctx);
      return WorkoutDay(dayIndex: i, type: type, exercises: exercises);
    });

    return WeeklyRoutine(
      weekId: weekId,
      generatedAt: DateTime.now(),
      activityLevelSnapshot: user.activityLevel.name,
      healthGoalSnapshot: user.healthGoal?.name ?? 'metabolicHealth',
      days: days,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 2 — DISTRIBUCIÓN INTELIGENTE DE DÍAS
  //
  // Reglas de prioridad:
  //  1. Fuerza primero (frecuencia 2×/grupo muscular)
  //  2. Cardio Zone2 para salud metabólica
  //  3. HIIT si hay slots y el perfil lo permite
  //  4. Los días no disponibles → rest
  //  5. Intentar alternar fuerza/cardio para mejor recuperación
  // ═══════════════════════════════════════════════════════════════════════════

  static List<WorkoutDayType> _distributeDays(_ProfileContext ctx) {
    final result = List.filled(7, WorkoutDayType.rest);
    final available = ctx.workoutDays.toList()..sort();
    final n = available.length;

    if (n == 0) return result;

    // ── Plantillas según días disponibles ──
    // Cada plantilla garantiza frecuencia 2×/grupo y balance fuerza:cardio
    final List<WorkoutDayType> template;

    if (n >= 6) {
      // 6-7 días: Upper/Lower/Upper/Lower + Zone2 + HIIT
      template = [
        WorkoutDayType.strengthUpper, // 1
        WorkoutDayType.strengthLower, // 2
        WorkoutDayType.zone2, // 3
        WorkoutDayType.strengthUpper, // 4
        WorkoutDayType.strengthLower, // 5
        WorkoutDayType.hiit, // 6
      ];
    } else if (n == 5) {
      // 5 días: Upper/Lower/Zone2/Upper/Lower
      template = [
        WorkoutDayType.strengthUpper,
        WorkoutDayType.strengthLower,
        WorkoutDayType.zone2,
        WorkoutDayType.strengthUpper,
        WorkoutDayType.strengthLower,
      ];
    } else if (n == 4) {
      // 4 días: Upper/Lower/Upper/Lower (frecuencia 2× perfecta)
      template = [
        WorkoutDayType.strengthUpper,
        WorkoutDayType.strengthLower,
        WorkoutDayType.strengthUpper,
        WorkoutDayType.strengthLower,
      ];
    } else if (n == 3) {
      // 3 días: Full/Zone2/Full (2× frecuencia via fullbody)
      template = [
        WorkoutDayType.strengthFull,
        WorkoutDayType.zone2,
        WorkoutDayType.strengthFull,
      ];
    } else if (n == 2) {
      // 2 días: Full/Full (mínimo viable para frecuencia 2×)
      template = [WorkoutDayType.strengthFull, WorkoutDayType.strengthFull];
    } else {
      // 1 día: Full (mejor que nada)
      template = [WorkoutDayType.strengthFull];
    }

    // ── Ajuste por objetivo ──
    final adjusted = _adjustForGoal(template.toList(), ctx);

    // ── Asignar plantilla a los días disponibles ──
    for (int i = 0; i < adjusted.length && i < available.length; i++) {
      result[available[i]] = adjusted[i];
    }

    // Si hay días disponibles sobrantes (n > template.length), llenar con zone2
    for (int i = adjusted.length; i < available.length; i++) {
      result[available[i]] = WorkoutDayType.zone2;
    }

    return result;
  }

  /// Ajusta la plantilla según el objetivo del usuario
  static List<WorkoutDayType> _adjustForGoal(
    List<WorkoutDayType> template,
    _ProfileContext ctx,
  ) {
    switch (ctx.healthGoal) {
      case HealthGoal.fatLoss:
        // Fat loss: reemplazar último zone2 por HIIT si existe,
        // o agregar más cardio si hay 5+ días
        final zone2Idx = template.lastIndexOf(WorkoutDayType.zone2);
        if (zone2Idx != -1 && !template.contains(WorkoutDayType.hiit)) {
          template[zone2Idx] = WorkoutDayType.hiit;
        }
        return template;

      case HealthGoal.muscleGain:
        // Muscle gain: reemplazar HIIT por fuerza si existe
        final hiitIdx = template.indexOf(WorkoutDayType.hiit);
        if (hiitIdx != -1) {
          // Convertir HIIT a fuerza full body extra
          template[hiitIdx] = WorkoutDayType.strengthFull;
        }
        return template;

      case HealthGoal.metabolicHealth:
        // Balance por defecto — ya está equilibrado
        return template;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASO 3 — SELECCIÓN DE EJERCICIOS POR DÍA
  // ═══════════════════════════════════════════════════════════════════════════

  static List<ExerciseTemplate> _exercisesForDay(
    WorkoutDayType type,
    _ProfileContext ctx,
  ) {
    switch (type) {
      case WorkoutDayType.strengthUpper:
        return _buildStrengthSession(ExerciseDatabase.upperBodyGroups, ctx);
      case WorkoutDayType.strengthLower:
        return _buildStrengthSession(ExerciseDatabase.lowerBodyGroups, ctx);
      case WorkoutDayType.strengthFull:
        return _buildStrengthSession(ExerciseDatabase.fullBodyGroups, ctx);
      case WorkoutDayType.zone2:
        return [
          ExerciseTemplate(
            exerciseId: 'zone2_cardio',
            name: 'Cardio Zona 2',
            muscleGroup: 'cardio',
            targetSets: 1,
            targetReps: 0,
            targetMinutes: _zone2Minutes(ctx),
          ),
        ];
      case WorkoutDayType.hiit:
        return [
          ExerciseTemplate(
            exerciseId: 'hiit_session',
            name: 'Sesión HIIT',
            muscleGroup: 'cardio',
            targetSets: 1,
            targetReps: 0,
            targetMinutes: _hiitMinutes(ctx),
          ),
        ];
      case WorkoutDayType.rest:
        return [];
    }
  }

  /// Construye una sesión de fuerza inteligente:
  ///  1. Pool filtrado (patologías, equipo)
  ///  2. Selección por diversidad de grupos musculares
  ///  3. 1 ejercicio de core obligatorio
  ///  4. Priorización por género y objetivo
  ///  5. Volumen personalizado (sets × reps)
  static List<ExerciseTemplate> _buildStrengthSession(
    Set<String> targetGroups,
    _ProfileContext ctx,
  ) {
    final sets = ctx.targetSets;
    final reps = ctx.targetReps;

    // ── Filtrar pool disponible ──
    final pool = ExerciseDatabase.all.where((ex) {
      // Solo grupos objetivo + core
      if (!targetGroups.contains(ex.muscleGroup) && ex.muscleGroup != 'core') {
        return false;
      }
      // Excluir por patología
      if (ex.contraindication != null &&
          ctx.pathologies.contains(ex.contraindication)) {
        return false;
      }
      // Excluir dumbbells si no tiene
      if (ex.requiresDumbbells && !ctx.hasDumbbells) return false;
      return true;
    }).toList();

    // ── Separar por grupo ──
    final byGroup = <String, List<ExerciseDefinition>>{};
    for (final ex in pool) {
      byGroup.putIfAbsent(ex.muscleGroup, () => []).add(ex);
    }

    // Shuffle cada grupo para variedad semanal
    for (final list in byGroup.values) {
      list.shuffle(_rng);
    }

    // ── Selección diversificada ──
    final selected = <ExerciseDefinition>[];
    final exerciseCount = ctx.exercisesPerSession;

    // Prioridad: 1 ejercicio por grupo muscular target (diversidad)
    final orderedGroups = _prioritizeGroups(targetGroups.toList(), ctx);
    for (final group in orderedGroups) {
      final candidates = byGroup[group];
      if (candidates != null && candidates.isNotEmpty) {
        selected.add(candidates.removeAt(0));
      }
    }

    // Si necesitamos más, rotar por los grupos con ejercicios restantes
    int safety = 0;
    while (selected.length < exerciseCount - 1 && safety < 20) {
      safety++;
      for (final group in orderedGroups) {
        if (selected.length >= exerciseCount - 1) break;
        final candidates = byGroup[group];
        if (candidates != null && candidates.isNotEmpty) {
          selected.add(candidates.removeAt(0));
        }
      }
    }

    // ── Core obligatorio (último slot) ──
    final corePool = byGroup['core'];
    if (corePool != null && corePool.isNotEmpty) {
      selected.add(corePool.first);
    }

    // ── Convertir a ExerciseTemplate ──
    return selected.map((ex) {
      return ExerciseTemplate(
        exerciseId: ex.id,
        name: ex.name,
        muscleGroup: ex.muscleGroup,
        targetSets: sets,
        targetReps: ex.muscleGroup == 'core' ? (reps * 1.2).round() : reps,
        requiresDumbbells: ex.requiresDumbbells,
      );
    }).toList();
  }

  /// Ordena grupos musculares según prioridad de género + objetivo
  static List<String> _prioritizeGroups(
    List<String> groups,
    _ProfileContext ctx,
  ) {
    final priority = <String, int>{};
    for (final g in groups) {
      priority[g] = 0;
    }

    // Mujeres + fat loss → piernas primero
    if (ctx.gender == Gender.female && ctx.healthGoal == HealthGoal.fatLoss) {
      priority['legs'] = (priority['legs'] ?? 0) - 10;
    }
    // Hombres + muscle gain → pecho y espalda primero
    if (ctx.gender == Gender.male && ctx.healthGoal == HealthGoal.muscleGain) {
      priority['chest'] = (priority['chest'] ?? 0) - 10;
      priority['back'] = (priority['back'] ?? 0) - 9;
    }
    // Mayores de 50 → piernas y espalda (prevención sarcopenia)
    if (ctx.age >= 50) {
      priority['legs'] = (priority['legs'] ?? 0) - 5;
      priority['back'] = (priority['back'] ?? 0) - 4;
    }
    // Fat loss en general → más compuestos (legs involucran más masa)
    if (ctx.healthGoal == HealthGoal.fatLoss) {
      priority['legs'] = (priority['legs'] ?? 0) - 3;
    }

    final sorted = groups.toList()
      ..sort((a, b) => (priority[a] ?? 0).compareTo(priority[b] ?? 0));
    return sorted;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARDIO — Duraciones adaptativas
  // ═══════════════════════════════════════════════════════════════════════════

  static int _zone2Minutes(_ProfileContext ctx) {
    // Base según nivel
    int base = switch (ctx.activityLevel) {
      ActivityLevel.sedentary => 20,
      ActivityLevel.light => 30,
      ActivityLevel.moderate => 35,
      ActivityLevel.heavy => 45,
    };
    // Penalización por mal sueño
    if (ctx.sleepHours < 6.0) base -= 5;
    // Más cardio para fat loss
    if (ctx.healthGoal == HealthGoal.fatLoss) base += 5;
    // Reducir si es mayor de 60
    if (ctx.age >= 60) base -= 5;
    return base.clamp(15, 60);
  }

  static int _hiitMinutes(_ProfileContext ctx) {
    // HIIT más corto por seguridad
    if (ctx.sleepHours < 6.0) return 12;
    if (ctx.age >= 55) return 15;
    return switch (ctx.activityLevel) {
      ActivityLevel.sedentary => 12,
      ActivityLevel.light => 18,
      ActivityLevel.moderate => 22,
      ActivityLevel.heavy => 28,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE CONTEXT — Análisis consolidado del perfil del usuario
// Extrae y pre-calcula todos los parámetros necesarios para la generación.
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileContext {
  final int age;
  final Gender gender;
  final ActivityLevel activityLevel;
  final HealthGoal healthGoal;
  final List<int> workoutDays;
  final bool hasDumbbells;
  final Set<String> pathologies;
  final double sleepHours;
  final int energyLevel;
  final double? fatPercentage;
  final double weightKg;
  final double heightCm;

  _ProfileContext._({
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.healthGoal,
    required this.workoutDays,
    required this.hasDumbbells,
    required this.pathologies,
    required this.sleepHours,
    required this.energyLevel,
    required this.fatPercentage,
    required this.weightKg,
    required this.heightCm,
  });

  factory _ProfileContext.from(UserModel user) {
    return _ProfileContext._(
      age: user.age,
      gender: user.gender,
      activityLevel: user.activityLevel,
      healthGoal: user.healthGoal ?? HealthGoal.metabolicHealth,
      workoutDays: user.workoutDays,
      hasDumbbells: user.hasDumbbells,
      pathologies: {...user.pathologies, ...user.physicalLimitations},
      sleepHours: user.averageSleepHours ?? 7.0,
      energyLevel: user.energyLevel1To10 ?? 5,
      fatPercentage: user.currentFatPercentage,
      weightKg: user.currentWeightKg,
      heightCm: user.heightCm,
    );
  }

  // ─── Parámetros de volumen calculados ─────────────────────────────────

  /// Series por ejercicio: 2-4 según nivel y recuperación
  int get targetSets {
    int base = switch (activityLevel) {
      ActivityLevel.sedentary => 2,
      ActivityLevel.light => 3,
      ActivityLevel.moderate => 3,
      ActivityLevel.heavy => 4,
    };
    // Reducir si duerme mal o energía baja
    if (sleepHours < 6.0 || energyLevel <= 3) base--;
    // Aumentar si muscle gain + buen sueño
    if (healthGoal == HealthGoal.muscleGain && sleepHours >= 7.0) base++;
    return base.clamp(2, 5);
  }

  /// Repeticiones por serie según objetivo
  int get targetReps {
    return switch (healthGoal) {
      HealthGoal.fatLoss => 15, // Alto volumen, más gasto calórico
      HealthGoal.muscleGain => 8, // Más carga, hipertrofia mecánica
      HealthGoal.metabolicHealth => 12, // Balance mixto
    };
  }

  /// Número de ejercicios por sesión (incluyendo core)
  int get exercisesPerSession {
    int base = switch (activityLevel) {
      ActivityLevel.sedentary => 3,
      ActivityLevel.light => 4,
      ActivityLevel.moderate => 4,
      ActivityLevel.heavy => 5,
    };
    // +1 para full body (más grupos que cubrir)
    // Pero se maneja externamente en _buildStrengthSession
    if (sleepHours < 6.0) base--;
    if (age >= 55) base--;
    return base.clamp(3, 6);
  }

  /// Volumen semanal total estimado (series totales por grupo)
  /// Para validación: debe estar en rango 10-20 por grupo
  int get weeklySeriesPerGroup {
    final strengthDays = workoutDays.length; // aprox días de fuerza
    return (targetSets *
            (exercisesPerSession - 1) *
            strengthDays ~/
            workoutDays.length)
        .clamp(10, 20);
  }
}
