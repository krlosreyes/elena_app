// SPEC-197 inc1 — tests del gate puro, el provider reactivo y PremiumLock.

import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/application/feature_gate.dart';
import 'package:elena_app/src/features/billing/presentation/premium_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_billing_service.dart';

void main() {
  group('FeatureGate (puro)', () {
    test('Free: solo lo básico; coaching 1/día', () {
      const g = FeatureGate(isPremium: false, isInTrial: false);
      expect(g.cycleFeedbackAllowed, false);
      expect(g.analyticsHistoryAllowed, false);
      expect(g.autoSyncAllowed, false);
      expect(g.coachingSecondaryAllowed, false);
      expect(g.coachingActionAllowed(0), true); // primera del día
      expect(g.coachingActionAllowed(1), false); // la segunda se bloquea
    });

    test(
        'UX-SYNC (21-jul, P1): manualSyncAllowed siempre true, incluso Free '
        '— solo el sync EN SEGUNDO PLANO (autoSyncAllowed) se gatea', () {
      const free = FeatureGate(isPremium: false, isInTrial: false);
      const premium = FeatureGate(isPremium: true, isInTrial: false);
      expect(free.manualSyncAllowed, true);
      expect(free.autoSyncAllowed, false);
      expect(premium.manualSyncAllowed, true);
      expect(premium.autoSyncAllowed, true);
    });

    test('Premium: todo permitido, coaching ilimitado', () {
      const g = FeatureGate(isPremium: true, isInTrial: false);
      expect(g.cycleFeedbackAllowed, true);
      expect(g.analyticsHistoryAllowed, true);
      expect(g.autoSyncAllowed, true);
      expect(g.coachingSecondaryAllowed, true);
      expect(g.coachingActionAllowed(5), true);
    });
  });

  group('gating inerte cuando el cobro no está habilitado', () {
    test('billingEnabled=false → todos premium (no se gatea nada)', () {
      // BUGFIX (auditoría 2026-07-12): `billingEnabledProvider` cambió su
      // default de `false` a `kDebugMode` (fix real: "gating invisible" —
      // ver commit "fix(SPEC-197/198): billingEnabledProvider=kDebugMode
      // por defecto"). `flutter test` corre siempre con kDebugMode=true,
      // así que un `ProviderContainer()` sin overrides YA NO representa
      // el caso "billing deshabilitado" — hay que forzarlo explícitamente
      // para probar esa rama.
      final container = ProviderContainer(
        overrides: [billingEnabledProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);
      expect(container.read(isPremiumProvider), true);
      expect(container.read(featureGateProvider).analyticsHistoryAllowed, true);
      expect(container.read(featureGateProvider).autoSyncAllowed, true);
    });
  });

  group('featureGateProvider (reactivo)', () {
    test('free→premium desbloquea en vivo', () async {
      final fake = FakeBillingService();
      final container = ProviderContainer(
        overrides: [
          billingServiceProvider.overrideWithValue(fake),
          billingEnabledProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fake.dispose);

      await container.read(entitlementProvider.future);
      expect(container.read(featureGateProvider).isPremium, false);

      final pkgs = await fake.currentOfferingPackages();
      await fake.purchase(pkgs.first);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(featureGateProvider).isPremium, true);
      expect(container.read(featureGateProvider).analyticsHistoryAllowed, true);
    });
  });

  group('PremiumLock (widget)', () {
    testWidgets('desbloqueado muestra el hijo sin candado', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PremiumLock(
            isLocked: false,
            onUpgrade: () {},
            child: const Text('contenido'),
          ),
        ),
      ));
      expect(find.text('contenido'), findsOneWidget);
      expect(find.text('Desbloquear'), findsNothing);
    });

    testWidgets('bloqueado muestra candado + CTA que dispara onUpgrade',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          // PremiumLock superpone su overlay sobre contenido premium de
          // tamaño real (un gráfico/sección); le damos espacio en el test.
          body: PremiumLock(
            isLocked: true,
            onUpgrade: () => tapped = true,
            label: 'Histórico Premium',
            child: const SizedBox(
                width: 300, height: 220, child: Text('contenido')),
          ),
        ),
      ));
      expect(find.text('Histórico Premium'), findsOneWidget);
      expect(find.text('Desbloquear'), findsOneWidget);
      await tester.tap(find.text('Desbloquear'));
      expect(tapped, true);
    });
  });
}
