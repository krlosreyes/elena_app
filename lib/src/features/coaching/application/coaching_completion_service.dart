// SPEC-194 — correlación recomendación → registro de pilar = "completada".
//
// Diseño desacoplado y test-safe: el servicio cachea la acción recomendada
// activa (el card se la setea vía setActive). Los notifiers de pilares solo
// llaman onPillarActivity(pillar), que lee el caché — SIN leer
// coachingSelectionProvider ni tocar Firestore. Así no se acopla la escritura
// de un pilar al chain de coaching y los tests de notifiers no lo disparan.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';

class CoachingCompletionService {
  CoachingCompletionService();

  CoachingAction? _activePrimary;
  final Set<String> _completed = <String>{};

  /// El card llama esto al mostrar (o limpiar) la acción principal.
  void setActive(CoachingAction? primary) {
    _activePrimary = primary;
  }

  /// Un notifier de pilar llama esto tras un registro exitoso. Si el pilar
  /// coincide con la acción recomendada activa y no se contó antes, dispara
  /// `coaching_action_completed`. Devuelve true si se contó (para tests).
  bool onPillarActivity(Pillar pillar) {
    final primary = _activePrimary;
    if (primary == null || primary.pillar != pillar) return false;
    if (!_completed.add(primary.id)) return false; // ya contada
    AnalyticsService.logEvent(
      AnalyticsEvents.coachingActionCompleted,
      params: {
        AnalyticsParams.actionId: primary.id,
        AnalyticsParams.pillar: pillar.name,
      },
    );
    return true;
  }
}

final coachingCompletionProvider = Provider<CoachingCompletionService>(
  (ref) => CoachingCompletionService(),
);
