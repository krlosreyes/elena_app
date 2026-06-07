// SPEC-194 Adenda circadiana — genera candidatos según la fase activa
// (menú fase → acción óptima) + el override del bloqueo intestinal (21:30).
// Sin Riverpod — función estática testeable.

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/confidence_level.dart';

class CircadianGenerator {
  const CircadianGenerator._();

  /// Minutos antes de las 21:30 a partir de los cuales "cerrar la cocina"
  /// se vuelve override duro (Adenda §5).
  static const int kLockOverrideMin = 60;

  static List<CoachingAction> generate(
    CircadianPhase phase, {
    int? minutesToIntestinalLock,
  }) {
    final out = <CoachingAction>[];

    // Override del bloqueo intestinal: cruzar 21:30 corta el factor
    // circadiano de 1.0 a 0.5 (el mayor golpe evitable al IMR).
    final m = minutesToIntestinalLock;
    if (m != null && m >= 0 && m <= kLockOverrideMin) {
      out.add(CoachingAction(
        id: 'circadian_close_kitchen',
        title: 'Cierra tu cocina',
        actionText: 'Cierra tu ventana de comida antes de las 21:30.',
        reason:
            'Después de las 21:30 tu factor circadiano cae de 1.0 a 0.5 — y '
            'el circadiano es el mayor componente de tu IMR (38% de tu '
            'conducta).',
        pillar: Pillar.nutrition,
        confidence: ConfidenceLevel.medium,
        citation: '· Lopez-Minguez 2018',
        source: ActionSource.circadian,
        urgencyKind: ActionUrgencyKind.deadlineHard,
        circadianImpact: 1.0,
        minutesToDeadline: m,
      ));
    }

    final phaseAction = _phaseOpportunity(phase);
    if (phaseAction != null) out.add(phaseAction);
    return out;
  }

  /// Acción óptima de la fase activa. Null para fases sin acción accionable
  /// (sueño: el usuario descansa; cognitivo: foco mental, no pilar).
  static CoachingAction? _phaseOpportunity(CircadianPhase phase) {
    switch (phase) {
      case CircadianPhase.alerta:
        return const CoachingAction(
          id: 'circadian_morning_hydrate',
          title: 'Arranca hidratado',
          actionText: 'Toma un vaso de agua y busca luz natural al despertar.',
          reason:
              'La hidratación y la luz temprana ordenan tu reloj y tu energía '
              'del día.',
          pillar: Pillar.hydration,
          confidence: ConfidenceLevel.low,
          citation: '· Biological Dial',
          source: ActionSource.circadian,
          urgencyKind: ActionUrgencyKind.phaseOpportunity,
          circadianImpact: 0.4,
        );
      case CircadianPhase.receso:
        return const CoachingAction(
          id: 'circadian_main_meal_early',
          title: 'Tu comida principal, temprano',
          actionText: 'Si vas a hacer tu comida más grande, que sea ahora.',
          reason:
              'Comer fuerte temprano aprovecha tu mejor sensibilidad a la '
              'insulina del día.',
          pillar: Pillar.nutrition,
          confidence: ConfidenceLevel.medium,
          citation: '· Lopez-Minguez 2018',
          source: ActionSource.circadian,
          urgencyKind: ActionUrgencyKind.phaseOpportunity,
          circadianImpact: 0.7,
        );
      case CircadianPhase.motorFuerza:
        return const CoachingAction(
          id: 'circadian_train_peak',
          title: 'Tu pico de fuerza',
          actionText: 'Es buena hora para entrenar: tu cuerpo rinde más ahora.',
          reason:
              'El rendimiento físico alcanza su máximo entre las 15 y las 20h.',
          pillar: Pillar.exercise,
          confidence: ConfidenceLevel.medium,
          citation: '· Facer-Childs 2018',
          source: ActionSource.circadian,
          urgencyKind: ActionUrgencyKind.phaseOpportunity,
          circadianImpact: 0.75,
        );
      case CircadianPhase.creatividad:
        return const CoachingAction(
          id: 'circadian_winddown',
          title: 'Baja el ritmo',
          actionText: 'Baja luces y prepara tu descanso para dormir mejor.',
          reason:
              'Las horas previas al sueño preparan la reparación nocturna.',
          pillar: Pillar.sleep,
          confidence: ConfidenceLevel.medium,
          citation: '· Walker 2017',
          source: ActionSource.circadian,
          urgencyKind: ActionUrgencyKind.phaseOpportunity,
          circadianImpact: 0.8,
        );
      case CircadianPhase.sueno:
      case CircadianPhase.cognitivo:
        return null;
    }
  }
}
