// DEBT-01 (auditoría técnica 21-jul, P1): tests de
// `OnboardingGoalsController`, extraído de `_OnboardingScreenState`
// (antes `_goalDrafts`/`_goalDraftsInitialized`/
// `_ensureGoalDraftsInitialized`/`_persistGoalDrafts`).
//
// Cubre exactamente el comportamiento que tenía el código dentro del
// widget: init idempotente, reemplazo puntual de un draft, y persist
// que arma el mapa de UserGoal respetando `isActive` — incluyendo el
// caso "sin drafts → no llama al repo" (edge case que documentaba el
// comentario original de `_finalSubmit`).

import 'dart:async';

import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/data/goal_repository.dart';
import 'package:elena_app/src/features/goals/domain/goal_repository.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/presentation/goal_setup_screen.dart'
    show GoalDraft;
import 'package:elena_app/src/features/onboarding/application/onboarding_goals_controller.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _buildUser({String id = 'u1'}) => UserModel(
      id: id,
      age: 35,
      gender: 'M',
      weight: 90,
      height: 175,
      waistCircumference: 100,
      neckCircumference: 40,
      bodyFatPercentage: 28,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 7, 0),
        sleepTime: DateTime(2026, 1, 1, 23, 0),
        firstMealGoal: DateTime(2026, 1, 1, 12, 0),
        lastMealGoal: DateTime(2026, 1, 1, 20, 0),
      ),
    );

/// Stream controller para simular emisiones de currentUserStreamProvider,
/// mismo patrón que biometric_backfill_provider_test.dart.
class _UserStreamController {
  final controller = StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get stream => controller.stream;
  void emit(UserModel? user) => controller.add(user);
  Future<void> close() => controller.close();
}

/// Fake de GoalRepository — captura la última llamada a saveGoals sin
/// tocar Firestore.
class _FakeGoalRepository implements GoalRepository {
  String? lastUserId;
  Map<GoalType, UserGoal>? lastSavedGoals;
  int saveCalls = 0;

  @override
  Future<void> saveGoals(String userId, Map<GoalType, UserGoal> goals) async {
    saveCalls++;
    lastUserId = userId;
    lastSavedGoals = goals;
  }

  @override
  Stream<Map<GoalType, UserGoal>> watchGoals(String userId) =>
      const Stream.empty();

  @override
  Future<Map<GoalType, UserGoal>> fetchGoals(String userId) async => const {};
}

void main() {
  late _UserStreamController userStream;
  late _FakeGoalRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    userStream = _UserStreamController();
    fakeRepo = _FakeGoalRepository();
    container = ProviderContainer(overrides: [
      currentUserStreamProvider.overrideWith((ref) => userStream.stream),
      goalRepositoryProvider.overrideWithValue(fakeRepo),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await userStream.close();
  });

  test('ensureInitialized arma un draft por cada GoalType', () {
    final controller = container.read(onboardingGoalsControllerProvider);
    controller.ensureInitialized(_buildUser());

    expect(controller.initialized, isTrue);
    expect(controller.drafts.keys.toSet(), GoalType.values.toSet());
    // Cada draft trae su propio target/current del engine — no están vacíos.
    for (final draft in controller.drafts.values) {
      expect(draft.target, isNotNull);
    }
  });

  test(
      'ensureInitialized es idempotente: no pisa un draft ya modificado '
      'por el usuario en una segunda llamada', () {
    final controller = container.read(onboardingGoalsControllerProvider);
    controller.ensureInitialized(_buildUser());

    final type = GoalType.values.first;
    final original = controller.drafts[type]!;
    final userEdited = GoalDraft(
      type: type,
      target: original.target + 5,
      current: original.current,
      rationale: original.rationale,
      statusLabel: original.statusLabel,
      isActive: !original.isActive,
      originalSuggestion: original.originalSuggestion,
    );
    controller.updateDraft(type, userEdited);

    // Simula que _buildStepGoals se vuelve a ejecutar (ej. el PageView
    // reconstruye el step al navegar entre pasos).
    controller.ensureInitialized(_buildUser());

    expect(controller.drafts[type]!.target, original.target + 5);
    expect(controller.drafts[type]!.isActive, !original.isActive);
  });

  test('updateDraft reemplaza solo el tipo indicado', () {
    final controller = container.read(onboardingGoalsControllerProvider);
    controller.ensureInitialized(_buildUser());

    final targetType = GoalType.values.first;
    final otherType = GoalType.values[1];
    final before = controller.drafts[otherType];

    final updated = controller.drafts[targetType]!;
    controller.updateDraft(
      targetType,
      GoalDraft(
        type: targetType,
        target: 999,
        current: updated.current,
        rationale: updated.rationale,
        statusLabel: updated.statusLabel,
        isActive: updated.isActive,
        originalSuggestion: updated.originalSuggestion,
      ),
    );

    expect(controller.drafts[targetType]!.target, 999);
    expect(controller.drafts[otherType], same(before));
  });

  test('persist() con drafts vacíos no llama al repo (caso edge de '
      '_finalSubmit: paso Goals nunca se inicializó)', () async {
    final controller = container.read(onboardingGoalsControllerProvider);
    await controller.persist();
    expect(fakeRepo.saveCalls, 0);
  });

  test(
      'persist() guarda un UserGoal por draft respetando isActive '
      '(Opción B: incluso los inactivos del engine se guardan)',
      () async {
    // Fuerza la creación de GoalNotifier y su suscripción a
    // currentUserStreamProvider ANTES de emitir — un StreamController
    // broadcast no reproduce eventos a suscriptores tardíos.
    container.read(goalsProvider);
    userStream.emit(_buildUser());
    await Future<void>.delayed(Duration.zero);

    final controller = container.read(onboardingGoalsControllerProvider);
    controller.ensureInitialized(_buildUser());

    final type = GoalType.values.first;
    final draft = controller.drafts[type]!;
    controller.updateDraft(
      type,
      GoalDraft(
        type: type,
        target: draft.target,
        current: draft.current,
        rationale: draft.rationale,
        statusLabel: draft.statusLabel,
        isActive: false, // fuerza un caso inactivo explícito
        originalSuggestion: draft.originalSuggestion,
      ),
    );

    await controller.persist();

    expect(fakeRepo.saveCalls, 1);
    expect(fakeRepo.lastUserId, 'u1');
    expect(fakeRepo.lastSavedGoals!.length, GoalType.values.length);
    expect(fakeRepo.lastSavedGoals![type]!.isActive, isFalse);
    expect(fakeRepo.lastSavedGoals![type]!.targetValue, draft.target);
  });
}
