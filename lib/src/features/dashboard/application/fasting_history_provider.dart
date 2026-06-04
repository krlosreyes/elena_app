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
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart'
    show currentMetabolicCycleProvider;

/// True si el último ayuno cerrado del usuario:
///   1. Pertenece al CICLO METABÓLICO actual (SPEC-149.2.bugfix
///      2026-06-02), o al día calendárico si no hay ciclo abierto, y
///   2. Su duración total fue ≥ las horas objetivo del protocolo
///      activo (state.targetHours).
///
/// Si alguna condición falla → false (puede iniciar otro ayuno).
///
/// SPEC-149.2.bugfix: antes usaba solo día calendárico. Si el usuario
/// cerraba el ciclo metabólico a las 21:00 después de haber completado
/// un ayuno hoy a las 13:00, el provider seguía devolviendo true porque
/// ambos eran del mismo día calendárico → el ring de Ayuno NO se
/// reseteaba en el ciclo nuevo. Ahora se ancla al cycle.startedAt.
final hasCompletedFastingTodayProvider = Provider<bool>((ref) {
  final lastClosed = ref.watch(lastCompletedFastingProvider).valueOrNull;
  if (lastClosed == null) return false;
  final endTime = lastClosed.endTime;
  if (endTime == null) return false;

  // SPEC-149.2.bugfix: criterio de pertenencia al período actual.
  final currentCycle = ref.watch(currentMetabolicCycleProvider).valueOrNull;
  bool belongsToCurrentWindow;
  if (currentCycle != null) {
    // El ayuno cuenta para este ciclo solo si terminó DENTRO del ciclo
    // actual (endTime >= cycle.startedAt). Un ayuno que cerró 13:00 y
    // el ciclo nuevo arrancó 21:00 NO cuenta — pertenece al ciclo
    // anterior, ya cerrado.
    belongsToCurrentWindow = !endTime.isBefore(currentCycle.startedAt);
  } else {
    // Fallback calendárico (modo "Ninguno" o estado pre-bootstrap):
    // criterio SPEC-138 original (atribución por punto medio del
    // intervalo, no por día calendario de endTime).
    final now = DateTime.now();
    final attributionDay = DayBoundaryResolver.attributionDayKey(
      start: lastClosed.startTime,
      end: endTime,
    );
    belongsToCurrentWindow =
        attributionDay == DayBoundaryResolver.dayKey(now);
  }
  if (!belongsToCurrentWindow) return false;

  // ¿Fue completado al 100%?
  final fastingState = ref.watch(fastingProvider);
  final targetSeconds = fastingState.targetHours * 3600;
  final actualSeconds = endTime.difference(lastClosed.startTime).inSeconds;
  return actualSeconds >= targetSeconds;
});
