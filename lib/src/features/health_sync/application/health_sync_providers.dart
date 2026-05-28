// SPEC-132: providers Riverpod para el flujo de health-sync.
//
// El servicio en sí es singleton (no tiene state mutable más allá del
// flag `_configured`). Los notifiers que dependan de él lo van a
// inyectar a través de `healthSyncServiceProvider`.
//
// `lastSyncResultProvider` mantiene el último resultado para que la
// UI pueda mostrar badges de "Última sync: hace X min" sin volver a
// pegarle al plugin.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/health_sync/application/health_sync_service.dart';
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sync_result.dart';

/// Singleton del servicio. Inyectable por tests vía override.
final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService();
});

/// Estado del último permiso conocido. Empieza como `null`
/// (indeterminado); se actualiza al consultar `checkPermissions()`.
final healthPermissionStatusProvider =
    StateProvider<HealthPermissionStatus?>((ref) => null);

/// Último resultado de sync exitoso. `null` antes de la primera sync.
/// Usado por la UI para mostrar:
///  - "Sincronizando..." mientras corre
///  - "Última sync: hace 5 min" cuando terminó
///  - "Error al sincronizar X" cuando falló parcialmente.
final lastHealthSyncResultProvider =
    StateProvider<HealthSyncResult?>((ref) => null);

/// Flag de "estoy sincronizando ahora mismo" — evita disparar 2 syncs
/// concurrentes (por ejemplo, si el usuario toca el botón manual
/// mientras el auto-sync de Bloque C está corriendo).
final isHealthSyncingProvider = StateProvider<bool>((ref) => false);
