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
import 'package:elena_app/src/features/coaching/application/coaching_fatigue_notifier.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';

class CoachingCompletionService {
  CoachingCompletionService({this.onCompleted});

  /// Callback opcional invocado cuando una acción se cuenta como completada.
  /// Lo usa el provider para resetear la racha de ignorada (RF-2.5). Default
  /// no-op → mantiene el servicio test-safe y desacoplado.
  final void Function(String actionId)? onCompleted;

  CoachingAction? _activePrimary;
  final Set<String> _completed = <String>{};

  /// El card llama esto al mostrar (o limpiar) la acción principal.
  void setActive(CoachingAction? primary) {
    _activePrimary = primary;
  }

  /// Acción recomendada activa (para el feedback de cierre RF-194-05).
  CoachingAction? get activeAction => _activePrimary;

  /// ¿Se contó como completada la acción con este id?
  bool isCompleted(String id) => _completed.contains(id);

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
    // RF-2.5: completar resetea la racha de "ignorada" de esta acción.
    onCompleted?.call(primary.id);
    return true;
  }
}

final coachingCompletionProvider = Provider<CoachingCompletionService>(
  (ref) => CoachingCompletionService(
    onCompleted: (id) =>
        ref.read(coachingFatigueProvider.notifier).recordCompleted(id),
  ),
);
