// SPEC-15: Road Map de Avance Personal
// Snapshot biométrico periódico del usuario.
// Se registra manualmente desde BiometricCheckInSheet, automáticamente
// desde edits de Profile (SPEC-143), recálculo de %grasa (SPEC-92) y
// sync de HealthKit/Health Connect (SPEC-141.2 cuando SPEC-132 cierre).
// Almacenado en Firestore: users/{uid}/biometric_history/{yyyy-MM-dd}
// No usa Freezed para evitar build_runner.
//
// SPEC-143 extensions (campos opcionales, backward compat con docs
// legacy que no los traen):
//   - neckCircumference: completa el snapshot biométrico (SPEC-92).
//   - source: traza de qué punto del código creó la entrada.
//   - previousValues: audit ligero de qué cambió respecto a la
//     versión anterior (solo los campos que efectivamente se movieron).
//   - recordedAt: timestamp del momento exacto del cambio (más
//     granular que `createdAt`, que pre-SPEC-143 a veces era el
//     timestamp del check-in del usuario, no del save).

class BiometricCheckIn {
  /// Fecha en formato 'yyyy-MM-dd' — clave primaria en Firestore.
  final String date;

  /// ID del usuario propietario.
  final String userId;

  /// Peso en kg (obligatorio en cada check-in).
  final double weight;

  /// % de grasa corporal (opcional — puede no tener cinta métrica ese día).
  final double? bodyFatPercentage;

  /// Circunferencia de cintura en cm (opcional).
  final double? waistCircumference;

  /// SPEC-143: circunferencia de cuello en cm (opcional). Completa el
  /// snapshot biométrico que SPEC-92 calcula desde cintura + cuello + altura.
  /// Docs legacy sin este campo se leen como null.
  final double? neckCircumference;

  /// IMR del momento del check-in (snapshot automático del motor).
  final int? imrScore;

  /// Nota libre del usuario.
  final String? notes;

  /// Timestamp de creación.
  final DateTime createdAt;

  /// SPEC-143: fuente del cambio biométrico. Valores válidos en
  /// `BiometricSource.all`. Null para docs legacy.
  final String? source;

  /// SPEC-143: audit ligero — valores PREVIOS de los campos que cambiaron
  /// respecto al snapshot anterior. Solo se persisten los campos que
  /// efectivamente variaron. Null si no hay snapshot anterior o si es la
  /// primera entrada del usuario.
  final Map<String, dynamic>? previousValues;

  /// SPEC-143: timestamp exacto de cuándo se persistió esta entrada,
  /// distinto de `createdAt` (que para check-ins manuales puede ser el
  /// tiempo del check-in del usuario, no del save). Null para docs
  /// legacy. Se setea con serverTimestamp en escritura.
  final DateTime? recordedAt;

  const BiometricCheckIn({
    required this.date,
    required this.userId,
    required this.weight,
    this.bodyFatPercentage,
    this.waistCircumference,
    this.neckCircumference,
    this.imrScore,
    this.notes,
    required this.createdAt,
    this.source,
    this.previousValues,
    this.recordedAt,
  });

  // ─── Serialización ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'date': date,
      'userId': userId,
      'weight': weight,
      'bodyFatPercentage': bodyFatPercentage,
      'waistCircumference': waistCircumference,
      'imrScore': imrScore,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
    // SPEC-143: campos opcionales — omitir si null para no escribir basura
    // a Firestore ni romper docs legacy en round-trip.
    if (neckCircumference != null) m['neckCircumference'] = neckCircumference;
    if (source != null) m['source'] = source;
    if (previousValues != null && previousValues!.isNotEmpty) {
      m['previousValues'] = previousValues;
    }
    if (recordedAt != null) m['recordedAt'] = recordedAt!.toIso8601String();
    return m;
  }

  factory BiometricCheckIn.fromJson(Map<String, dynamic> json) {
    final pv = json['previousValues'];
    return BiometricCheckIn(
      date: json['date'] as String,
      userId: json['userId'] as String? ?? '',
      weight: (json['weight'] as num).toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      waistCircumference: (json['waistCircumference'] as num?)?.toDouble(),
      neckCircumference: (json['neckCircumference'] as num?)?.toDouble(),
      imrScore: (json['imrScore'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      source: json['source'] as String?,
      previousValues: pv is Map<String, dynamic> ? pv : null,
      recordedAt: json['recordedAt'] is String
          ? DateTime.parse(json['recordedAt'] as String)
          : null,
    );
  }

  // ─── Computed ─────────────────────────────────────────────────────────────

  /// Masa magra en kg, si hay %grasa disponible.
  double? get leanMass => bodyFatPercentage != null
      ? weight * (1 - bodyFatPercentage! / 100)
      : null;

  /// WHTR si hay cintura y altura. Requiere altura externa.
  double whtr(double heightCm) =>
      heightCm > 0 ? (waistCircumference ?? 0) / heightCm : 0.0;

  /// SPEC-143: true si esta entrada porta los campos extendidos. Útil
  /// para distinguir entradas legacy de modernas en analytics.
  bool get hasExtendedFields => source != null || recordedAt != null;

  /// SPEC-143: copia esta entrada con campos modificados. Útil para
  /// el `BiometricHistoryService` al construir snapshots con
  /// `source` y `previousValues` correctos.
  BiometricCheckIn copyWith({
    String? date,
    String? userId,
    double? weight,
    double? bodyFatPercentage,
    double? waistCircumference,
    double? neckCircumference,
    int? imrScore,
    String? notes,
    DateTime? createdAt,
    String? source,
    Map<String, dynamic>? previousValues,
    DateTime? recordedAt,
  }) {
    return BiometricCheckIn(
      date: date ?? this.date,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      waistCircumference: waistCircumference ?? this.waistCircumference,
      neckCircumference: neckCircumference ?? this.neckCircumference,
      imrScore: imrScore ?? this.imrScore,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      previousValues: previousValues ?? this.previousValues,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}
