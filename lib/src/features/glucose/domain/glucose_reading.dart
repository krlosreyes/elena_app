// Módulo "Tu Glucosa" (propuesta 2026-07-23, ver
// documentacion/propuestas/Propuesta_Protocolo_Glucosa_2026-07-23.docx
// §9.1): registro individual de una medición de glucosa capilar.
//
// Clase plana (sin @freezed / json_serializable) — mismo criterio ya
// documentado en exercise/domain/exercise_profile.dart: este entorno no
// tiene toolchain de codegen (build_runner) disponible de forma segura,
// así que se sigue el patrón de clases inmutables con copyWith/toMap/
// fromMap manuales que ya usan ExerciseProfile, StreakEntry, SleepLog y
// NutritionLog. Es una decisión de infraestructura, no de dominio — el
// checklist de calidad pedía Freezed, pero aplicarlo aquí rompería la
// consistencia del resto del código y requeriría generar código que
// este sandbox no puede compilar. Documentado explícitamente en el
// informe final de implementación.

/// Momento del día/relación con la comida en que se tomó la medición.
/// El mismo valor numérico de glucosa significa cosas clínicamente
/// distintas según el contexto (ADA: <100 mg/dL en ayunas es normal,
/// <180 mg/dL a las 2h postprandiales es la meta) — sin este campo el
/// dato no es interpretable. Ver propuesta §2.3 y §9.1.
enum GlucoseReadingContext {
  ayunas,
  antesDeComer,
  postprandial1h,
  postprandial2h,
  antesDeDormir,
  otro,
}

extension GlucoseReadingContextLabel on GlucoseReadingContext {
  String get label {
    switch (this) {
      case GlucoseReadingContext.ayunas:
        return 'En ayunas';
      case GlucoseReadingContext.antesDeComer:
        return 'Antes de comer';
      case GlucoseReadingContext.postprandial1h:
        return '1 hora después de comer';
      case GlucoseReadingContext.postprandial2h:
        return '2 horas después de comer';
      case GlucoseReadingContext.antesDeDormir:
        return 'Antes de dormir';
      case GlucoseReadingContext.otro:
        return 'Otro momento';
    }
  }

  bool get isPostprandial =>
      this == GlucoseReadingContext.postprandial1h ||
      this == GlucoseReadingContext.postprandial2h;
}

/// Síntomas asociados a la medición — mismo vocabulario ya establecido
/// en la app (fasting_consciousness_card.dart, adaptive_engine.dart):
/// "mareo, temblor o palpitaciones" como señal de alarma dura (Frank
/// Suárez, preguntaleafrank.com). Se agrega "sudoración" (síntoma
/// clásico de hipoglucemia en la literatura clínica) para completar el
/// set sin inventar un vocabulario nuevo de diagnóstico.
enum GlucoseSymptom { mareo, temblor, sudoracion, palpitaciones, ninguno }

extension GlucoseSymptomLabel on GlucoseSymptom {
  String get label {
    switch (this) {
      case GlucoseSymptom.mareo:
        return 'Mareo';
      case GlucoseSymptom.temblor:
        return 'Temblor';
      case GlucoseSymptom.sudoracion:
        return 'Sudoración';
      case GlucoseSymptom.palpitaciones:
        return 'Palpitaciones';
      case GlucoseSymptom.ninguno:
        return 'Ninguno';
    }
  }
}

/// Origen del dato. MVP (propuesta §15) es 100% manual — no hay
/// integración con glucómetro Bluetooth ni HealthKit blood glucose
/// todavía (Roadmap V2/V3).
enum GlucoseSource { manual }

/// Rango de validación de entrada: límites fisiológicos plausibles de
/// un glucómetro doméstico (propuesta §9.1). Fuera de este rango se
/// pide confirmación explícita antes de guardar (regla de negocio R9).
const int kGlucoseMinPlausibleMgDl = 40;
const int kGlucoseMaxPlausibleMgDl = 400;

class GlucoseReading {
  final String id;
  final String userId;
  final int valueMgDl;
  final GlucoseReadingContext context;
  final DateTime measuredAt;

  /// Solo relevante cuando [context] es postprandial — minutos desde el
  /// inicio de la última comida (propuesta §2.3: el pico real ocurre en
  /// promedio ~75 min, con amplia variación interindividual).
  final int? minutesSinceLastMeal;

  /// Solo relevante cuando [context] == ayunas — minutos desde que el
  /// usuario se despertó, para validar que la medición ocurrió
  /// realmente al despertar y no a media mañana.
  final int? minutesSinceWaking;

  /// Horas de ayuno acumuladas al momento de la medición — insumo
  /// directo de GlucoseInsightEngine (correlato ayuno↔glucosa). Se
  /// captura en el momento de guardar la lectura (snapshot del estado
  /// real de `fastingProvider` en ese instante), no se reconstruye
  /// después — más preciso y evita tener que re-consultar el historial
  /// de ayuno de otras features para armar insights.
  final double? relatedFastingHours;

  /// Horas de sueño de la noche/ciclo previo, capturadas en el mismo
  /// snapshot que [relatedFastingHours] — insumo del correlato
  /// sueño↔glucosa.
  final double? relatedSleepHours;

  /// Meta de sueño del usuario al momento de la medición (para "sueño
  /// corto" relativo a SU meta, no un umbral fijo — mismo criterio que
  /// `effectiveSleepGoalProvider` ya usa en el resto de la app).
  final double? relatedSleepGoalHours;

  /// Índice glucémico estimado (0-100) de la última comida registrada
  /// — solo relevante para lecturas postprandiales. Mismo campo que
  /// `NutritionLog.glycemicIndex` (SPEC-64), copiado al momento de
  /// guardar para que el motor de análisis no dependa de re-consultar
  /// nutrition_log.
  final int? mealGlycemicIndex;

  final List<GlucoseSymptom> symptomsReported;
  final String note;
  final GlucoseSource source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GlucoseReading({
    required this.id,
    required this.userId,
    required this.valueMgDl,
    required this.context,
    required this.measuredAt,
    this.minutesSinceLastMeal,
    this.minutesSinceWaking,
    this.relatedFastingHours,
    this.relatedSleepHours,
    this.relatedSleepGoalHours,
    this.mealGlycemicIndex,
    required this.symptomsReported,
    this.note = '',
    this.source = GlucoseSource.manual,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasSymptoms =>
      symptomsReported.isNotEmpty &&
      !(symptomsReported.length == 1 &&
          symptomsReported.first == GlucoseSymptom.ninguno);

  bool get isPlausible =>
      valueMgDl >= kGlucoseMinPlausibleMgDl &&
      valueMgDl <= kGlucoseMaxPlausibleMgDl;

  GlucoseReading copyWith({
    String? id,
    String? userId,
    int? valueMgDl,
    GlucoseReadingContext? context,
    DateTime? measuredAt,
    int? minutesSinceLastMeal,
    int? minutesSinceWaking,
    double? relatedFastingHours,
    double? relatedSleepHours,
    double? relatedSleepGoalHours,
    int? mealGlycemicIndex,
    List<GlucoseSymptom>? symptomsReported,
    String? note,
    GlucoseSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlucoseReading(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      valueMgDl: valueMgDl ?? this.valueMgDl,
      context: context ?? this.context,
      measuredAt: measuredAt ?? this.measuredAt,
      minutesSinceLastMeal: minutesSinceLastMeal ?? this.minutesSinceLastMeal,
      minutesSinceWaking: minutesSinceWaking ?? this.minutesSinceWaking,
      relatedFastingHours: relatedFastingHours ?? this.relatedFastingHours,
      relatedSleepHours: relatedSleepHours ?? this.relatedSleepHours,
      relatedSleepGoalHours:
          relatedSleepGoalHours ?? this.relatedSleepGoalHours,
      mealGlycemicIndex: mealGlycemicIndex ?? this.mealGlycemicIndex,
      symptomsReported: symptomsReported ?? this.symptomsReported,
      note: note ?? this.note,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'valueMgDl': valueMgDl,
        'context': context.name,
        'measuredAt': measuredAt.toIso8601String(),
        'minutesSinceLastMeal': minutesSinceLastMeal,
        'minutesSinceWaking': minutesSinceWaking,
        'relatedFastingHours': relatedFastingHours,
        'relatedSleepHours': relatedSleepHours,
        'relatedSleepGoalHours': relatedSleepGoalHours,
        'mealGlycemicIndex': mealGlycemicIndex,
        'symptomsReported': symptomsReported.map((e) => e.name).toList(),
        'note': note,
        'source': source.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GlucoseReading.fromMap(String id, Map<String, dynamic> map) {
    return GlucoseReading(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      valueMgDl: (map['valueMgDl'] as num?)?.toInt() ?? 0,
      context: _enumFromName(
        GlucoseReadingContext.values,
        map['context'] as String?,
        GlucoseReadingContext.otro,
      ),
      measuredAt: DateTime.tryParse(map['measuredAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      minutesSinceLastMeal: (map['minutesSinceLastMeal'] as num?)?.toInt(),
      minutesSinceWaking: (map['minutesSinceWaking'] as num?)?.toInt(),
      relatedFastingHours: (map['relatedFastingHours'] as num?)?.toDouble(),
      relatedSleepHours: (map['relatedSleepHours'] as num?)?.toDouble(),
      relatedSleepGoalHours:
          (map['relatedSleepGoalHours'] as num?)?.toDouble(),
      mealGlycemicIndex: (map['mealGlycemicIndex'] as num?)?.toInt(),
      symptomsReported: ((map['symptomsReported'] as List?) ?? const [])
          .map((e) => _enumFromName(
                GlucoseSymptom.values,
                e as String?,
                GlucoseSymptom.ninguno,
              ))
          .toList(),
      note: (map['note'] as String?) ?? '',
      source: _enumFromName(
        GlucoseSource.values,
        map['source'] as String?,
        GlucoseSource.manual,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
