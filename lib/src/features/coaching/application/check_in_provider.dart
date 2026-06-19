// SPEC-232: providers para check-ins emocionales durante el ayuno.
//
// Conecta:
//   1. CheckInRepository (stream Firestore) → historia del ciclo actual
//   2. PredictiveTriggerEngine.checkInPrompt() → prompt in-app
//   3. FastingCheckIn → persistencia de la respuesta
//   4. Coaching adaptativo post-respuesta

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/coaching/application/predictive_trigger_engine.dart';
import 'package:elena_app/src/features/coaching/data/check_in_repository.dart';
import 'package:elena_app/src/features/coaching/domain/actionable_prompt.dart';
import 'package:elena_app/src/features/coaching/domain/fasting_check_in.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stream: check-ins del ciclo actual
// ─────────────────────────────────────────────────────────────────────────────

/// Stream de todos los check-ins desde el inicio del ciclo de ayuno actual.
/// Vacío si no hay ayuno activo.
final checkInHistoryProvider =
    StreamProvider.autoDispose<List<FastingCheckIn>>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null || user.id.isEmpty) return const Stream.empty();

  final fastingState = ref.watch(fastingProvider);
  if (!fastingState.isActive || fastingState.startTime == null) {
    return const Stream.empty();
  }

  final repo = ref.read(checkInRepositoryProvider);
  return repo.watchSince(user.id, fastingState.startTime!);
});

/// Último check-in respondido en el ciclo actual (para anti-fatiga y coaching).
final lastCheckInProvider = Provider.autoDispose<FastingCheckIn?>((ref) {
  final history = ref.watch(checkInHistoryProvider).valueOrNull;
  if (history == null || history.isEmpty) return null;
  return history.last;
});

// ─────────────────────────────────────────────────────────────────────────────
// Prompt interactivo in-app
// ─────────────────────────────────────────────────────────────────────────────

/// Id del prompt de check-in que el usuario pospuso en esta sesión.
final dismissedCheckInPromptProvider = StateProvider<String?>((ref) => null);

/// Prompt de check-in a mostrar in-app, o null si se suprime.
final interactiveCheckInPromptProvider = Provider<ActionablePrompt?>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null || user.id.isEmpty) return null;

  final fastingState = ref.watch(fastingProvider);
  if (!fastingState.isActive || fastingState.startTime == null) return null;

  final fastingDuration =
      DateTime.now().difference(fastingState.startTime!);

  final lastCheckIn = ref.watch(lastCheckInProvider);

  // ¿Ya respondió el hito actual? Si el hito de la última respuesta coincide
  // con el hito activo, no volver a mostrar.
  final hoursElapsed = fastingDuration.inHours;
  int? activeHito;
  for (final h in PredictiveTriggerEngine.kCheckInMilestones.reversed) {
    if (hoursElapsed >= h) {
      activeHito = h;
      break;
    }
  }
  if (activeHito != null &&
      lastCheckIn != null &&
      lastCheckIn.fastingHour == activeHito) {
    return null; // Ya respondió este hito.
  }

  final prompt = PredictiveTriggerEngine.checkInPrompt(
    fastingActive: true,
    fastingDuration: fastingDuration,
    now: DateTime.now(),
    wakeHour: user.profile.wakeUpTime.hour,
    sleepHour: user.profile.sleepTime.hour,
    lastCheckInAt: lastCheckIn?.timestamp,
  );
  if (prompt == null) return null;

  // Respetar el "dismiss" de esta sesión.
  if (ref.watch(dismissedCheckInPromptProvider) == prompt.id) return null;

  return prompt;
});

// ─────────────────────────────────────────────────────────────────────────────
// Acción: guardar un check-in
// ─────────────────────────────────────────────────────────────────────────────

/// Guarda un check-in emocional. Llamado tanto desde la tarjeta in-app como
/// desde el CoachingActionRouter (notificación background).
void saveCheckIn({
  required String userId,
  required FastingFeeling feeling,
  required CheckInRepository repo,
  DateTime? fastingStart,
  String? cycleId,
}) {
  final now = DateTime.now();
  final fastingHour = fastingStart != null
      ? now.difference(fastingStart).inHours
      : 0;

  // Snap al hito más cercano.
  int snappedHour = fastingHour;
  for (final h in PredictiveTriggerEngine.kCheckInMilestones.reversed) {
    if (fastingHour >= h) {
      snappedHour = h;
      break;
    }
  }

  final checkIn = FastingCheckIn(
    id: FastingCheckIn.buildId(userId, now, snappedHour),
    userId: userId,
    timestamp: now,
    fastingHour: snappedHour,
    feeling: feeling,
    cycleId: cycleId,
  );

  repo.save(checkIn);
  AppLogger.debug(
    '[CheckIn] saved: ${feeling.name} at ${snappedHour}h fasting',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Coaching post-respuesta
// ─────────────────────────────────────────────────────────────────────────────

/// Mensaje empático del coach basado en la respuesta del check-in.
class CheckInCoachingResponse {
  final String message;
  final PromptActionType? followUpAction; // null = solo refuerzo verbal

  const CheckInCoachingResponse({
    required this.message,
    this.followUpAction,
  });
}

/// Genera la respuesta del coach según el sentimiento reportado.
/// Si hay 2 irritables consecutivos, sugiere cerrar.
CheckInCoachingResponse getCoachingResponse(
  FastingFeeling feeling,
  List<FastingCheckIn> recentHistory,
) {
  // Regla clave: irritable 2x consecutivas → sugerir cierre.
  if (feeling == FastingFeeling.irritable && recentHistory.length >= 1) {
    final prev = recentHistory.last;
    if (prev.feeling == FastingFeeling.irritable) {
      return const CheckInCoachingResponse(
        message: 'Llevas dos momentos difíciles seguidos. '
            'Está bien parar si lo necesitas. Tu salud es lo primero.',
        followUpAction: PromptActionType.closeFasting,
      );
    }
  }

  return switch (feeling) {
    FastingFeeling.energized => const CheckInCoachingResponse(
        message: 'Tu cuerpo ya encontró su ritmo. Sigue así.',
      ),
    FastingFeeling.focused => const CheckInCoachingResponse(
        message: 'Excelente claridad mental. Tu cerebro está usando cetonas.',
      ),
    FastingFeeling.good => const CheckInCoachingResponse(
        message: 'Vas bien, sigue así.',
      ),
    FastingFeeling.hungry => const CheckInCoachingResponse(
        message:
            'Un vaso de agua con limón puede ayudar. ¿Lo tomamos?',
        followUpAction: PromptActionType.logWater,
      ),
    FastingFeeling.tired => const CheckInCoachingResponse(
        message:
            'Es normal en esta fase. Un té sin azúcar puede darte un empujón.',
      ),
    FastingFeeling.irritable => const CheckInCoachingResponse(
        message:
            'Está bien parar si lo necesitas. ¿Quieres cerrar el ayuno?',
        followUpAction: PromptActionType.closeFasting,
      ),
  };
}
