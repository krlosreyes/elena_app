// DEBT-01 (auditoría técnica 21-jul, P1): primer paso del desmontaje
// incremental del God Widget de onboarding (2459 líneas, 30+ campos de
// estado mutable). Extrae el estado y la lógica de negocio del paso
// "Tus objetivos" (SPEC-168.0.A) de `_OnboardingScreenState` a este
// controller dedicado.
//
// Alcance deliberadamente acotado: SOLO se extraen `_goalDrafts` +
// `_goalDraftsInitialized` + `_ensureGoalDraftsInitialized` +
// `_persistGoalDrafts`. `_firstMealGoal`/`_lastMealGoal` (TimeOfDay)
// NO se tocan — son horarios de la ventana de alimentación del paso
// "Ritmos" (paso 2), entrelazados con la sugerencia de protocolo
// (`_applyProtocolChange`) y el cálculo de ventana óptima
// (`OptimalScheduleCalculator`), y quedan fuera de este paso a
// propósito (ver Plan_de_Accion_ElenaApp_2026-07-21.docx).
//
// Deliberadamente NO es un StateNotifier: en el código original,
// `_ensureGoalDraftsInitialized()` se invoca DENTRO de `build()`
// (`_buildStepGoals`) y necesita que el valor esté listo para leerse
// en la MISMA pasada síncrona — el propio código previo mutaba
// `_goalDrafts` como campo simple, sin pasar por `setState()`, por
// esa razón exacta. Reemplazarlo por un `StateNotifierProvider` cuyo
// `state = ...` se dispara desde dentro de `build()` arriesga
// "setState()/markNeedsBuild() called during build" — un riesgo real
// que no se puede verificar sin el toolchain de Flutter en este
// sandbox. Este controller replica el patrón que ya funcionaba:
// mutación directa de campos; `OnboardingScreen` sigue siendo quien
// llama `setState()` cuando el usuario cambia un draft, igual que
// antes — solo que el Map ahora vive acá en vez de en el State del
// widget.
//
// Scope del provider: `Provider.autoDispose` para que una nueva
// sesión de onboarding (nuevo `OnboardingScreen` montado — ej. otro
// usuario firma después de cerrar sesión sin reiniciar la app) arranque
// con drafts limpios en vez de heredar el estado de la sesión
// anterior. `OnboardingScreen` debe hacer `ref.watch(...)` (no solo
// `ref.read`) al menos una vez en su `build()` para mantenerlo vivo
// mientras la pantalla esté montada — un `Provider.autoDispose` sin
// watchers activos se destruye entre frames.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/application/goal_suggestion_engine.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/presentation/goal_setup_screen.dart'
    show GoalDraft;
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class OnboardingGoalsController {
  OnboardingGoalsController(this._ref);

  final Ref _ref;

  /// SPEC-168.0.A: borrador local por tipo de objetivo. Público y
  /// mutable a propósito — `OnboardingScreen` sigue siendo dueño del
  /// ciclo de `setState`/UI; este controller solo centraliza el dato
  /// y la lógica de negocio (init + persist). Portado 1:1 desde
  /// `_goalDrafts`.
  Map<GoalType, GoalDraft> drafts = {};

  /// Portado 1:1 desde `_goalDraftsInitialized`.
  bool initialized = false;

  /// Lazy-init idempotente: arma los 7 drafts a partir de las
  /// sugerencias del engine sobre el `UserModel` actual del
  /// onboarding. Portado 1:1 desde `_ensureGoalDraftsInitialized`
  /// (ver nota de archivo sobre por qué no dispara notifyListeners).
  void ensureInitialized(UserModel user) {
    if (initialized) return;
    final suggestions = GoalSuggestionEngine.suggest(user);

    drafts = {
      for (final type in GoalType.values)
        type: GoalDraft(
          type: type,
          target: suggestions[type]!.suggestedTarget,
          current: suggestions[type]!.currentValue,
          rationale: suggestions[type]!.rationale,
          statusLabel: suggestions[type]!.currentStatusLabel,
          isActive: suggestions[type]!.shouldActivate,
          originalSuggestion: suggestions[type]!.suggestedTarget,
        ),
    };
    initialized = true;
  }

  /// Reemplaza el draft de un tipo puntual (ej. el usuario movió un
  /// slider o togglea "activar"). Portado 1:1 desde
  /// `setState(() => _goalDrafts[type] = updated)` — el `setState`
  /// sigue viviendo en `OnboardingScreen`, este método solo muta el
  /// dato.
  void updateDraft(GoalType type, GoalDraft updated) {
    drafts[type] = updated;
  }

  /// SPEC-168.0.A v2 (Opción B, Carlos 2026-06-03): persiste TODOS
  /// los drafts respetando su `isActive` — incluso si el usuario no
  /// tocó nada, las recomendaciones del engine se guardan para que
  /// Perfil las muestre. Portado 1:1 desde `_persistGoalDrafts`.
  Future<void> persist() async {
    if (drafts.isEmpty) return;
    final goals = <GoalType, UserGoal>{};
    for (final draft in drafts.values) {
      goals[draft.type] = UserGoal(
        type: draft.type,
        targetValue: draft.target,
        startValue: draft.current,
        isActive: draft.isActive,
        createdAt: DateTime.now(),
      );
    }
    if (goals.isEmpty) return;
    await _ref.read(goalsProvider.notifier).saveAll(goals);
  }
}

final onboardingGoalsControllerProvider =
    Provider.autoDispose<OnboardingGoalsController>(
  (ref) => OnboardingGoalsController(ref),
);
