// SPEC-196 — interfaz abstracta de cobro (provider-agnostic).
//
// El resto de la app depende SOLO de esta interfaz, nunca de purchases_flutter.
// Implementaciones:
//   - FreeBillingService (lib): default seguro "todo Free" mientras el cobro
//     no está habilitado o no hay keys.
//   - RevenueCatBillingService (data, SPEC-196 inc2): impl real con el SDK.
//   - FakeBillingService (test): simula compras sin red.

import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

/// Resultado de un intento de compra/restauración.
enum PurchaseOutcome { success, cancelled, error }

class PurchaseResult {
  const PurchaseResult._(this.outcome, this.status, this.errorMessage);

  factory PurchaseResult.success(EntitlementStatus status) =>
      PurchaseResult._(PurchaseOutcome.success, status, null);

  /// El usuario canceló el diálogo de compra. NO es un error.
  factory PurchaseResult.cancelled() =>
      const PurchaseResult._(PurchaseOutcome.cancelled, null, null);

  factory PurchaseResult.error(String message) =>
      PurchaseResult._(PurchaseOutcome.error, null, message);

  final PurchaseOutcome outcome;

  /// Estado resultante (solo en success).
  final EntitlementStatus? status;

  /// Mensaje legible (solo en error).
  final String? errorMessage;

  bool get isSuccess => outcome == PurchaseOutcome.success;
}

/// Capa de cobro. Las implementaciones NUNCA propagan excepciones del SDK a
/// la UI sin envolverlas en `PurchaseResult.error`.
abstract class BillingService {
  /// Inicializa el SDK (idempotente). Llamar una vez al arrancar la app.
  Future<void> initialize();

  /// Asocia las compras al usuario (App User ID = Firebase UID).
  Future<void> login(String appUserId);

  /// Desasocia al cerrar sesión (vuelve a anónimo/Free).
  Future<void> logout();

  /// Estado de entitlement en vivo: re-emite ante compra, expiración y
  /// restauración. Emite `EntitlementStatus.free()` por defecto.
  Stream<EntitlementStatus> customerInfoStream();

  /// Packages de la Offering activa (para el paywall, SPEC-198).
  /// Lista vacía si no hay Offering configurada.
  Future<List<BillingPackage>> currentOfferingPackages();

  /// Inicia la compra de un package.
  Future<PurchaseResult> purchase(BillingPackage pkg);

  /// Restaura compras previas (obligatorio para App Store).
  Future<PurchaseResult> restore();

  /// SPEC-213: libera recursos (StreamController, listeners SDK).
  /// Riverpod lo invoca vía ref.onDispose cuando el provider se destruye.
  void dispose();
}
