/// Registro de cumplimiento diario de los 5 pilares metabólicos.
///
/// Un día "cuenta" para la racha si [qualifiesForStreak] es true,
/// lo que requiere completar al menos 3 de los 5 pilares.
///
/// No usa Freezed para evitar re-ejecución de build_runner.
/// La serialización manual es suficiente dado que el modelo es estable.
class StreakEntry {
  /// Fecha en formato 'yyyy-MM-dd' — clave primaria en Firestore.
  final String date;

  // ── Estado de cada pilar ese día ────────────────────────────────────────────

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

  const StreakEntry({
    required this.date,
    required this.fastingCompleted,
    required this.sleepCompleted,
    required this.hydrationCompleted,
    required this.exerciseLogged,
    required this.nutritionLogged,
    required this.imrScore,
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

  // ── Serialización Firestore ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'date': date,
        'fastingCompleted': fastingCompleted,
        'sleepCompleted': sleepCompleted,
        'hydrationCompleted': hydrationCompleted,
        'exerciseLogged': exerciseLogged,
        'nutritionLogged': nutritionLogged,
        'imrScore': imrScore,
      };

  factory StreakEntry.fromJson(Map<String, dynamic> json) => StreakEntry(
        date: json['date'] as String? ?? '',
        fastingCompleted: json['fastingCompleted'] as bool? ?? false,
        sleepCompleted: json['sleepCompleted'] as bool? ?? false,
        hydrationCompleted: json['hydrationCompleted'] as bool? ?? false,
        exerciseLogged: json['exerciseLogged'] as bool? ?? false,
        nutritionLogged: json['nutritionLogged'] as bool? ?? false,
        imrScore: (json['imrScore'] as num?)?.toInt() ?? 0,
      );

  /// Crea una copia modificando solo los campos especificados.
  StreakEntry copyWith({
    String? date,
    bool? fastingCompleted,
    bool? sleepCompleted,
    bool? hydrationCompleted,
    bool? exerciseLogged,
    bool? nutritionLogged,
    int? imrScore,
  }) =>
      StreakEntry(
        date: date ?? this.date,
        fastingCompleted: fastingCompleted ?? this.fastingCompleted,
        sleepCompleted: sleepCompleted ?? this.sleepCompleted,
        hydrationCompleted: hydrationCompleted ?? this.hydrationCompleted,
        exerciseLogged: exerciseLogged ?? this.exerciseLogged,
        nutritionLogged: nutritionLogged ?? this.nutritionLogged,
        imrScore: imrScore ?? this.imrScore,
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
          imrScore == other.imrScore;

  @override
  int get hashCode => date.hashCode;
}
