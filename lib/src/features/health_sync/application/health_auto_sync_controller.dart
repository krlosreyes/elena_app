// SPEC-132 — Bloque C: orquesta el flujo end-to-end de auto-sync.
//
// Responsabilidades:
//   1. Chequear permisos al startup (sin solicitar — eso lo hace el
//      onboarding en Bloque E o el botón manual en Bloque D).
//   2. Disparar sync + import si hay permisos.
//   3. Debouncing: no re-sync más seguido que cada `minInterval`
//      (default 15 min) — evita martillar HealthKit cuando el usuario
//      abre/cierra la app rápido.
//   4. Exponer el estado actual al árbol Riverpod para la UI.
//
// Diseño:
//   - StateNotifier — pattern del repo (sleep, fasting, etc.).
//   - No se auto-construye: el caller (root widget de la app) llama
//     `runIfDue()` cuando es seguro hacerlo (auth ready, etc.).
//   - Persistencia del lastRunAt en memoria. Si la app se cierra,
//     el debounce se resetea — aceptable porque sync es barato.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/dashboard/data/sleep_repository_impl.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart';
import 'package:elena_app/src/features/health_sync/application/health_import_service.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_providers.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_service.dart';
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Snapshot público del estado del controller. La UI lo consume para
/// mostrar badges ("Sincronizando", "Última sync", "Permisos
/// pendientes").
class HealthAutoSyncState {
  /// Estado actual de permisos. `null` antes del primer check.
  final HealthPermissionStatus? permissionStatus;

  /// Última sync exitosa (o con errores parciales). `null` si nunca
  /// se corrió.
  final HealthSyncResult? lastResult;

  /// Resumen del último import. `null` si nunca se corrió.
  final HealthImportSummary? lastImport;

  /// `true` durante el ciclo sync+import.
  final bool isRunning;

  /// Timestamp del último run completado (exitoso o no). Driver del
  /// debouncing.
  final DateTime? lastRunAt;

  const HealthAutoSyncState({
    this.permissionStatus,
    this.lastResult,
    this.lastImport,
    this.isRunning = false,
    this.lastRunAt,
  });

  HealthAutoSyncState copyWith({
    HealthPermissionStatus? permissionStatus,
    HealthSyncResult? lastResult,
    HealthImportSummary? lastImport,
    bool? isRunning,
    DateTime? lastRunAt,
  }) {
    return HealthAutoSyncState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      lastResult: lastResult ?? this.lastResult,
      lastImport: lastImport ?? this.lastImport,
      isRunning: isRunning ?? this.isRunning,
      lastRunAt: lastRunAt ?? this.lastRunAt,
    );
  }
}

/// Intervalo mínimo entre syncs automáticos. 15 min es suficiente:
/// HealthKit / Health Connect raramente cambian valores a alta
/// frecuencia (el usuario no se pesa cada 5 min).
const Duration _kMinSyncInterval = Duration(minutes: 15);

/// Ventana por defecto que pide cada sync. 7 días cubre el caso de
/// un usuario que estuvo offline una semana sin saturar el plugin.
const Duration _kDefaultSyncWindow = Duration(days: 7);

class HealthAutoSyncController extends StateNotifier<HealthAutoSyncState> {
  final HealthSyncService _syncService;
  final HealthImportService _importService;
  final Ref _ref;

  HealthAutoSyncController({
    required HealthSyncService syncService,
    required HealthImportService importService,
    required Ref ref,
  })  : _syncService = syncService,
        _importService = importService,
        _ref = ref,
        super(const HealthAutoSyncState());

  // ─── API pública ─────────────────────────────────────────────────

  /// Punto de entrada principal del auto-sync. Idempotente y
  /// debounced: si pasó menos de `_kMinSyncInterval` desde el último
  /// run, retorna sin hacer nada.
  ///
  /// `userId` requerido — si es null/empty, abortamos (no hay donde
  /// persistir).
  Future<void> runIfDue({required String? userId}) async {
    if (userId == null || userId.isEmpty) {
      AppLogger.debug('HealthAutoSync: skip — userId vacío');
      return;
    }
    if (state.isRunning) {
      AppLogger.debug('HealthAutoSync: skip — ya está corriendo');
      return;
    }
    if (state.lastRunAt != null &&
        DateTime.now().difference(state.lastRunAt!) < _kMinSyncInterval) {
      AppLogger.debug(
        'HealthAutoSync: skip — última corrida hace '
        '${DateTime.now().difference(state.lastRunAt!).inMinutes} min',
      );
      return;
    }

    await _runNow(userId: userId);
  }

  /// Fuerza un sync ignorando el debounce (botón manual de Bloque D).
  Future<void> runNow({required String? userId}) async {
    if (userId == null || userId.isEmpty) return;
    if (state.isRunning) return;
    await _runNow(userId: userId);
  }

  /// Consulta permisos y actualiza el estado (sin disparar sync).
  /// Útil para que la UI sepa si mostrar "Conectar Apple Health".
  Future<void> refreshPermissionStatus() async {
    final status = await _syncService.checkPermissions();
    state = state.copyWith(permissionStatus: status);
    _ref.read(healthPermissionStatusProvider.notifier).state = status;
  }

  /// Solicita autorización al usuario. Lanza el sheet nativo de iOS
  /// o la UI de Health Connect en Android.
  Future<HealthPermissionStatus> requestAuthorization() async {
    final result = await _syncService.requestAuthorization();
    state = state.copyWith(permissionStatus: result);
    _ref.read(healthPermissionStatusProvider.notifier).state = result;
    return result;
  }

  // ─── Implementación ──────────────────────────────────────────────

  Future<void> _runNow({required String userId}) async {
    // SPEC-173.bugfix2: prints directos con marcador único 🩺 para que
    // aparezcan en Console.app del iPhone aunque AppLogger esté
    // strippeado en release builds optimizados.
    // ignore: avoid_print
    print('🩺 SYNC START userId=$userId');
    state = state.copyWith(isRunning: true);
    _ref.read(isHealthSyncingProvider.notifier).state = true;

    try {
      // 1. Permisos.
      final perm = await _syncService.checkPermissions();
      state = state.copyWith(permissionStatus: perm);
      _ref.read(healthPermissionStatusProvider.notifier).state = perm;
      // ignore: avoid_print
      print('🩺 SYNC permisos=${perm.runtimeType}');

      if (perm is! HealthPermissionGranted) {
        AppLogger.debug(
          'HealthAutoSync: sin permisos (${perm.runtimeType}), '
          'no se sincroniza',
        );
        // ignore: avoid_print
        print('🩺 SYNC ABORT — sin permisos');
        return;
      }

      // 2. Sync.
      final result = await _syncService.sync(window: _kDefaultSyncWindow);
      state = state.copyWith(lastResult: result);
      _ref.read(lastHealthSyncResultProvider.notifier).state = result;
      AppLogger.info('HealthAutoSync: sync ok — $result');
      // ignore: avoid_print
      print('🩺 SYNC RESULT $result');

      // 3. Import (solo si hubo datos).
      if (!result.isEmpty) {
        final summary = await _importService.importResult(userId, result);
        state = state.copyWith(lastImport: summary);
        AppLogger.info('HealthAutoSync: import ok — $summary');
        // ignore: avoid_print
        print('🩺 SYNC IMPORTED $summary');

        // BUGFIX coherencia (2026-06-07): _importWeights escribe el peso en
        // biometric_history (gráfica de Análisis) pero NO en users/{uid}.weight,
        // que es lo que lee la card de Perfil. Propagamos el peso más reciente
        // al doc canónico para que ambas vistas coincidan.
        if (summary.weightsImported > 0) {
          await _syncCanonicalWeight(userId);
        }
      } else {
        AppLogger.info('HealthAutoSync: nada que importar');
        // ignore: avoid_print
        print('🩺 SYNC EMPTY — nada que importar');
      }
    } catch (e, st) {
      AppLogger.error('HealthAutoSync: ciclo falló', e, st);
      // ignore: avoid_print
      print('🩺 SYNC ERROR $e');
      // ignore: avoid_print
      print(st);
    } finally {
      state = state.copyWith(
        isRunning: false,
        lastRunAt: DateTime.now(),
      );
      _ref.read(isHealthSyncingProvider.notifier).state = false;
    }
  }

  /// Propaga el peso más reciente de `biometric_history` al doc canónico
  /// `users/{uid}.weight` (que lee la card de Perfil). Nunca rompe el sync:
  /// cualquier fallo se loguea y se ignora.
  Future<void> _syncCanonicalWeight(String userId) async {
    try {
      final latest =
          await _ref.read(biometricRepositoryProvider).fetchLatest(userId);
      final user = _ref.read(currentUserStreamProvider).valueOrNull;
      final w = latest?.weight;
      if (latest == null || user == null || w == null) return;
      if (user.weight == w) return; // ya coincide
      await _ref
          .read(userProfileRepositoryProvider)
          .saveProfile(user.copyWith(weight: w));
      AppLogger.info('HealthAutoSync: peso canónico actualizado a $w kg');
    } catch (e) {
      AppLogger.warning(
        'HealthAutoSync: no se pudo sincronizar el peso canónico: $e',
      );
    }
  }
}

// ─── Providers ───────────────────────────────────────────────────────

/// Singleton del ImportService.
final healthImportServiceProvider = Provider<HealthImportService>((ref) {
  return HealthImportService(
    biometricRepository: ref.read(biometricRepositoryProvider),
    sleepRepository: ref.read(sleepRepositoryProvider),
    exerciseRepository: ref.read(exerciseRepositoryProvider),
  );
});

/// Controller del auto-sync. La UI lo consume con `ref.watch` para
/// reaccionar al estado; el root widget lo invoca con `ref.read` para
/// disparar el `runIfDue()` al startup.
final healthAutoSyncControllerProvider =
    StateNotifierProvider<HealthAutoSyncController, HealthAutoSyncState>(
  (ref) {
    return HealthAutoSyncController(
      syncService: ref.read(healthSyncServiceProvider),
      importService: ref.read(healthImportServiceProvider),
      ref: ref,
    );
  },
);
