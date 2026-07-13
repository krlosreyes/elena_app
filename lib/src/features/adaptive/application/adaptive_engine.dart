import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart';
import 'package:elena_app/src/features/streak/domain/fasting_symptom_log.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// SPEC-257 RF-257-B1: `simplify` (bajar protocolo) ya lo emite el motor
// — ver `_evaluateSimplify`. Se activa con engagement crítico sostenido
// (adherencia semanal <50%, el mismo umbral que ya define
// `EngagementLevel.critico`) o con un reporte de hipoglucemia (Eje D,
// `hypoglycemiaReported` — hoy siempre `false` hasta que SPEC-257 §4
// Eje D conecte la captura de síntomas de `early_fasting_end_dialog.dart`).
enum SuggestionType { levelUp, simplify }

class AdaptiveSuggestion {
  final SuggestionType type;
  final String title;
  final String description;
  final String? newProtocol;
  final int? newExerciseGoal;
  final String reason;

  const AdaptiveSuggestion({
    required this.type,
    required this.title,
    required this.description,
    this.newProtocol,
    this.newExerciseGoal,
    required this.reason,
  });
}

class AdaptiveEngine {
  // SPEC-257 RF-257-B1: la escalera de auto-progresión (adherencia +
  // IMR, sin intervención humana) llega hasta 20:4 — no más. 22:2 y
  // OMAD quedan reservados a elección consciente del usuario vía
  // `ProtocolSelectorSheet` (22:2 sin supervisión, OMAD solo con
  // supervisión médica activa — Eje A). Subirlos automáticamente por
  // buen comportamiento contradiría el propio tope que Eje A define.
  static const List<String> _fastingLevels = [
    'Ninguno',
    '12:12',
    '14:10',
    '16:8',
    '18:6',
    '20:4',
  ];

  /// Evalúa estabilidad: al menos 6 de los últimos 7 días con IMR >= 75 (SPEC-08)
  static bool isIMRStable(List<StreakEntry> history) {
    if (history.length < 7) return false;

    // Tomar los últimos 7 días
    final last7 = history.take(7);
    final stableDays = last7.where((e) => e.imrScore >= 75).length;

    return stableDays >= 6;
  }

  static AdaptiveSuggestion? evaluateProtocolAdjustment({
    required EngagementLevel engagement,
    required List<StreakEntry> history,
    required String currentProtocol,
    required int currentExerciseGoal,
    // SPEC-257 Eje A: tope médico. `null` = sin gate conocido (fallback
    // conservador, se comporta como antes de SPEC-257).
    FastingEligibility? eligibility,
    // SPEC-257 Eje D (aún no conectado a UI — ver RF-257-D): true cuando
    // el usuario reportó mareo/temblor/palpitaciones al romper un ayuno
    // reciente. Fuerza `simplify` sin importar el engagement.
    bool hypoglycemiaReported = false,
  }) {
    // 0. Hipoglucemia reportada — señal de alarma de Suárez, ignora el
    // período de gracia y cualquier otro cálculo: bajar un nivel ya.
    if (hypoglycemiaReported) {
      final simplified = _evaluateSimplify(
        currentProtocol: currentProtocol,
        reason:
            'Reportaste síntomas de hipoglucemia (mareo, temblor o palpitaciones) '
            'al romper tu ayuno reciente.',
      );
      if (simplified != null) return simplified;
    }

    // 0.b Período de gracia: no sugerir cambios si el nivel es neutro (pocos datos)
    if (engagement == EngagementLevel.neutro) return null;

    // 1. Lógica de LEVEL UP (Engagement Excelente + Estabilidad IMR)
    if (engagement == EngagementLevel.excelente && isIMRStable(history)) {
      final currentIndex = _fastingLevels.indexOf(currentProtocol);
      if (currentIndex != -1 && currentIndex < _fastingLevels.length - 1) {
        final nextProtocol = _fastingLevels[currentIndex + 1];
        // SPEC-257 Eje A: el motor de comportamiento nunca propone un
        // protocolo por encima del tope médico — aunque la adherencia
        // sea perfecta, la elegibilidad manda.
        if (eligibility != null && !eligibility.allows(nextProtocol)) {
          return null;
        }
        return AdaptiveSuggestion(
          type: SuggestionType.levelUp,
          title: 'Subida de Nivel Sugerida',
          description:
              'Tu estabilidad metabólica es excepcional. Podrías beneficiarte de ampliar tu ventana de ayuno a $nextProtocol.',
          newProtocol: nextProtocol,
          reason: 'Alta adherencia y IMR estable detectados.',
        );
      }

      // Si ya está en el tope de la escalera automática (20:4), sugerir
      // micro-entrenamiento en vez de seguir subiendo protocolo.
      if (currentExerciseGoal < 45) {
        return AdaptiveSuggestion(
          type: SuggestionType.levelUp,
          title: 'Mejora de Intensidad',
          description:
              'Estás dominando tu protocolo. ¿Te gustaría añadir un micro-entrenamiento aumentando tu meta de ejercicio a ${currentExerciseGoal + 10} min?',
          newExerciseGoal: currentExerciseGoal + 10,
          reason: 'Protocolo actual dominado.',
        );
      }
      return null;
    }

    // 2. Lógica de SIMPLIFY (engagement crítico sostenido — la propia
    // definición de `EngagementLevel.critico` ya exige adherencia
    // semanal <50%, así que no hace falta una ventana adicional).
    if (engagement == EngagementLevel.critico) {
      return _evaluateSimplify(
        currentProtocol: currentProtocol,
        reason:
            'Tu adherencia semanal bajó de forma sostenida — un protocolo más '
            'corto es más fácil de mantener que ninguno.',
      );
    }

    return null;
  }

  /// SPEC-257 Eje B "simplify": un paso hacia abajo en la misma
  /// escalera que usa `levelUp`, nunca por debajo de 'Ninguno'. Devuelve
  /// `null` si ya está en el piso — no hay a dónde bajar.
  static AdaptiveSuggestion? _evaluateSimplify({
    required String currentProtocol,
    required String reason,
  }) {
    final currentIndex = _fastingLevels.indexOf(currentProtocol);
    // Protocolo fuera de la escalera automática (22:2/OMAD, elegidos a
    // mano) — bajar al techo de la escalera automática (20:4) en vez de
    // no hacer nada.
    if (currentIndex == -1) {
      if (!_fastingLevels.contains(currentProtocol)) {
        return AdaptiveSuggestion(
          type: SuggestionType.simplify,
          title: 'Simplificar protocolo',
          description:
              'Bajar a ${_fastingLevels.last} puede ayudarte a recuperar consistencia '
              'sin perder el hábito.',
          newProtocol: _fastingLevels.last,
          reason: reason,
        );
      }
      return null;
    }
    if (currentIndex <= 0) return null; // ya en 'Ninguno'
    final previousProtocol = _fastingLevels[currentIndex - 1];
    return AdaptiveSuggestion(
      type: SuggestionType.simplify,
      title: 'Simplificar protocolo',
      description:
          'Bajar a $previousProtocol puede ayudarte a recuperar consistencia '
          'sin perder el hábito.',
      newProtocol: previousProtocol,
      reason: reason,
    );
  }
}

final adaptiveProvider = Provider<AdaptiveSuggestion?>((ref) {
  final engagement = ref.watch(engagementProvider);
  final streak = ref.watch(streakProvider);
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  // SPEC-257 Eje D: reporte reciente de hipoglucemia — fuerza `simplify`
  // sin esperar a que la adherencia semanal caiga.
  final hypoglycemiaReported = ref.watch(recentHypoglycemiaReportProvider);

  if (user == null) return null;

  return AdaptiveEngine.evaluateProtocolAdjustment(
    engagement: engagement.level,
    history: streak.history,
    currentProtocol: user.fastingProtocol,
    currentExerciseGoal: user.exerciseGoalMinutes,
    eligibility: FastingEligibility.assess(user),
    hypoglycemiaReported: hypoglycemiaReported,
  );
});
