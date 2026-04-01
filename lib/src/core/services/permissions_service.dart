import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_logger.dart';

part 'permissions_service.g.dart';

/// 🔑 PERMISSIONS SERVICE
/// 
/// Centraliza toda la gestión de permisos del SO (iOS/Android).
/// Solicita permisos de forma segura y auditable.
class PermissionsService {
  /// ✅ TASK 1.5.1: Solicitar permiso de notificaciones
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      _logPermissionStatus('Notifications', status);
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Error solicitando permiso de notificaciones: $e');
      return false;
    }
  }

  /// ✅ TASK 1.5.2: Solicitar permiso de calendario
  Future<bool> requestCalendarPermission() async {
    try {
      final status = await Permission.calendar.request();
      _logPermissionStatus('Calendar', status);
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Error solicitando permiso de calendario: $e');
      return false;
    }
  }

  /// ✅ TASK 1.5.3: Solicitar múltiples permisos
  Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      final statuses = await permissions.request();
      for (final entry in statuses.entries) {
        _logPermissionStatus(entry.key.toString(), entry.value);
      }
      return statuses;
    } catch (e) {
      AppLogger.error('Error solicitando múltiples permisos: $e');
      return {};
    }
  }

  /// ✅ TASK 1.5.4: Verificar si un permiso está concedido
  Future<bool> hasPermission(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Error verificando permiso: $e');
      return false;
    }
  }

  /// ✅ TASK 1.5.5: Solicitar permiso y mostrar mensaje si está denegado permanentemente
  Future<bool> requestPermissionWithFallback(
    Permission permission, {
    required String permissionName,
  }) async {
    try {
      final status = await permission.request();
      _logPermissionStatus(permissionName, status);

      if (status.isDenied) {
        AppLogger.warning('El usuario denegó permiso de: $permissionName');
        return false;
      }

      if (status.isPermanentlyDenied) {
        AppLogger.warning(
          'El permiso de $permissionName está permanentemente denegado. '
          'El usuario debe habilitarlo en configuración.',
        );
        return false;
      }

      return status.isGranted;
    } catch (e) {
      AppLogger.error('Error solicitando permiso de $permissionName: $e');
      return false;
    }
  }

  /// ✅ TASK 1.5.6: Abrir configuración de app si permiso está denegado
  Future<bool> openAppSettingsIfNeeded(Permission permission) async {
    try {
      final status = await permission.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        return await openAppSettings();
      }
      return true;
    } catch (e) {
      AppLogger.error('Error abriendo configuración: $e');
      return false;
    }
  }

  /// ✅ HELPER: Log de estado de permisos
  void _logPermissionStatus(String permission, PermissionStatus status) {
    AppLogger.logPermissionEvent(permission, status.isGranted);
    if (status.isDenied) {
      AppLogger.warning('Permiso denegado: $permission');
    } else if (status.isPermanentlyDenied) {
      AppLogger.warning('Permiso PERMANENTEMENTE denegado: $permission');
    }
  }
}

/// 📱 Riverpod Provider para PermissionsService
@riverpod
PermissionsService permissionsService(PermissionsServiceRef ref) {
  return PermissionsService();
}
