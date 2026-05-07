// Tests del NutritionNotifier con fake NutritionRepository — SPEC-66 v2.
//
// Cubre CA-63-04 (el patrón Domain↔DataSource↔Mapper es testeable sin
// Firestore real) y valida el comportamiento del notifier:
//
// - Al autenticarse el usuario, el notifier suscribe el stream del repo.
// - logMeal(label, mealTime) invoca repo.saveMeal con un log construido.
// - El stream del repo dispara un recalculate del state (todayLogs,
//   nutritionScore, windowAdherence).
// - removeLastMeal invoca repo.removeLastMeal.
// - resetDaily limpia el cache local (los logs persistidos quedan en repo).

import 'dart:async';

import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fake repository ─────────────────────────────────────────────────────────

class FakeNutritionRepository implements NutritionRepository {
  final _logsController =
      StreamController<List<NutritionLog>>.broadcast();
  final List<NutritionLog> _today = [];

  /// Llamado por los tests para inyectar el stream que el notifier observa.
  void emit(List<NutritionLog> logs) {
    _today
      ..clear()
      ..addAll(logs);
    _logsController.add(List.unmodifiable(logs));
  }

  /// Capturas para verificar que el notifier llama al repo.
  final List<NutritionLog> savedMeals = [];
  int removeLastCount = 0;

  @override
  Stream<List<NutritionLog>> watchTodayLogs(String userId) =>
      _logsController.stream;

  @override
  Future<void> saveMeal(String userId, NutritionLog log) async {
    savedMeals.add(log);
    final next = [..._today, log];
    emit(next);
  }

  @override
  Future<void> removeLastMeal(String userId) async {
    removeLastCount++;
    if (_today.isEmpty) return;
    emit(_today.sublist(0, _today.length - 1));
  }

  void dispose() {
    _logsController.close();
  }
}

// ─── User stream stub ────────────────────────────────────────────────────────

UserModel _user({int mealsPerDay = 3}) => UserModel(
      id: 'u-1',
      age: 30,
      gender: 'M',
      weight: 75,
      height: 175,
      mealsPerDay: mealsPerDay,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 5, 1, 6),
        sleepTime: DateTime(2026, 5, 1, 22),
        firstMealGoal: DateTime(2026, 5, 1, 8),
        lastMealGoal: DateTime(2026, 5, 1, 19),
      ),
    );

void main() {
  group('NutritionNotifier con FakeNutritionRepository', () {
    late FakeNutritionRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeNutritionRepository();
      container = ProviderContainer(
        overrides: [
          nutritionRepositoryProvider.overrideWithValue(fakeRepo),
          currentUserStreamProvider
              .overrideWith((ref) => Stream.value(_user())),
        ],
      );
      // Forzar la inicialización del notifier.
      container.read(nutritionProvider);
    });

    tearDown(() {
      container.dispose();
      fakeRepo.dispose();
    });

    test('Cuando el repo emite logs, el state los refleja', () async {
      // Esperar al ciclo del listen interno.
      await Future<void>.delayed(Duration.zero);

      final log = NutritionLog(
        id: 'log-1',
        timestamp: DateTime(2026, 5, 1, 13),
        label: 'Almuerzo',
        withinCircadianWindow: true,
      );
      fakeRepo.emit([log]);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(nutritionProvider);
      expect(state.todayLogs.length, 1);
      expect(state.todayLogs.first.id, 'log-1');
      expect(state.mealsLoggedToday, 1);
    });

    test('logMeal invoca repo.saveMeal con el label correcto', () async {
      await Future<void>.delayed(Duration.zero);
      fakeRepo.emit(const []);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(nutritionProvider.notifier)
          .logMeal(label: 'Almuerzo', mealTime: DateTime(2026, 5, 1, 13));

      expect(fakeRepo.savedMeals.length, 1);
      expect(fakeRepo.savedMeals.first.label, 'Almuerzo');
      expect(fakeRepo.savedMeals.first.timestamp, DateTime(2026, 5, 1, 13));
      expect(fakeRepo.savedMeals.first.id, isNotEmpty);
    });

    test('removeLastMeal invoca repo.removeLastMeal', () async {
      await Future<void>.delayed(Duration.zero);
      await container.read(nutritionProvider.notifier).removeLastMeal();
      expect(fakeRepo.removeLastCount, 1);
    });

    test('nutritionScore se recalcula cuando llegan logs', () async {
      await Future<void>.delayed(Duration.zero);
      // 3 comidas dentro de ventana, target 3 → mealCount=1.0,
      // window=1.0 → score=1.0.
      fakeRepo.emit([
        NutritionLog(
          id: '1',
          timestamp: DateTime(2026, 5, 1, 8),
          label: 'Desayuno',
          withinCircadianWindow: true,
        ),
        NutritionLog(
          id: '2',
          timestamp: DateTime(2026, 5, 1, 13),
          label: 'Almuerzo',
          withinCircadianWindow: true,
        ),
        NutritionLog(
          id: '3',
          timestamp: DateTime(2026, 5, 1, 19),
          label: 'Cena',
          withinCircadianWindow: true,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(nutritionProvider);
      expect(state.nutritionScore, closeTo(1.0, 1e-9));
      expect(state.windowAdherence, 1.0);
    });

    test('windowAdherence baja cuando hay logs fuera de ventana', () async {
      await Future<void>.delayed(Duration.zero);
      // 2 dentro + 1 fuera → window=2/3.
      fakeRepo.emit([
        NutritionLog(
          id: '1',
          timestamp: DateTime(2026, 5, 1, 8),
          label: 'Desayuno',
          withinCircadianWindow: true,
        ),
        NutritionLog(
          id: '2',
          timestamp: DateTime(2026, 5, 1, 13),
          label: 'Almuerzo',
          withinCircadianWindow: true,
        ),
        NutritionLog(
          id: '3',
          timestamp: DateTime(2026, 5, 1, 22),
          label: 'Cena',
          withinCircadianWindow: false,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(nutritionProvider);
      expect(state.windowAdherence, closeTo(2 / 3, 1e-9));
    });

    test('resetDaily limpia el cache local sin tocar el repo', () async {
      await Future<void>.delayed(Duration.zero);
      fakeRepo.emit([
        NutritionLog(
          id: 'x',
          timestamp: DateTime(2026, 5, 1, 8),
          label: 'Desayuno',
          withinCircadianWindow: true,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      container.read(nutritionProvider.notifier).resetDaily();

      final state = container.read(nutritionProvider);
      expect(state.todayLogs, isEmpty);
      expect(state.nutritionScore, 0.0);
      // No se invocó repo.removeLastMeal — los logs persisten en Firestore.
      expect(fakeRepo.removeLastCount, 0);
    });
  });
}
