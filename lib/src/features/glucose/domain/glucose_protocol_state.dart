// Módulo "Tu Glucosa" — estado persistido del protocolo por usuario
// (propuesta §9.2). Documento único, mismo patrón que ExerciseProfile
// (users/{uid}/exercise_meta/profile), acá en users/{uid}/glucose_meta/
// protocol.
//
// Clase plana — mismo criterio documentado en glucose_reading.dart.

class GlucoseProtocolState {
  /// true si el protocolo está activo (automático por pathologies, o
  /// manual desde Perfil — propuesta §5.2, "disponibilidad opcional").
  final bool protocolActive;

  /// Cuándo se activó — para el copy de bienvenida y para no
  /// re-mostrarlo cada sesión.
  final DateTime? activatedAt;

  /// true si el usuario pausó el protocolo sin desactivarlo del todo
  /// (R10): deja de pedir registros pero conserva el historial y la
  /// posibilidad de reanudar sin volver a pasar por consentimiento.
  final bool paused;

  final bool consentAccepted;
  final int consentVersion;
  final DateTime? consentAcceptedAt;

  /// Hora aproximada en que el usuario suele despertar — heurística de
  /// UI (promedio móvil de wokeUp de sleep_log), no fuente de verdad de
  /// la ventana real (esa se deriva en vivo, ver GlucoseWindowState).
  final DateTime? lastReminderSentAt;

  /// Días consecutivos sin registro en-ayunas — alimenta R7
  /// (reactivación suave).
  final int missedStreak;

  const GlucoseProtocolState({
    this.protocolActive = false,
    this.activatedAt,
    this.paused = false,
    this.consentAccepted = false,
    this.consentVersion = 0,
    this.consentAcceptedAt,
    this.lastReminderSentAt,
    this.missedStreak = 0,
  });

  factory GlucoseProtocolState.initial() => const GlucoseProtocolState();

  /// El registro solo debe pedirse si el protocolo está activo, no está
  /// pausado, y ya se aceptó el consentimiento vigente.
  bool get shouldPromptForReadings =>
      protocolActive && !paused && consentAccepted;

  GlucoseProtocolState copyWith({
    bool? protocolActive,
    DateTime? activatedAt,
    bool? paused,
    bool? consentAccepted,
    int? consentVersion,
    DateTime? consentAcceptedAt,
    DateTime? lastReminderSentAt,
    int? missedStreak,
  }) {
    return GlucoseProtocolState(
      protocolActive: protocolActive ?? this.protocolActive,
      activatedAt: activatedAt ?? this.activatedAt,
      paused: paused ?? this.paused,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      consentVersion: consentVersion ?? this.consentVersion,
      consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
      lastReminderSentAt: lastReminderSentAt ?? this.lastReminderSentAt,
      missedStreak: missedStreak ?? this.missedStreak,
    );
  }

  Map<String, dynamic> toMap() => {
        'protocolActive': protocolActive,
        'activatedAt': activatedAt?.toIso8601String(),
        'paused': paused,
        'consentAccepted': consentAccepted,
        'consentVersion': consentVersion,
        'consentAcceptedAt': consentAcceptedAt?.toIso8601String(),
        'lastReminderSentAt': lastReminderSentAt?.toIso8601String(),
        'missedStreak': missedStreak,
      };

  factory GlucoseProtocolState.fromMap(Map<String, dynamic> map) {
    return GlucoseProtocolState(
      protocolActive: (map['protocolActive'] as bool?) ?? false,
      activatedAt: DateTime.tryParse(map['activatedAt'] as String? ?? ''),
      paused: (map['paused'] as bool?) ?? false,
      consentAccepted: (map['consentAccepted'] as bool?) ?? false,
      consentVersion: (map['consentVersion'] as num?)?.toInt() ?? 0,
      consentAcceptedAt:
          DateTime.tryParse(map['consentAcceptedAt'] as String? ?? ''),
      lastReminderSentAt:
          DateTime.tryParse(map['lastReminderSentAt'] as String? ?? ''),
      missedStreak: (map['missedStreak'] as num?)?.toInt() ?? 0,
    );
  }
}
