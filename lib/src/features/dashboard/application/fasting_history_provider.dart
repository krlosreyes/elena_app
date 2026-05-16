// SPEC-101: providers derivados sobre el historial de ayunos.
//
// Permite a la UI saber si el usuario ya completó su ayuno del día
// para deshabilitar "Iniciar Ayuno" — solo se permite un ayuno
// completado por día calendario.
//
// SPEC-113.bugfix: el provider primitivo `lastCompletedFastingProvider`
// se movió a `fasting_notifier.dart` para que el notifier pueda
// consumirlo sin crear un ciclo de imports. Este archivo solo expone
// el selector derivado.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart'
    show fastingProvider, lastCompletedFastingProvider;

/// True si el último ayuno cerrado del usuario:
///   1. Tiene `endTime` en el día calendario de hoy (hora local), y
///   2. Su duración total fue ≥ las horas objetivo del protocolo
///      activo (state.targetHours).
///
/// Si alguna condición falla → false (puede iniciar otro ayuno).
final hasCompletedFastingTodayProvider = Provider<bool>((ref) {
  final lastClosed = ref.watch(lastCompletedFastingProvider).valueOrNull;
  if (lastClosed == null) return false;
  final endTime = lastClosed.endTime;
  if (endTime == null) return false;

  // ¿Es de hoy?
  final now = DateTime.now();
  final isSameDay = endTime.year == now.year &&
      endTime.month == now.month &&
      endTime.day == now.day;
  if (!isSameDay) return false;

  // ¿Fue completado al 100%?
  final fastingState = ref.watch(fastingProvider);
  final targetSeconds = fastingState.targetHours * 3600;
  final actualSeconds = endTime.difference(lastClosed.startTime).inSeconds;
  return actualSeconds >= targetSeconds;
});
