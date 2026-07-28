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

import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fake repository ─────────────────────────────────────────────────────────

class FakeNutritionRepository implements NutritionRepository {
  final _logsController = StreamController<List<NutritionLog>>.broadcast();
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

  /// SPEC-149.2: para el fake reutilizamos el mismo controller — los
  /// tests no validan filtrado por ventana, solo el flujo del notifier.
  @override
  Stream<List<NutritionLog>> watchSinceLogs(
    String userId,
    DateTime since, {
    DateTime? until,
  }) =>
      _logsController.stream;

  @override
  Future<void> saveMeal(String userId, NutritionLog log) async {
    savedMeals.add(log);
    final next = [..._today, log];
    emit(next);
  }

  /// SPEC-210: captura el `since` pasado por el notifier.
  DateTime? lastRemoveSince;

  @override
  Future<void> removeLastMeal(String userId, {required DateTime since}) async {
    removeLastCount++;
    lastRemoveSince = since;
    if (_today.isEmpty) return;
    emit(_today.sublist(0, _today.length - 1));
  }

  @override
  Future<void> deleteMealById(String userId, String mealId) async {
    final idx = _today.indexWhere((l) => l.id == mealId);
    if (idx == -1) return;
    final next = [..._today]..removeAt(idx);
    emit(next);
  }

  void dispose() {
    _logsController.close();
  }
}

/// TEST-03 (auditoría pre-producción 2026-07-11): repo cuyo `saveMeal`
/// NUNCA resuelve, replicando el mismo patrón `_HangingSaveRepo` de
/// test/features/metabolic_cycle/application/metabolic_cycle_service_test.dart
/// (SPEC-206) para verificar que logMeal no se cuelga si el dispositivo
/// está offline y el write de Firestore queda pendiente.
class _HangingNutritionRepository implements NutritionRepository {
  final saved = <NutritionLog>[];

  // BUGFIX (2026-07-11): antes usaba `Stream.value(const [])`, que emite
  // una vez y LUEGO COMPLETA. Firestore real (`.snapshots()`) nunca
  // completa por sí solo, pero este stream sí — y el `onDone` de
  // `NutritionNotifier._subscribeFor` re-suscribe incondicionalmente al
  // cerrarse el stream. Resultado real (visto en `flutter test`): loop
  // infinito síncrono subscribe→emit→complete→onDone→resubscribe, que
  // nunca cede el control y cuelga el test suite imprimiendo el mismo par
  // de logs de debug indefinidamente. Ninguno de los dos tests que usan
  // este fake depende de que el stream emita algo — solo verifican que
  // saveMeal/removeLastMeal no bloqueen — así que un stream que nunca
  // emite y nunca completa es suficiente y elimina el loop de raíz.
  // `.broadcast()` — igual que en `FakeNutritionRepository` de arriba —
  // porque `_subscribeFor` puede terminar suscribiéndose más de una vez
  // (listener de usuario + listener de ciclo metabólico, ambos con
  // `fireImmediately: true`); un controller single-subscription lanzaría
  // "Stream has already been listened to" en ese caso.
  // No se cierra A PROPÓSITO: el contrato de este fake es un stream que
  // NUNCA emite y NUNCA completa (ver comentario de arriba). Cerrarlo haría
  // que los listeners recibieran `onDone` y cambiaría justo el escenario que
  // estos tests reproducen. La regla `close_sinks` (activada en la auditoría
  // del 27-jul-2026) lo señala correctamente en general; aquí es el
  // comportamiento buscado.
  // ignore: close_sinks
  final _neverEmits = StreamController<List<NutritionLog>>.broadcast();

  @override
  Stream<List<NutritionLog>> watchTodayLogs(String userId) =>
      _neverEmits.stream;

  @override
  Stream<List<NutritionLog>> watchSinceLogs(
    String userId,
    DateTime since, {
    DateTime? until,
  }) =>
      _neverEmits.stream;

  @override
  Future<void> saveMeal(String userId, NutritionLog log) {
    saved.add(log);
    return Completer<void>().future; // nunca completa
  }

  @override
  Future<void> removeLastMeal(String userId, {required DateTime since}) {
    return Completer<void>().future; // nunca completa
  }

  @override
  Future<void> deleteMealById(String userId, String mealId) {
    return Completer<void>().future; // nunca completa
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
          // BUGFIX (auditoría 2026-07-12): logMeal/removeLastMeal leen
          // fastingProvider (SPEC-251) para la lógica de notificaciones.
          // Sin este override, la cadena real de fastingProvider construye
          // FirebaseAuth.instance/FirebaseFirestore.instance sin que
          // Firebase esté inicializado en flutter_test, lanzando
          // FirebaseException(core/no-app) — Flutter lo reporta como
          // fallo del test aunque los `expect` ya hayan pasado. Mismo
          // patrón ya usado en los grupos SPEC-251/252/253 más abajo.
          fastingProvider.overrideWith(
            (ref) => throw StateError('fastingProvider boom (simulado)'),
          ),
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

    // ── SPEC-210: removeLastMeal cycle-aware ───────────────────────────────────

    test('SPEC-210-01: removeLastMeal pasa since != null al repositorio',
        () async {
      await Future<void>.delayed(Duration.zero);
      await container.read(nutritionProvider.notifier).removeLastMeal();

      expect(fakeRepo.lastRemoveSince, isNotNull,
          reason: 'SPEC-210: since debe pasarse siempre (no null)');
    });

    test(
        'SPEC-210-02: since es >= startOfDay (nunca anterior a medianoche del '
        'día actual si no hay ciclo activo)', () async {
      await Future<void>.delayed(Duration.zero);
      await container.read(nutritionProvider.notifier).removeLastMeal();

      final since = fakeRepo.lastRemoveSince!;
      final startOfToday = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      // Sin ciclo activo el fallback es startOfDay — no puede ser antes.
      expect(
        since.isAfter(startOfToday) || since.isAtSameMomentAs(startOfToday),
        isTrue,
        reason: 'SPEC-210: sin ciclo activo, since debe ser >= startOfDay',
      );
    });

    test(
        'SPEC-210-03: sin logs en el ciclo → removeLastCount=1 pero lista intacta',
        () async {
      await Future<void>.delayed(Duration.zero);
      // No emitimos logs → todayLogs está vacío
      await container.read(nutritionProvider.notifier).removeLastMeal();

      expect(fakeRepo.removeLastCount, 1,
          reason: 'El repo siempre se invoca (sin-op decisión del repo)');
      expect(container.read(nutritionProvider).todayLogs, isEmpty);
    });
  });

  // ── SPEC-251 Fix 1: la persistencia no debe abortarse si falla la lógica de
  // notificaciones (fastingProvider). Antes del fix, logMeal/deleteMealById
  // leían fastingProvider ANTES de invocar al repo — si esa lectura lanzaba,
  // repo.saveMeal/deleteMealById nunca se llamaban aunque el state local
  // optimista ya se hubiera actualizado (pérdida silenciosa de datos). ──────
  group('NutritionNotifier resiliente a fallos en fastingProvider (SPEC-251)',
      () {
    late FakeNutritionRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeNutritionRepository();
      container = ProviderContainer(
        overrides: [
          nutritionRepositoryProvider.overrideWithValue(fakeRepo),
          currentUserStreamProvider
              .overrideWith((ref) => Stream.value(_user())),
          // Simula el mismo tipo de fallo que motivó el fix: leer
          // fastingProvider lanza (p.ej. authRepositoryProvider construye
          // FirebaseAuth.instance sin app inicializada en test).
          fastingProvider.overrideWith(
            (ref) => throw StateError('fastingProvider boom (simulado)'),
          ),
        ],
      );
      container.read(nutritionProvider);
    });

    tearDown(() {
      container.dispose();
      fakeRepo.dispose();
    });

    test('logMeal invoca repo.saveMeal aunque fastingProvider lance excepción',
        () async {
      await Future<void>.delayed(Duration.zero);
      fakeRepo.emit(const []);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(nutritionProvider.notifier)
          .logMeal(label: 'Almuerzo', mealTime: DateTime(2026, 5, 1, 13));

      expect(fakeRepo.savedMeals.length, 1,
          reason: 'SPEC-251 Fix 1: la persistencia debe ocurrir aunque la '
              'lógica de notificaciones (fastingProvider) falle');
      expect(fakeRepo.savedMeals.first.label, 'Almuerzo');
    });

    test(
        'removeLastMeal invoca repo.removeLastMeal aunque fastingProvider '
        'lance excepción', () async {
      await Future<void>.delayed(Duration.zero);
      await container.read(nutritionProvider.notifier).removeLastMeal();

      expect(fakeRepo.removeLastCount, 1,
          reason: 'SPEC-251: removeLastMeal ya despachaba el repo antes de '
              'leer fastingProvider; se cubre aquí por consistencia');
    });

    test(
        'deleteMealById invoca repo.deleteMealById aunque fastingProvider '
        'lance excepción', () async {
      await Future<void>.delayed(Duration.zero);
      final log = NutritionLog(
        id: 'log-del-1',
        timestamp: DateTime(2026, 5, 1, 13),
        label: 'Almuerzo',
        withinCircadianWindow: true,
      );
      fakeRepo.emit([log]);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(nutritionProvider.notifier)
          .deleteMealById('log-del-1');
      await Future<void>.delayed(Duration.zero);

      expect(container.read(nutritionProvider).todayLogs, isEmpty,
          reason: 'SPEC-251 Fix 1: el borrado debe persistir en el repo '
              'aunque la lógica de notificaciones falle');
    });
  });

  // ── SPEC-252: editar una comida (replaceMeal) no debe eliminarla sin
  // guardar la nueva versión. Bug: el intervalo se validaba contra el
  // MISMO log que se estaba reemplazando (delta ≈0 → blocked siempre),
  // y el log viejo ya se había borrado antes de que esa validación
  // corriera. Ver causa raíz completa en el docstring de `replaceMeal`. ──
  group('NutritionNotifier.replaceMeal (SPEC-252)', () {
    late FakeNutritionRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeNutritionRepository();
      container = ProviderContainer(
        overrides: [
          nutritionRepositoryProvider.overrideWithValue(fakeRepo),
          currentUserStreamProvider
              .overrideWith((ref) => Stream.value(_user())),
          fastingProvider.overrideWith(
            (ref) => throw StateError('fastingProvider boom (simulado)'),
          ),
        ],
      );
      container.read(nutritionProvider);
    });

    tearDown(() {
      container.dispose();
      fakeRepo.dispose();
    });

    test(
        'replaceMeal guarda la nueva versión aunque el horario coincida '
        'con el del log original (antes: MealTooSoonException contra sí '
        'mismo y pérdida del dato)', () async {
      await Future<void>.delayed(Duration.zero);
      final original = NutritionLog(
        id: 'log-original',
        timestamp: DateTime(2026, 5, 1, 13, 0),
        label: 'Almuerzo',
        withinCircadianWindow: true,
      );
      fakeRepo.emit([original]);
      await Future<void>.delayed(Duration.zero);

      await container.read(nutritionProvider.notifier).replaceMeal(
            oldId: 'log-original',
            label: 'Almuerzo',
            // Mismo timestamp que el original — antes de SPEC-252 esto
            // disparaba MealTooSoonException al comparar contra sí mismo.
            mealTime: DateTime(2026, 5, 1, 13, 0),
          );
      await Future<void>.delayed(Duration.zero);

      expect(fakeRepo.savedMeals.length, 1,
          reason: 'SPEC-252: la nueva versión debe guardarse aunque su '
              'horario coincida con el del log que reemplaza');
      final logs = container.read(nutritionProvider).todayLogs;
      expect(logs.length, 1,
          reason: 'no debe quedar en 0 (dato perdido) ni en 2 (duplicado)');
      expect(logs.first.id, isNot('log-original'),
          reason: 'el log viejo debe haberse eliminado');
    });

    test(
        'replaceMeal preserva el log original si logMeal falla por chocar '
        'con OTRA comida real (no la que se está reemplazando)', () async {
      await Future<void>.delayed(Duration.zero);
      final earlier = NutritionLog(
        id: 'log-desayuno',
        timestamp: DateTime(2026, 5, 1, 8, 0),
        label: 'Desayuno',
        withinCircadianWindow: true,
      );
      final original = NutritionLog(
        id: 'log-original',
        timestamp: DateTime(2026, 5, 1, 13, 0),
        label: 'Almuerzo',
        withinCircadianWindow: true,
      );
      fakeRepo.emit([earlier, original]);
      await Future<void>.delayed(Duration.zero);

      // Editar el log 'log-original' pero moviendo su hora a 8:10 — a
      // <2h de 'log-desayuno' (una comida DISTINTA, no la que se edita).
      // Este bloqueo es un comportamiento correcto y debe preservarse.
      await expectLater(
        container.read(nutritionProvider.notifier).replaceMeal(
              oldId: 'log-original',
              label: 'Almuerzo',
              mealTime: DateTime(2026, 5, 1, 8, 10),
            ),
        throwsA(isA<MealTooSoonException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(fakeRepo.savedMeals, isEmpty,
          reason: 'no debe haberse guardado ninguna versión nueva');
      final logs = container.read(nutritionProvider).todayLogs;
      expect(logs.map((l) => l.id), contains('log-original'),
          reason: 'SPEC-252: el log original NO debe perderse cuando '
              'logMeal falla por un choque real con otra comida');
    });
  });

  // ── SPEC-253: guardia definitiva contra pérdida silenciosa de datos.
  // Carlos reportó (2026-07-08) que registrar o editar una comida hacía
  // desaparecer OTRA comida ya visible, incluso tras reiniciar la app —
  // sin usar "Editar" (descartando SPEC-252 como causa) y sin que el
  // usuario pidiera borrar nada. La causa exacta (listener/caché de
  // Firestore) no se pudo confirmar con certeza, así que se blindó el
  // notifier: un log que el usuario vio en pantalla nunca desaparece de
  // la vista salvo que el propio notifier haya pedido borrarlo. ─────────
  group('NutritionNotifier guardia anti-pérdida-de-datos (SPEC-253)', () {
    late FakeNutritionRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeNutritionRepository();
      container = ProviderContainer(
        overrides: [
          nutritionRepositoryProvider.overrideWithValue(fakeRepo),
          currentUserStreamProvider
              .overrideWith((ref) => Stream.value(_user())),
          fastingProvider.overrideWith(
            (ref) => throw StateError('fastingProvider boom (simulado)'),
          ),
        ],
      );
      container.read(nutritionProvider);
    });

    tearDown(() {
      container.dispose();
      fakeRepo.dispose();
    });

    test(
        'si un snapshot posterior omite un log sin que el usuario lo haya '
        'borrado, el log se preserva en el state (no desaparece solo)',
        () async {
      await Future<void>.delayed(Duration.zero);
      final desayuno = NutritionLog(
        id: 'log-desayuno',
        timestamp: DateTime(2026, 5, 1, 8, 0),
        label: 'Desayuno',
        withinCircadianWindow: true,
      );
      final almuerzo = NutritionLog(
        id: 'log-almuerzo',
        timestamp: DateTime(2026, 5, 1, 13, 0),
        label: 'Almuerzo',
        withinCircadianWindow: true,
      );
      // Snapshot 1: ambas comidas visibles (como en el reporte de Carlos
      // tras registrar el desayuno).
      fakeRepo.emit([desayuno, almuerzo]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(nutritionProvider).todayLogs.length, 2);

      // Snapshot 2: Firestore (por la razón que sea — la anomalía que
      // reportó Carlos) deja de incluir el desayuno, SIN que el notifier
      // haya pedido borrarlo. Simulamos esto emitiendo directamente desde
      // el fake, sin pasar por deleteMealById/removeLastMeal/replaceMeal.
      fakeRepo.emit([almuerzo]);
      await Future<void>.delayed(Duration.zero);

      final logs = container.read(nutritionProvider).todayLogs;
      expect(logs.map((l) => l.id), contains('log-desayuno'),
          reason: 'SPEC-253: un log que el usuario vio no debe '
              'desaparecer solo — la guardia debe preservarlo');
      expect(logs.map((l) => l.id), contains('log-almuerzo'));
      expect(logs.length, 2);
    });

    test(
        'un borrado explícito (deleteMealById) sí reduce la lista — la '
        'guardia no resucita logs que el usuario pidió eliminar', () async {
      await Future<void>.delayed(Duration.zero);
      final desayuno = NutritionLog(
        id: 'log-desayuno',
        timestamp: DateTime(2026, 5, 1, 8, 0),
        label: 'Desayuno',
        withinCircadianWindow: true,
      );
      final almuerzo = NutritionLog(
        id: 'log-almuerzo',
        timestamp: DateTime(2026, 5, 1, 13, 0),
        label: 'Almuerzo',
        withinCircadianWindow: true,
      );
      fakeRepo.emit([desayuno, almuerzo]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(nutritionProvider).todayLogs.length, 2);

      await container
          .read(nutritionProvider.notifier)
          .deleteMealById('log-desayuno');
      await Future<void>.delayed(Duration.zero);

      final logs = container.read(nutritionProvider).todayLogs;
      expect(logs.map((l) => l.id), isNot(contains('log-desayuno')),
          reason: 'SPEC-253: un borrado explícito SÍ debe reflejarse — '
              'la guardia solo protege contra desapariciones no pedidas');
      expect(logs.map((l) => l.id), contains('log-almuerzo'));
      expect(logs.length, 1);
    });

    test(
        'removeLastMeal marca el último log como explícitamente '
        'eliminado — la guardia no lo preserva', () async {
      await Future<void>.delayed(Duration.zero);
      final desayuno = NutritionLog(
        id: 'log-desayuno',
        timestamp: DateTime(2026, 5, 1, 8, 0),
        label: 'Desayuno',
        withinCircadianWindow: true,
      );
      final almuerzo = NutritionLog(
        id: 'log-almuerzo',
        timestamp: DateTime(2026, 5, 1, 13, 0),
        label: 'Almuerzo',
        withinCircadianWindow: true,
      );
      fakeRepo.emit([desayuno, almuerzo]);
      await Future<void>.delayed(Duration.zero);

      await container.read(nutritionProvider.notifier).removeLastMeal();
      await Future<void>.delayed(Duration.zero);

      final logs = container.read(nutritionProvider).todayLogs;
      expect(logs.map((l) => l.id), isNot(contains('log-almuerzo')),
          reason: 'removeLastMeal debe borrar el más reciente '
              '(almuerzo) y la guardia no debe resucitarlo');
    });
  });

  // ── TEST-03 (auditoría 2026-07-11): SPEC-206 offline-first ──────────────
  group('NutritionNotifier — SPEC-206 offline-first (write no bloqueante)', () {
    late _HangingNutritionRepository hangingRepo;
    late ProviderContainer container;

    setUp(() {
      hangingRepo = _HangingNutritionRepository();
      container = ProviderContainer(
        overrides: [
          nutritionRepositoryProvider.overrideWithValue(hangingRepo),
          currentUserStreamProvider
              .overrideWith((ref) => Stream.value(_user())),
          fastingProvider.overrideWith(
            (ref) => throw StateError('fastingProvider boom (simulado)'),
          ),
        ],
      );
      container.read(nutritionProvider);
    });

    tearDown(() => container.dispose());

    test(
        'logMeal con repo colgado (offline) no bloquea — retorna dentro '
        'del timeout', () async {
      await Future<void>.delayed(Duration.zero);

      await container
          .read(nutritionProvider.notifier)
          .logMeal(label: 'Almuerzo', mealTime: DateTime(2026, 5, 1, 13))
          .timeout(const Duration(seconds: 2));

      expect(hangingRepo.saved.length, 1,
          reason: 'el write se intentó (quedó pendiente en la caché) '
              'aunque el Future del server nunca resuelva');
    });

    test(
        'removeLastMeal con repo colgado no bloquea — retorna dentro '
        'del timeout', () async {
      await Future<void>.delayed(Duration.zero);

      await container
          .read(nutritionProvider.notifier)
          .removeLastMeal()
          .timeout(const Duration(seconds: 2));
    });
  });
}
