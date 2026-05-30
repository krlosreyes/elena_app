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

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart'
    show fastingProvider, lastCompletedFastingProvider;

/// True si el último ayuno cerrado del usuario:
///   1. Se ATRIBUYE al día de hoy (SPEC-138: por el punto medio del
///      intervalo, no por el día calendario de `endTime`), y
///   2. Su duración total fue ≥ las horas objetivo del protocolo
///      activo (state.targetHours).
///
/// Si alguna condición falla → false (puede iniciar otro ayuno).
final hasCompletedFastingTodayProvider = Provider<bool>((ref) {
  final lastClosed = ref.watch(lastCompletedFastingProvider).valueOrNull;
  if (lastClosed == null) return false;
  final endTime = lastClosed.endTime;
  if (endTime == null) return false;

  // SPEC-138: ¿se atribuye a hoy? Un 16:8 que cierra a las 00:30 tiene su
  // punto medio el día anterior → cuenta para el día que la persona vivió,
  // no para el día nuevo (corrige el "ya completaste tu ayuno de hoy" errado).
  final now = DateTime.now();
  final attributionDay = DayBoundaryResolver.attributionDayKey(
    start: lastClosed.startTime,
    end: endTime,
  );
  if (attributionDay != DayBoundaryResolver.dayKey(now)) return false;

  // ¿Fue completado al 100%?
  final fastingState = ref.watch(fastingProvider);
  final targetSeconds = fastingState.targetHours * 3600;
  final actualSeconds = endTime.difference(lastClosed.startTime).inSeconds;
  return actualSeconds >= targetSeconds;
});
