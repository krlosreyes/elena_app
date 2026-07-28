// Módulo "Tu Glucosa" — motor de análisis (propuesta §10, alcance MVP
// según Roadmap §15: "3 correlatos básicos (ayuno, sueño, última
// comida)"; los correlatos de ejercicio/fuerza/hidratación/composición
// corporal quedan documentados como V2 en la propuesta y NO se
// implementan acá — implementarlos con datos insuficientes sería
// exactamente el "generar falsas personalizaciones" que el documento
// prohíbe explícitamente en su sección de Riesgos).
//
// Diseño Clean Architecture: `GlucoseInsightEngine` es una clase PURA
// (sin Flutter/Riverpod/Firestore) que recibe estructuras simples ya
// agregadas por día (`GlucoseDailyContext`) — no importa domain types
// de fasting/sleep/nutrition directamente. Mismo patrón que
// `StreakEngine` (domain, puro, recibe primitivos) vs. `StreakNotifier`
// (application, hace el cruce entre features y le pasa primitivos al
// engine). Quien arma `GlucoseDailyContext` es `GlucoseNotifier`
// (application layer), leyendo los providers de los otros pilares con
// `.select()` — así el dominio de glucosa no se acopla a los dominios
// internos de otras 4 features.
//
// Regla de negocio R8 (mínimo de datos): ninguna correlación se genera
// con menos de 7 días de superposición; con 7-13 se marca "tendencia
// preliminar"; con 14+ es el patrón principal. Nunca se inventa un
// insight con menos de 7 — el motor debe decir honestamente que no hay
// suficientes datos (propuesta, sección "Motor de análisis inteligente"
// y "Riesgos y limitaciones").

enum GlucoseInsightType {
  ayunoVsGlucosaAyunas,
  suenoVsGlucosaAyunas,
  comidaVsGlucosaPostprandial,
}

/// Clasificación estándar de índice glucémico (bajo ≤55, medio 56-69,
/// alto ≥70) — usada solo por `_analyzeMealVsPostprandialGlucose` para
/// agrupar lecturas, no para clasificar la lectura de glucosa en sí
/// (eso lo hace `GlucoseClassifier`).
class _GlycemicIndexBand {
  static const int lowMax = 55;
  static const int highMin = 70;
}

enum GlucoseEvidenceLevel { solida, moderada }

enum GlucoseInsightConfidence { preliminar, establecido }

/// Contexto agregado de UN día, ya cruzado por `GlucoseNotifier` desde
/// los providers de los otros pilares. Todo nullable: si un pilar no
/// tiene dato ese día, ese correlato simplemente no cuenta ese día
/// (no se rellena con un valor inventado).
class GlucoseDailyContext {
  final DateTime date;

  /// Horas de ayuno completadas ese "día metabólico" (desde
  /// fastingProvider/streak — mismo dato que ya usa el resto de la
  /// app).
  final double? fastingHoursCompleted;

  /// Horas de sueño de la noche previa a ese día (desde sleep_log).
  final double? sleepHours;

  /// Meta de sueño del usuario (para "sueño corto" relativo, no un
  /// umbral fijo — coherente con `effectiveSleepGoalProvider` que ya
  /// usa el resto de la app).
  final double? sleepGoalHours;

  const GlucoseDailyContext({
    required this.date,
    this.fastingHoursCompleted,
    this.sleepHours,
    this.sleepGoalHours,
  });
}

/// Un insight generado por el motor. Siempre incluye el mecanismo y su
/// nivel de evidencia — nunca se presenta una correlación desnuda sin
/// explicar el "por qué" (propuesta §10.2).
class GlucoseInsight {
  final GlucoseInsightType type;
  final GlucoseInsightConfidence confidence;
  final GlucoseEvidenceLevel evidenceLevel;

  /// "Qué está ocurriendo" — el hecho observado en los datos reales del
  /// usuario (nunca una afirmación poblacional genérica).
  final String observation;

  /// "Por qué ocurre" — el mecanismo fisiológico conocido.
  final String mechanism;

  /// "Qué acción concreta tomar" — una sola sugerencia, nunca una lista.
  final String action;

  final int sampleSize;

  const GlucoseInsight({
    required this.type,
    required this.confidence,
    required this.evidenceLevel,
    required this.observation,
    required this.mechanism,
    required this.action,
    required this.sampleSize,
  });
}

/// Registro simplificado de una lectura + su contexto de día, listo
/// para que el engine calcule promedios por grupo. `GlucoseNotifier`
/// arma esta lista cruzando `GlucoseReading` con `GlucoseDailyContext`
/// por fecha.
class GlucoseReadingWithContext {
  final int valueMgDl;
  final bool isFastingContext;
  final bool isPostprandialContext;
  final GlucoseDailyContext dayContext;

  /// Índice glucémico estimado (0-100) de la comida asociada a esta
  /// lectura postprandial — mismo campo `glycemicIndex` que
  /// `NutritionLog` ya captura (SPEC-64). Null si no se pudo asociar
  /// una comida (ej. contexto no postprandial, o el usuario no declaró
  /// el índice glucémico de esa comida).
  final int? mealGlycemicIndex;

  const GlucoseReadingWithContext({
    required this.valueMgDl,
    required this.isFastingContext,
    this.isPostprandialContext = false,
    this.mealGlycemicIndex,
    required this.dayContext,
  });
}

class GlucoseInsightEngine {
  GlucoseInsightEngine._();

  /// R8: mínimo de días superpuestos para generar CUALQUIER insight.
  static const int kMinOverlapDays = 7;

  /// R8: a partir de acá, el insight se presenta como "patrón
  /// principal" en vez de "tendencia preliminar".
  static const int kEstablishedOverlapDays = 14;

  /// Umbral (horas) para considerar un ayuno "completado" a efectos de
  /// este correlato — 12h es un punto medio conservador entre
  /// protocolos cortos (12:12) y largos, documentado en el propio
  /// `fasting_status.dart` (postAbsorption termina ~12h).
  static const double kFastingCompletedThresholdHours = 12.0;

  /// Genera todos los insights posibles con los datos disponibles.
  /// Nunca lanza una excepción por datos insuficientes — simplemente
  /// omite el insight y deja que la UI muestre el estado "todavía no
  /// tenemos suficientes datos" (propuesta §13).
  static List<GlucoseInsight> analyze(
    List<GlucoseReadingWithContext> entries,
  ) {
    final insights = <GlucoseInsight>[];

    final fastingInsight = _analyzeFastingVsGlucose(entries);
    if (fastingInsight != null) insights.add(fastingInsight);

    final sleepInsight = _analyzeSleepVsGlucose(entries);
    if (sleepInsight != null) insights.add(sleepInsight);

    final mealInsight = _analyzeMealVsPostprandialGlucose(entries);
    if (mealInsight != null) insights.add(mealInsight);

    return insights;
  }

  /// Correlato 1 (propuesta §10.1): ayuno ↔ glucosa en ayunas. Compara
  /// el promedio de glucosa en-ayunas de días con ayuno completado
  /// (≥ kFastingCompletedThresholdHours) vs. días con ayuno corto o
  /// interrumpido.
  static GlucoseInsight? _analyzeFastingVsGlucose(
    List<GlucoseReadingWithContext> entries,
  ) {
    final fastingReadings = entries.where((e) =>
        e.isFastingContext && e.dayContext.fastingHoursCompleted != null);

    final withLongFast = fastingReadings
        .where((e) =>
            e.dayContext.fastingHoursCompleted! >=
            kFastingCompletedThresholdHours)
        .map((e) => e.valueMgDl)
        .toList();
    final withShortFast = fastingReadings
        .where((e) =>
            e.dayContext.fastingHoursCompleted! <
            kFastingCompletedThresholdHours)
        .map((e) => e.valueMgDl)
        .toList();

    final totalDays = withLongFast.length + withShortFast.length;
    if (totalDays < kMinOverlapDays ||
        withLongFast.isEmpty ||
        withShortFast.isEmpty) {
      return null;
    }

    final avgLong = _average(withLongFast);
    final avgShort = _average(withShortFast);
    final diff = avgShort - avgLong;

    // Solo se reporta si la diferencia es en la dirección esperada por
    // el mecanismo conocido (ayuno más largo → glucosa más baja) y no
    // es un ruido despreciable (<3 mg/dL no se reporta — bajo el
    // margen de error del propio glucómetro doméstico, propuesta §2.8).
    if (diff < 3) return null;

    return GlucoseInsight(
      type: GlucoseInsightType.ayunoVsGlucosaAyunas,
      confidence: totalDays >= kEstablishedOverlapDays
          ? GlucoseInsightConfidence.establecido
          : GlucoseInsightConfidence.preliminar,
      evidenceLevel: GlucoseEvidenceLevel.solida,
      observation: 'En tus últimos $totalDays días con dato, tu glucosa en '
          'ayunas promedió ${avgLong.round()} mg/dL los días que completaste '
          '${kFastingCompletedThresholdHours.round()}+ horas de ayuno, contra '
          '${avgShort.round()} mg/dL los días de ayuno más corto.',
      mechanism: 'El ayuno reduce la insulina circulante y activa la '
          'gluconeogénesis hepática controlada — con el tiempo, eso tiende '
          'a bajar la glucosa basal en ayunas.',
      action: 'Sostener tu ventana de ayuno habitual parece estar '
          'ayudando a tu glucosa en ayunas — vale la pena seguir así.',
      sampleSize: totalDays,
    );
  }

  /// Correlato 2 (propuesta §10.1): sueño ↔ glucosa en ayunas. Compara
  /// noches de sueño corto (< meta declarada) contra la glucosa en
  /// ayunas de la mañana siguiente. Este es, según la propuesta §2.10,
  /// el correlato con mayor respaldo experimental de todos.
  static GlucoseInsight? _analyzeSleepVsGlucose(
    List<GlucoseReadingWithContext> entries,
  ) {
    final withSleepData = entries.where((e) =>
        e.isFastingContext &&
        e.dayContext.sleepHours != null &&
        e.dayContext.sleepGoalHours != null &&
        e.dayContext.sleepGoalHours! > 0);

    final shortSleep = <int>[];
    final adequateSleep = <int>[];
    for (final e in withSleepData) {
      if (e.dayContext.sleepHours! < e.dayContext.sleepGoalHours!) {
        shortSleep.add(e.valueMgDl);
      } else {
        adequateSleep.add(e.valueMgDl);
      }
    }

    final totalDays = shortSleep.length + adequateSleep.length;
    if (totalDays < kMinOverlapDays ||
        shortSleep.isEmpty ||
        adequateSleep.isEmpty) {
      return null;
    }

    final avgShort = _average(shortSleep);
    final avgAdequate = _average(adequateSleep);
    final diff = avgShort - avgAdequate;

    if (diff < 3) return null;

    return GlucoseInsight(
      type: GlucoseInsightType.suenoVsGlucosaAyunas,
      confidence: totalDays >= kEstablishedOverlapDays
          ? GlucoseInsightConfidence.establecido
          : GlucoseInsightConfidence.preliminar,
      evidenceLevel: GlucoseEvidenceLevel.solida,
      observation: 'Las noches que dormiste menos de tu meta, tu glucosa en '
          'ayunas de la mañana siguiente promedió ${diff.round()} mg/dL más '
          'alta que tras tus noches con sueño suficiente ($totalDays días '
          'con dato).',
      mechanism: 'La privación de sueño, incluso parcial y de una sola '
          'noche, reduce la sensibilidad a la insulina de forma medible — '
          'uno de los hallazgos más consistentes en investigación '
          'metabólica.',
      action: 'Priorizar dormir tu meta de horas esta noche puede ayudar '
          'más a tu glucosa de mañana que cualquier ajuste en la comida.',
      sampleSize: totalDays,
    );
  }

  /// Correlato 3 (propuesta §10.1 y ejemplo de §13): comida ↔ glucosa
  /// postprandial. Compara el promedio de lecturas postprandiales
  /// asociadas a comidas de índice glucémico alto (≥70) contra las
  /// asociadas a comidas de índice glucémico bajo (≤55).
  ///
  /// Nota de adaptación (documentada, no silenciosa — ver informe de
  /// implementación): R8 define el mínimo de datos en "días de
  /// superposición", pensado para correlatos de un dato por día
  /// (ayuno, sueño). Este correlato es por COMIDA, no por día — un
  /// mismo día puede tener 2-3 lecturas postprandiales de comidas
  /// distintas. Se aplica el mismo umbral numérico (7) pero contando
  /// LECTURAS en vez de días, que es la unidad natural de este
  /// correlato y sigue siendo un mínimo conservador.
  static GlucoseInsight? _analyzeMealVsPostprandialGlucose(
    List<GlucoseReadingWithContext> entries,
  ) {
    final postprandial = entries
        .where((e) => e.isPostprandialContext && e.mealGlycemicIndex != null);

    final highGi = postprandial
        .where((e) => e.mealGlycemicIndex! >= _GlycemicIndexBand.highMin)
        .map((e) => e.valueMgDl)
        .toList();
    final lowGi = postprandial
        .where((e) => e.mealGlycemicIndex! <= _GlycemicIndexBand.lowMax)
        .map((e) => e.valueMgDl)
        .toList();

    final total = highGi.length + lowGi.length;
    if (total < kMinOverlapDays || highGi.isEmpty || lowGi.isEmpty) {
      return null;
    }

    final avgHigh = _average(highGi);
    final avgLow = _average(lowGi);
    final diff = avgHigh - avgLow;

    if (diff < 3) return null;

    return GlucoseInsight(
      type: GlucoseInsightType.comidaVsGlucosaPostprandial,
      confidence: total >= kEstablishedOverlapDays
          ? GlucoseInsightConfidence.establecido
          : GlucoseInsightConfidence.preliminar,
      evidenceLevel: GlucoseEvidenceLevel.solida,
      observation: 'Tus lecturas después de comidas de índice glucémico '
          'alto promediaron ${avgHigh.round()} mg/dL, contra '
          '${avgLow.round()} mg/dL después de comidas de índice glucémico '
          'bajo ($total lecturas con dato).',
      mechanism: 'La carga y el tipo de carbohidrato determinan en gran '
          'medida la magnitud del pico postprandial — la fibra y la '
          'proteína moderan la velocidad de absorción.',
      action: 'Priorizar comidas de menor índice glucémico (o agregar '
          'fibra/proteína antes del carbohidrato) parece suavizar tu pico '
          'después de comer.',
      sampleSize: total,
    );
  }

  static double _average(List<int> values) =>
      values.reduce((a, b) => a + b) / values.length;
}
