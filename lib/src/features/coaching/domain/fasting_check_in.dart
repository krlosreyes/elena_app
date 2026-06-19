// SPEC-232: Check-ins emocionales durante el ayuno.
//
// Modelo liviano de un check-in: cómo se siente el usuario en un hito
// de ayuno (4h, 8h, 12h, 16h). Persiste en Firestore y alimenta al
// motor de coaching para adaptar la siguiente acción.

/// Sentimientos predefinidos — orden por valencia (positivo → negativo).
/// La notificación accionable muestra 4 (sin focused/irritable por límite
/// de iOS); la tarjeta in-app muestra las 6.
enum FastingFeeling {
  energized, // "Con energía"
  focused, // "Concentrado"
  good, // "Bien"
  hungry, // "Con hambre"
  tired, // "Cansado"
  irritable, // "Irritable"
}

/// Extensiones de utilidad sobre FastingFeeling.
extension FastingFeelingX on FastingFeeling {
  /// Label visible al usuario (español neutro LatAm).
  String get label => switch (this) {
        FastingFeeling.energized => 'Con energía',
        FastingFeeling.focused => 'Concentrado',
        FastingFeeling.good => 'Bien',
        FastingFeeling.hungry => 'Con hambre',
        FastingFeeling.tired => 'Cansado',
        FastingFeeling.irritable => 'Irritable',
      };

  /// Emoji representativo.
  String get emoji => switch (this) {
        FastingFeeling.energized => '💪',
        FastingFeeling.focused => '🧠',
        FastingFeeling.good => '🙂',
        FastingFeeling.hungry => '🍽️',
        FastingFeeling.tired => '😴',
        FastingFeeling.irritable => '😤',
      };

  /// true si la valencia es negativa (activa coaching empático).
  bool get isNegative =>
      this == FastingFeeling.hungry ||
      this == FastingFeeling.tired ||
      this == FastingFeeling.irritable;

  /// true si es positivo (refuerzo).
  bool get isPositive =>
      this == FastingFeeling.energized ||
      this == FastingFeeling.focused ||
      this == FastingFeeling.good;
}

/// Un check-in emocional registrado durante el ayuno.
class FastingCheckIn {
  final String id; // 'checkin_{userId}_{isoDate}_{fastingHour}'
  final String userId;
  final DateTime timestamp;
  final int fastingHour; // hora de ayuno al momento del check-in (4, 8, 12, 16)
  final FastingFeeling feeling;
  final String? cycleId; // metabolic cycle al que pertenece

  const FastingCheckIn({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.fastingHour,
    required this.feeling,
    this.cycleId,
  });

  /// Genera un ID determinista (idempotente por usuario + día + hito).
  static String buildId(String userId, DateTime when, int fastingHour) {
    final d = when.toLocal();
    final iso =
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    return 'checkin_${userId}_${iso}_${fastingHour}h';
  }

  // ── Firestore serialización ──────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'fastingHour': fastingHour,
        'feeling': feeling.name,
        if (cycleId != null) 'cycleId': cycleId,
      };

  static FastingCheckIn? fromMap(String id, Map<String, dynamic> m) {
    final feelingName = m['feeling'] as String?;
    if (feelingName == null) return null;
    FastingFeeling? feeling;
    for (final f in FastingFeeling.values) {
      if (f.name == feelingName) {
        feeling = f;
        break;
      }
    }
    if (feeling == null) return null;

    return FastingCheckIn(
      id: id,
      userId: (m['userId'] as String?) ?? '',
      timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ??
          DateTime.now(),
      fastingHour: (m['fastingHour'] as num?)?.toInt() ?? 0,
      feeling: feeling,
      cycleId: m['cycleId'] as String?,
    );
  }
}
