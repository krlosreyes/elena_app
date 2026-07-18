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

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/dashboard/data/sleep_repository_impl.dart';
import 'package:elena_app/src/features/exercise/data/exercise_repository_impl.dart';
import 'package:elena_app/src/features/health_sync/application/health_import_service.dart';
import 'package:elena_app/src/features/health_sync/application/samsung_health_service.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_providers.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_service.dart';
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';

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

  /// SPEC-237: Android — sync completó con permisos OK pero 0 datos de
  /// sueño/ejercicio. Señal de que Samsung Health no está configurado para
  /// compartir con Health Connect. La UI muestra una guía específica.
  final bool needsSamsungHealthGuide;

  const HealthAutoSyncState({
    this.permissionStatus,
    this.lastResult,
    this.lastImport,
    this.isRunning = false,
    this.lastRunAt,
    this.needsSamsungHealthGuide = false,
  });

  HealthAutoSyncState copyWith({
    HealthPermissionStatus? permissionStatus,
    HealthSyncResult? lastResult,
    HealthImportSummary? lastImport,
    bool? isRunning,
    DateTime? lastRunAt,
    bool? needsSamsungHealthGuide,
  }) {
    return HealthAutoSyncState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      lastResult: lastResult ?? this.lastResult,
      lastImport: lastImport ?? this.lastImport,
      isRunning: isRunning ?? this.isRunning,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      needsSamsungHealthGuide:
          needsSamsungHealthGuide ?? this.needsSamsungHealthGuide,
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

  /// TEST-06 (auditoría 2026-07-11): reloj inyectable. Default
  /// `DateTime.now` preserva el comportamiento real en el único sitio
  /// donde se instancia el controller (provider al final de este
  /// archivo). Permite testear el debounce de `runIfDue` sin depender
  /// del reloj de pared.
  final DateTime Function() _now;

  HealthAutoSyncController({
    required HealthSyncService syncService,
    required HealthImportService importService,
    required Ref ref,
    DateTime Function() now = DateTime.now,
  })  : _syncService = syncService,
        _importService = importService,
        _ref = ref,
        _now = now,
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
        _now().difference(state.lastRunAt!) < _kMinSyncInterval) {
      AppLogger.debug(
        'HealthAutoSync: skip — última corrida hace '
        '${_now().difference(state.lastRunAt!).inMinutes} min',
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
    // ARCH-02 (auditoría 2026-07-11): estos print() de diagnóstico ya
    // estaban gateados por kDebugMode (no llegaban a release), pero
    // duplicaban información que AppLogger ya registra. Se consolidan en
    // AppLogger.debug (gateado igual, sin userId en el mensaje) para
    // evitar logging duplicado y el patrón `// ignore: avoid_print`.
    AppLogger.debug('HealthAutoSync: sync start');
    state = state.copyWith(isRunning: true);
    _ref.read(isHealthSyncingProvider.notifier).state = true;

    try {
      // 1. Permisos.
      final perm = await _syncService.checkPermissions();
      state = state.copyWith(permissionStatus: perm);
      _ref.read(healthPermissionStatusProvider.notifier).state = perm;
      AppLogger.debug('HealthAutoSync: permisos=${perm.runtimeType}');

      // SPEC-237: también sincronizamos si hay permisos PARCIALES.
      // En Android, si WORKOUT fue denegado pero SLEEP/STEPS están concedidos,
      // checkPermissions() retorna HealthPermissionPartial. El sync corre igual;
      // _fetchMetric omite silenciosamente los tipos sin permiso.
      final canSync =
          perm is HealthPermissionGranted || perm is HealthPermissionPartial;
      if (!canSync) {
        AppLogger.debug(
          'HealthAutoSync: sin permisos (${perm.runtimeType}), '
          'no se sincroniza',
        );
        return;
      }

      // 2. Sync.
      final result = await _syncService.sync(window: _kDefaultSyncWindow);
      state = state.copyWith(lastResult: result);
      _ref.read(lastHealthSyncResultProvider.notifier).state = result;
      AppLogger.info('HealthAutoSync: sync ok — $result');

      // 3. Import (solo si hubo datos).
      if (!result.isEmpty) {
        final summary = await _importService.importResult(userId, result);
        state = state.copyWith(lastImport: summary);
        AppLogger.info('HealthAutoSync: import ok — $summary');

        // NOTA: NO propagamos el peso de AH al doc canónico users/{uid}.weight.
        // El peso canónico lo controla el usuario (onboarding o edición manual en
        // Perfil). Apple Health alimenta solo biometric_history (gráficas).
        // Propagar AH sobreescribiría el peso que el usuario introdujo manualmente
        // con datos históricos de AH, corrompiendo la recomendación de meta de peso.
      } else {
        AppLogger.info('HealthAutoSync: nada que importar');
      }

      // SPEC-239: fallback Samsung Health SDK cuando HC no tiene sueño.
      // Solo Android. No bloquea el ciclo si falla.
      final isAndroidForSH = !kIsWeb && Platform.isAndroid;
      if (isAndroidForSH) {
        final importSummary = state.lastImport;
        final noSleepFromHC = importSummary == null ||
            importSummary.sleepSessionsImported == 0;
        if (noSleepFromHC) {
          AppLogger.debug(
            'HealthAutoSync: HC sin sueño → intentando Samsung Health SDK directo',
          );
          try {
            final shService = SamsungHealthService();
            final window = _kDefaultSyncWindow;
            final shSessions = await shService.fetchSleepIfAvailable(
              start: DateTime.now().subtract(window),
              end: DateTime.now(),
            );
            if (shSessions.isNotEmpty) {
              final shImported =
                  await _importService.importSamsungSleep(userId, shSessions);
              if (shImported > 0) {
                // Actualiza el summary para que la UI y la guía reflejen
                // que ahora sí hay datos de sueño.
                final updated = HealthImportSummary(
                  weightsImported: importSummary?.weightsImported ?? 0,
                  sleepSessionsImported:
                      (importSummary?.sleepSessionsImported ?? 0) + shImported,
                  stepsActivitiesImported:
                      importSummary?.stepsActivitiesImported ?? 0,
                  workoutsImported: importSummary?.workoutsImported ?? 0,
                );
                state = state.copyWith(lastImport: updated);
                AppLogger.debug(
                  'HealthAutoSync: SH SDK: $shImported sesiones importadas OK',
                );
              }
            }
          } catch (e) {
            AppLogger.warning('SamsungHealth SDK fallback falló: $e');
          }
        }
      }

      // SPEC-237: en Android, mostrar guía Samsung Health si no entraron
      // datos de SUEÑO. Steps pueden sincronizar vía Health Connect nativo
      // pero el reloj Samsung requiere configuración explícita para sueño.
      // Condición: Android + permisos OK + 0 sesiones de sueño importadas.
      // No usamos result.isEmpty porque steps puede tener datos aunque
      // sueño esté vacío (exactamente el caso Samsung Galaxy Watch).
      final isAndroid = !kIsWeb && Platform.isAndroid;
      if (isAndroid && canSync) {
        // Leemos el lastImport del state (que ya fue actualizado arriba).
        final importSummary = state.lastImport;
        final noSleepImported = importSummary == null ||
            importSummary.sleepSessionsImported == 0;
        if (noSleepImported) {
          state = state.copyWith(needsSamsungHealthGuide: true);
          AppLogger.debug('HealthAutoSync: sueño=0, mostrando guía HC');
        } else {
          // Sueño importó correctamente → ocultar guía si estaba visible.
          state = state.copyWith(needsSamsungHealthGuide: false);
        }
      }
    } catch (e, st) {
      AppLogger.error('HealthAutoSync: ciclo falló', e, st);
    } finally {
      // TEST-06: usa el reloj inyectado — este timestamp es el que
      // `runIfDue` compara en la próxima corrida, así que debe venir de
      // la misma fuente que la comparación para que el debounce sea
      // testeable de punta a punta.
      state = state.copyWith(
        isRunning: false,
        lastRunAt: _now(),
      );
      _ref.read(isHealthSyncingProvider.notifier).state = false;
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
