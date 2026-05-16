/// Registro de cumplimiento diario de los 5 pilares metabólicos.
///
/// Un día "cuenta" para la racha si [qualifiesForStreak] es true,
/// lo que requiere completar al menos 3 de los 5 pilares (umbral binario).
///
/// SPEC-65: añade magnitudes continuas por pilar — `qualifiesForStreak`
/// sigue siendo booleano, pero ahora `dailyQualityScore` ofrece una
/// medida ponderada [0.0, 1.0] que refleja cuán bien se cumplió cada
/// pilar (no solo si se cruzó el umbral). Esto habilita SPEC-53
/// (rebalanceo del IMR) y un futuro `EngagementScore` continuo.
///
/// Las magnitudes son nullable para preservar backward-compat con
/// entradas históricas que no las traen. `dailyQualityScore` degrada
/// graciosamente: si faltan magnitudes, renormaliza pesos sobre las
/// disponibles; si TODAS son null, cae a `pillarsCompleted / 5.0`.
///
/// No usa Freezed para evitar re-ejecución de build_runner.
/// La serialización manual es suficiente dado que el modelo es estable.
class StreakEntry {
  /// Fecha en formato 'yyyy-MM-dd' — clave primaria en Firestore.
  final String date;

  // ── Estado de cada pilar ese día (booleanos: cruzó el umbral) ──────────────

  /// Ayuno: ≥80% del protocolo configurado (o ≥10h si protocolo = 'Ninguno').
  final bool fastingCompleted;

  /// Sueño: ≥6.5 horas de sueño efectivo registrado.
  final bool sleepCompleted;

  /// Hidratación: ≥75% de la meta diaria alcanzada.
  final bool hydrationCompleted;

  /// Ejercicio: ≥20 minutos registrados (dosis mínima ACSM).
  final bool exerciseLogged;

  /// Nutrición: ≥1 comida dentro de la ventana circadiana.
  final bool nutritionLogged;

  /// Score IMR del día al momento de evaluar el cumplimiento.
  final int imrScore;

  // ── SPEC-65: magnitudes continuas por pilar ────────────────────────────────

  /// Magnitud de ayuno: `fastingHours / targetHours`. Range típico [0, ~1.5+].
  /// `null` si la entrada es histórica (pre-SPEC-65) o no se midió.
  final double? fastingMagnitude;

  /// Calidad multidimensional de sueño (SPEC-69), ya en [0.0, 1.0].
  /// `null` si no hubo log o la entrada es pre-SPEC-65.
  final double? sleepQualityScore;

  /// Magnitud de hidratación: `currentLiters / dailyGoalLiters`. Sin clamp
  /// superior — premia el overachievement. `null` si no se midió.
  final double? hydrationMagnitude;

  /// Magnitud de ejercicio: `todayMinutes / 30.0` (la dosis mínima ACSM
  /// de 20 min queda en ~0.67, una sesión completa de 30 min en 1.0,
  /// sesiones largas pueden superar 1.0). `null` si no se midió.
  final double? exerciseMagnitude;

  /// Score nutricional del día (combina meal ratio + window adherence)
  /// en [0.0, 1.0]. `null` si la entrada es pre-SPEC-65.
  final double? nutritionMagnitude;

  const StreakEntry({
    required this.date,
    required this.fastingCompleted,
    required this.sleepCompleted,
    required this.hydrationCompleted,
    required this.exerciseLogged,
    required this.nutritionLogged,
    required this.imrScore,
    this.fastingMagnitude,
    this.sleepQualityScore,
    this.hydrationMagnitude,
    this.exerciseMagnitude,
    this.nutritionMagnitude,
  });

  // ── Computed ────────────────────────────────────────────────────────────────

  /// Pilares completados hoy (0-5).
  int get pillarsCompleted {
    int count = 0;
    if (fastingCompleted) count++;
    if (sleepCompleted) count++;
    if (hydrationCompleted) count++;
    if (exerciseLogged) count++;
    if (nutritionLogged) count++;
    return count;
  }

  /// True si el día cuenta para la racha: mínimo 3 de 5 pilares completados.
  bool get qualifiesForStreak => pillarsCompleted >= 3;

  /// True si el día cumple con el estándar de Engagement (SPEC-07):
  /// IMR >= 60 Y mínimo 3 pilares completados.
  bool get isEngaged => imrScore >= 60 && qualifiesForStreak;

  /// SPEC-65: score continuo de calidad del día [0.0, 1.0].
  ///
  /// Pondera las magnitudes disponibles. Si todas están `null`, cae a
  /// `pillarsCompleted / 5.0` (señal binaria pura — comportamiento previo).
  ///
  /// Pesos por pilar (suman 1.0). SPEC-70: ref IMR_BIBLIOGRAPHY.md §6.
  /// - Sueño 0.25 — §6.1 MEDIUM (mayor evidencia + efectos sistémicos).
  /// - Ayuno/Ejercicio/Hidratación 0.20 — §6.2 ENGINEERING JUDGMENT
  ///   (co-iguales por dosis-respuesta comparable).
  /// - Nutrición 0.15 — §6.3 ENGINEERING JUDGMENT (conservador hasta
  ///   que macros de SPEC-64 entren al cómputo).
  double get dailyQualityScore {
    const wFasting = 0.20;
    const wSleep = 0.25;
    const wHydration = 0.20;
    const wExercise = 0.20;
    const wNutrition = 0.15;

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    if (fastingMagnitude != null) {
      weightedSum += wFasting * fastingMagnitude!.clamp(0.0, 1.0);
      totalWeight += wFasting;
    }
    if (sleepQualityScore != null) {
      weightedSum += wSleep * sleepQualityScore!.clamp(0.0, 1.0);
      totalWeight += wSleep;
    }
    if (hydrationMagnitude != null) {
      weightedSum += wHydration * hydrationMagnitude!.clamp(0.0, 1.0);
      totalWeight += wHydration;
    }
    if (exerciseMagnitude != null) {
      weightedSum += wExercise * exerciseMagnitude!.clamp(0.0, 1.0);
      totalWeight += wExercise;
    }
    if (nutritionMagnitude != null) {
      weightedSum += wNutrition * nutritionMagnitude!.clamp(0.0, 1.0);
      totalWeight += wNutrition;
    }

    // Si NINGUNA magnitud está presente (entrada legacy), caer al
    // fallback binario para que la métrica siga siendo significativa.
    if (totalWeight == 0.0) {
      return pillarsCompleted / 5.0;
    }
    return (weightedSum / totalWeight).clamp(0.0, 1.0);
  }

  /// True si la entrada porta al menos una magnitud continua (SPEC-65+).
  /// Útil para distinguir entradas legacy de las modernas en analytics.
  bool get hasMagnitudes =>
      fastingMagnitude != null ||
      sleepQualityScore != null ||
      hydrationMagnitude != null ||
      exerciseMagnitude != null ||
      nutritionMagnitude != null;

  // ── Serialización Firestore ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'date': date,
      'fastingCompleted': fastingCompleted,
      'sleepCompleted': sleepCompleted,
      'hydrationCompleted': hydrationCompleted,
      'exerciseLogged': exerciseLogged,
      'nutritionLogged': nutritionLogged,
      'imrScore': imrScore,
    };
    // SPEC-65: omitir magnitudes nulas para no escribir basura a Firestore.
    if (fastingMagnitude != null) m['fastingMagnitude'] = fastingMagnitude;
    if (sleepQualityScore != null) m['sleepQualityScore'] = sleepQualityScore;
    if (hydrationMagnitude != null) {
      m['hydrationMagnitude'] = hydrationMagnitude;
    }
    if (exerciseMagnitude != null) m['exerciseMagnitude'] = exerciseMagnitude;
    if (nutritionMagnitude != null) {
      m['nutritionMagnitude'] = nutritionMagnitude;
    }
    return m;
  }

  factory StreakEntry.fromJson(Map<String, dynamic> json) => StreakEntry(
        date: json['date'] as String? ?? '',
        fastingCompleted: json['fastingCompleted'] as bool? ?? false,
        sleepCompleted: json['sleepCompleted'] as bool? ?? false,
        hydrationCompleted: json['hydrationCompleted'] as bool? ?? false,
        exerciseLogged: json['exerciseLogged'] as bool? ?? false,
        nutritionLogged: json['nutritionLogged'] as bool? ?? false,
        imrScore: (json['imrScore'] as num?)?.toInt() ?? 0,
        fastingMagnitude: (json['fastingMagnitude'] as num?)?.toDouble(),
        sleepQualityScore: (json['sleepQualityScore'] as num?)?.toDouble(),
        hydrationMagnitude: (json['hydrationMagnitude'] as num?)?.toDouble(),
        exerciseMagnitude: (json['exerciseMagnitude'] as num?)?.toDouble(),
        nutritionMagnitude: (json['nutritionMagnitude'] as num?)?.toDouble(),
      );

  /// Crea una copia modificando solo los campos especificados.
  ///
  /// Nota: para "borrar" una magnitud (volverla null), pasar
  /// explícitamente `fooMagnitude: null` no funciona con la firma
  /// `double? param` porque Dart no distingue "no provisto" de "null".
  /// Como las magnitudes son monótonamente añadidas en producción,
  /// no necesitamos esa distinción por ahora.
  StreakEntry copyWith({
    String? date,
    bool? fastingCompleted,
    bool? sleepCompleted,
    bool? hydrationCompleted,
    bool? exerciseLogged,
    bool? nutritionLogged,
    int? imrScore,
    double? fastingMagnitude,
    double? sleepQualityScore,
    double? hydrationMagnitude,
    double? exerciseMagnitude,
    double? nutritionMagnitude,
  }) =>
      StreakEntry(
        date: date ?? this.date,
        fastingCompleted: fastingCompleted ?? this.fastingCompleted,
        sleepCompleted: sleepCompleted ?? this.sleepCompleted,
        hydrationCompleted: hydrationCompleted ?? this.hydrationCompleted,
        exerciseLogged: exerciseLogged ?? this.exerciseLogged,
        nutritionLogged: nutritionLogged ?? this.nutritionLogged,
        imrScore: imrScore ?? this.imrScore,
        fastingMagnitude: fastingMagnitude ?? this.fastingMagnitude,
        sleepQualityScore: sleepQualityScore ?? this.sleepQualityScore,
        hydrationMagnitude: hydrationMagnitude ?? this.hydrationMagnitude,
        exerciseMagnitude: exerciseMagnitude ?? this.exerciseMagnitude,
        nutritionMagnitude: nutritionMagnitude ?? this.nutritionMagnitude,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakEntry &&
          date == other.date &&
          fastingCompleted == other.fastingCompleted &&
          sleepCompleted == other.sleepCompleted &&
          hydrationCompleted == other.hydrationCompleted &&
          exerciseLogged == other.exerciseLogged &&
          nutritionLogged == other.nutritionLogged &&
          imrScore == other.imrScore &&
          fastingMagnitude == other.fastingMagnitude &&
          sleepQualityScore == other.sleepQualityScore &&
          hydrationMagnitude == other.hydrationMagnitude &&
          exerciseMagnitude == other.exerciseMagnitude &&
          nutritionMagnitude == other.nutritionMagnitude;

  @override
  int get hashCode => date.hashCode;
}
