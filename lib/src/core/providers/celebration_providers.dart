import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-220: Celebración al cruzar umbral 3/5 pilares
// ─────────────────────────────────────────────────────────────────────────────

/// Tipo de celebración. Extensible para milestones futuros (7 días, 30 días).
enum CelebrationType {
  /// El usuario completó ≥3 pilares hoy → cuenta para su racha.
  streakThreshold,

  /// SPEC-255 RF-04: la racha cruzó un hito nombrado (3/7/14/30/60/100 días).
  streakMilestone,

  /// SPEC-255 RF-03: una racha activa se rompió sin reserva disponible.
  /// Mensaje de reencuadre autocompasivo, no de culpa.
  streakBroken,
}

/// Evento one-shot de celebración emitido por StreakNotifier.
/// Se consume y se limpia — no persiste en Firestore.
class CelebrationEvent {
  final CelebrationType type;

  /// Pilares completados al momento de la celebración (3, 4 o 5).
  final int pillarsCompleted;

  /// Racha actual (incluyendo hoy).
  final int currentStreak;

  final DateTime timestamp;

  const CelebrationEvent({
    required this.type,
    required this.pillarsCompleted,
    required this.currentStreak,
    required this.timestamp,
  });

  /// Copy para el caso del pilar extra (4/5, 5/5).
  String get message {
    switch (type) {
      case CelebrationType.streakMilestone:
        return '🏆 Día $currentStreak — nuevo hito de racha.';
      case CelebrationType.streakBroken:
        return 'Tu racha de $currentStreak días se pausó. Lo que aprendiste no se borró.';
      case CelebrationType.streakThreshold:
        if (pillarsCompleted >= 5) {
          return '⭐ 5/5 — Día perfecto. Tu cuerpo lo nota.';
        }
        if (pillarsCompleted == 4) {
          return '💪 4/5 — Casi perfecto. Vas muy bien.';
        }
        if (currentStreak > 1) {
          return '🔥 3/5 — Día $currentStreak consecutivo. Sigue así.';
        }
        return '🎯 3/5 — ¡Hoy cuentas para tu racha!';
    }
  }
}

/// Provider one-shot: el widget lo consume y lo limpia (set null).
final celebrationEventProvider = StateProvider<CelebrationEvent?>((_) => null);
