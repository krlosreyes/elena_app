// SPEC-196 inc1 — tests de la capa de cobro pura (sin SDK ni red).

import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/application/billing_service.dart';
import 'package:elena_app/src/features/billing/application/free_billing_service.dart';
import 'package:elena_app/src/features/billing/domain/billing_package.dart';
import 'package:elena_app/src/features/billing/domain/entitlement_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_billing_service.dart';

const _samplePackage = BillingPackage(
  id: '\$rc_monthly',
  productId: 'elena_premium_monthly',
  title: 'Premium mensual',
  priceString: 'US\$9.99',
  period: BillingPeriod.monthly,
);

void main() {
  group('EntitlementStatus', () {
    test('free() no es premium y source none', () {
      const s = EntitlementStatus.free();
      expect(s.isPremium, false);
      expect(s.source, EntitlementSource.none);
      expect(s.isTrial, false);
    });

    test('trial cuenta como premium y isTrial', () {
      const s =
          EntitlementStatus(isPremium: true, source: EntitlementSource.trial);
      expect(s.isPremium, true);
      expect(s.isTrial, true);
    });

    test('igualdad por valor', () {
      const a =
          EntitlementStatus(isPremium: true, source: EntitlementSource.paid);
      const b =
          EntitlementStatus(isPremium: true, source: EntitlementSource.paid);
      expect(a, b);
    });
  });

  group('FreeBillingService (default seguro)', () {
    const svc = FreeBillingService();

    test('stream emite free', () async {
      final s = await svc.customerInfoStream().first;
      expect(s.isPremium, false);
    });

    test('sin packages y la compra no está habilitada', () async {
      expect(await svc.currentOfferingPackages(), isEmpty);
      final r = await svc.purchase(_samplePackage);
      expect(r.isSuccess, false);
      expect(r.outcome, PurchaseOutcome.error);
    });
  });

  group('FakeBillingService (simulación)', () {
    test('compra exitosa → premium en el stream', () async {
      final fake = FakeBillingService();
      addTearDown(fake.dispose);
      final pkgs = await fake.currentOfferingPackages();
      final emissions = <bool>[];
      final sub =
          fake.customerInfoStream().listen((s) => emissions.add(s.isPremium));

      final r = await fake.purchase(pkgs.first);
      await Future<void>.delayed(Duration.zero);

      expect(r.isSuccess, true);
      expect(r.status!.isPremium, true);
      expect(emissions.last, true);
      await sub.cancel();
    });

    test('compra cancelada → cancelled, no premium', () async {
      final fake = FakeBillingService()..cancelNextPurchase = true;
      addTearDown(fake.dispose);
      final pkgs = await fake.currentOfferingPackages();
      final r = await fake.purchase(pkgs.first);
      expect(r.outcome, PurchaseOutcome.cancelled);
    });

    test('logout vuelve a free', () async {
      final fake = FakeBillingService();
      addTearDown(fake.dispose);
      final pkgs = await fake.currentOfferingPackages();
      await fake.purchase(pkgs.first);
      await fake.logout();
      final s = await fake.customerInfoStream().first;
      expect(s.isPremium, false);
    });
  });

  group('entitlementProvider / isPremiumProvider', () {
    test('default Free, premium tras compra simulada', () async {
      final fake = FakeBillingService();
      final container = ProviderContainer(
        overrides: [billingServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      addTearDown(fake.dispose);

      await container.read(entitlementProvider.future);
      expect(container.read(isPremiumProvider), false);

      final pkgs = await fake.currentOfferingPackages();
      await fake.purchase(pkgs.first);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(container.read(entitlementProvider).value!.isPremium, true);
    });
  });
}
