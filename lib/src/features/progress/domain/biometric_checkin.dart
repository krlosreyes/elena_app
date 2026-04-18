// SPEC-15: Road Map de Avance Personal
// Snapshot biométrico periódico del usuario.
// Se registra manualmente desde BiometricCheckInSheet.
// Almacenado en Firestore: users/{uid}/biometric_history/{yyyy-MM-dd}
// No usa Freezed para evitar build_runner.

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

  /// IMR del momento del check-in (snapshot automático del motor).
  final int? imrScore;

  /// Nota libre del usuario.
  final String? notes;

  /// Timestamp de creación.
  final DateTime createdAt;

  const BiometricCheckIn({
    required this.date,
    required this.userId,
    required this.weight,
    this.bodyFatPercentage,
    this.waistCircumference,
    this.imrScore,
    this.notes,
    required this.createdAt,
  });

  // ─── Serialización ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'date':                date,
    'userId':              userId,
    'weight':              weight,
    'bodyFatPercentage':   bodyFatPercentage,
    'waistCircumference':  waistCircumference,
    'imrScore':            imrScore,
    'notes':               notes,
    'createdAt':           createdAt.toIso8601String(),
  };

  factory BiometricCheckIn.fromJson(Map<String, dynamic> json) {
    return BiometricCheckIn(
      date:               json['date'] as String,
      userId:             json['userId'] as String? ?? '',
      weight:             (json['weight'] as num).toDouble(),
      bodyFatPercentage:  (json['bodyFatPercentage'] as num?)?.toDouble(),
      waistCircumference: (json['waistCircumference'] as num?)?.toDouble(),
      imrScore:           json['imrScore'] as int?,
      notes:              json['notes'] as String?,
      createdAt:          DateTime.parse(json['createdAt'] as String),
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
}
