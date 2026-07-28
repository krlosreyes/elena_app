// SPEC-213: Billing lifecycle — StreamController no queda abierto tras dispose().
//
// Verifica que:
//   A) BillingService.dispose() existe como contrato (compila con cualquier impl).
//   B) FreeBillingService.dispose() es no-op y no lanza.
//   C) El patrón StreamController.broadcast() cierra correctamente sin lanzar
//      si se intenta agregar tras close() (isClosed guard).
//   D) ref.onDispose se dispara al destruir el provider (patrón de wiring en
//      billing_providers + main.dart).
//
// No usa purchases_flutter ni Firebase — prueba la mecánica pura.

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/application/free_billing_service.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';

// ─── Fake que expone el StreamController para los tests ───────────────────────

class FakeBillingServiceWithController implements BillingService {
  final _ctrl = StreamController<EntitlementStatus>.broadcast();
  bool disposeCalled = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> login(String appUserId) async {}

  @override
  Future<void> logout() async {}

  @override
  Stream<EntitlementStatus> customerInfoStream() => _ctrl.stream;

  @override
  Future<List<BillingPackage>> currentOfferingPackages() async => const [];

  @override
  Future<PurchaseResult> purchase(dynamic pkg) async =>
      PurchaseResult.error('fake');

  @override
  Future<PurchaseResult> restore() async =>
      PurchaseResult.success(const EntitlementStatus.free());

  @override
  void dispose() {
    disposeCalled = true;
    if (!_ctrl.isClosed) _ctrl.close();
  }

  bool get isControllerClosed => _ctrl.isClosed;

  void safeAdd(EntitlementStatus status) {
    // Simula el guard isClosed de RevenueCatBillingService
    if (!_ctrl.isClosed) _ctrl.add(status);
  }
}

void main() {
  group('SPEC-213 — Billing lifecycle / StreamController', () {
    test('SPEC-213-01: BillingService.dispose() es parte del contrato', () {
      // Compila → el método existe en la interfaz abstracta.
      final BillingService svc = const FreeBillingService();
      expect(() => svc.dispose(), returnsNormally,
          reason: 'dispose() debe estar definido en BillingService');
    });

    test('SPEC-213-02: FreeBillingService.dispose() es no-op y no lanza', () {
      const svc = FreeBillingService();
      expect(() => svc.dispose(), returnsNormally);
      // Puede llamarse múltiples veces sin error
      expect(() => svc.dispose(), returnsNormally);
    });

    test(
        'SPEC-213-03: dispose() cierra el StreamController; '
        'isClosed == true después', () {
      final svc = FakeBillingServiceWithController();
      expect(svc.isControllerClosed, isFalse);
      svc.dispose();
      expect(svc.isControllerClosed, isTrue);
      expect(svc.disposeCalled, isTrue);
    });

    test(
        'SPEC-213-04: guard isClosed previene StateError al agregar tras dispose()',
        () {
      final svc = FakeBillingServiceWithController();
      svc.dispose(); // cierra el controller

      // safeAdd simula el guard `if (!_controller.isClosed) _controller.add(...)`
      expect(
        () => svc.safeAdd(const EntitlementStatus.free()),
        returnsNormally,
        reason:
            'El guard isClosed debe prevenir StateError al agregar tras dispose()',
      );
    });

    test(
        'SPEC-213-05: dispose() idempotente — llamarlo dos veces no lanza '
        '(segunda llamada encuentra isClosed == true)', () {
      final svc = FakeBillingServiceWithController();
      svc.dispose();
      // Segunda llamada: _ctrl.isClosed == true → el guard lo evita
      expect(() => svc.dispose(), returnsNormally);
    });

    test(
        'SPEC-213-06: ref.onDispose llama dispose() al destruir el provider '
        '(patrón billing_providers.dart con overrideWith)', () {
      final svc = FakeBillingServiceWithController();
      final provider = Provider<BillingService>((ref) {
        ref.onDispose(svc.dispose);
        return svc;
      });

      final container = ProviderContainer(overrides: []);
      addTearDown(container.dispose);

      // Leer el provider (lo inicializa)
      container.read(provider);
      expect(svc.disposeCalled, isFalse);
      expect(svc.isControllerClosed, isFalse);

      // Destruir el container (simula app closedown / ProviderScope unmount)
      container.dispose();

      expect(svc.disposeCalled, isTrue,
          reason:
              'ref.onDispose debe llamar dispose() al destruir el container');
      expect(svc.isControllerClosed, isTrue);
    });
  });
}
