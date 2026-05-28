// SPEC-132: estado de permisos del proveedor nativo de salud.
// Modelado como sealed class para que el caller pueda hacer pattern
// matching exhaustivo en la UI.

import 'health_metric.dart';

/// Resultado de una consulta de estado de permisos.
sealed class HealthPermissionStatus {
  const HealthPermissionStatus();
}

/// Todos los permisos solicitados están concedidos.
class HealthPermissionGranted extends HealthPermissionStatus {
  const HealthPermissionGranted();
}

/// El usuario aceptó algunos permisos pero rechazó otros, o solo
/// concedió algunas métricas.
class HealthPermissionPartial extends HealthPermissionStatus {
  final List<HealthMetric> granted;
  final List<HealthMetric> denied;

  const HealthPermissionPartial({
    required this.granted,
    required this.denied,
  });
}

/// El usuario rechazó explícitamente (o nunca pidió) los permisos.
class HealthPermissionDenied extends HealthPermissionStatus {
  const HealthPermissionDenied();
}

/// El plugin no está disponible en esta plataforma (Web, Linux, etc.)
/// o falló el handshake con el proveedor nativo. La UI debería
/// degradar a captura manual sin mostrar el módulo de sync.
class HealthPermissionUnavailable extends HealthPermissionStatus {
  /// Motivo opcional para logs.
  final String? reason;

  const HealthPermissionUnavailable({this.reason});
}

/// En Android: Health Connect no está instalado en el device. La UI
/// debería ofrecer un botón "Instalar Health Connect" que abra el
/// Play Store en el paquete `com.google.android.apps.healthdata`.
class HealthConnectNotInstalled extends HealthPermissionStatus {
  const HealthConnectNotInstalled();
}
