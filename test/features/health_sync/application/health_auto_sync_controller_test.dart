// TEST-06 (auditoría 2026-07-11): tests del debounce de
// HealthAutoSyncController (SPEC-132 Bloque C).
//
// El controller usa `_kMinSyncInterval` (15 min) comparando un reloj
// inyectable (`now`, default `DateTime.now`) contra `state.lastRunAt`.
// Estos tests inyectan un reloj controlado (`_FakeClock`) para verificar
// el debounce sin depender del reloj de pared real.
//
// Fakes: `_FakeHealthSyncService` y `_FakeHealthImportService`
// implementan las clases concretas (no hay interfaz en domain/ para
// ellas todavía) — mismo patrón que `_FakeSleepRepository` en
// `health_import_service_test.dart` (implements + overrides mínimos).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/health_sync/application/health_auto_sync_controller.dart';
import 'package:elena_app/src/features/health_sync/application/health_import_service.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_service.dart';
import 'package:elena_app/src/features/health_sync/application/samsung_health_service.dart'
    as samsung_health;
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';

/// Reloj mutable para controlar `now()` desde el test.
class _FakeClock {
  DateTime value;
  _FakeClock(this.value);
  DateTime call() => value;
}

class _FakeHealthSyncService implements HealthSyncService {
  int syncCalls = 0;
  HealthPermissionStatus permission = const HealthPermissionGranted();

  @override
  bool get isPlatformSupported => true;

  @override
  Future<HealthPermissionStatus> checkPermissions() async => permission;

  @override
  Future<HealthPermissionStatus> requestAuthorization() async => permission;

  @override
  Future<void> openHealthConnectInstall() async {}

  @override
  Future<void> openHealthConnectSettings() async {}

  @override
  Future<HealthSyncResult> sync({
    Duration window = const Duration(days: 7),
    DateTime? now,
  }) async {
    syncCalls++;
    final end = now ?? DateTime.now();
    final start = end.subtract(window);
    // Vacío a propósito: sin samples, `_runNow` no dispara import ni
    // las ramas de Samsung Health — mantiene el test enfocado en el
    // debounce, no en el pipeline de importación (ya cubierto en
    // health_import_service_test.dart).
    return HealthSyncResult(
      windowStart: start,
      windowEnd: end,
      samplesByMetric: const {},
      errors: const {},
      completedAt: end,
    );
  }
}

class _FakeHealthImportService implements HealthImportService {
  int importCalls = 0;

  @override
  Future<HealthImportSummary> importResult(
    String userId,
    HealthSyncResult result,
  ) async {
    importCalls++;
    return const HealthImportSummary();
  }

  @override
  Future<int> importSamsungSleep(
    String userId,
    List<samsung_health.SamsungSleepSession> sessions,
  ) async =>
      0;
}

void main() {
  late ProviderContainer container;
  late Ref ref;
  late _FakeClock clock;
  late _FakeHealthSyncService syncService;
  late _FakeHealthImportService importService;
  late HealthAutoSyncController controller;

  setUp(() {
    container = ProviderContainer();
    ref = container.read(Provider<Ref>((r) => r));
    clock = _FakeClock(DateTime(2026, 1, 1, 12, 0));
    syncService = _FakeHealthSyncService();
    importService = _FakeHealthImportService();
    controller = HealthAutoSyncController(
      syncService: syncService,
      importService: importService,
      ref: ref,
      now: clock.call,
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('runIfDue no sincroniza si el último run fue hace menos de 15 min',
      () async {
    // Primer run — sin lastRunAt previo, siempre corre.
    await controller.runIfDue(userId: 'user-1');
    expect(syncService.syncCalls, 1);

    // Avanza el reloj 10 min (< _kMinSyncInterval de 15 min).
    clock.value = clock.value.add(const Duration(minutes: 10));
    await controller.runIfDue(userId: 'user-1');

    expect(syncService.syncCalls, 1, reason: 'debounce debe bloquear el 2do run');
  });

  test('runIfDue sí sincroniza tras pasar 15 min', () async {
    await controller.runIfDue(userId: 'user-1');
    expect(syncService.syncCalls, 1);

    // Avanza el reloj 16 min (> _kMinSyncInterval de 15 min).
    clock.value = clock.value.add(const Duration(minutes: 16));
    await controller.runIfDue(userId: 'user-1');

    expect(syncService.syncCalls, 2, reason: 'tras 15 min el debounce debe liberar');
  });

  test('runNow ignora el debounce aunque el último run haya sido hace segundos',
      () async {
    await controller.runIfDue(userId: 'user-1');
    expect(syncService.syncCalls, 1);

    // Sin avanzar el reloj — runNow debe correr igual (botón manual).
    await controller.runNow(userId: 'user-1');

    expect(syncService.syncCalls, 2, reason: 'runNow no debe respetar el debounce');
  });
}
