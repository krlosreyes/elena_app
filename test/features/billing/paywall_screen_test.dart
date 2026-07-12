// SPEC-198 — widget test del PaywallScreen con FakeBillingService.

import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_billing_service.dart';

Widget _wrap(FakeBillingService fake) {
  return ProviderScope(
    overrides: [billingServiceProvider.overrideWithValue(fake)],
    child: const MaterialApp(home: Scaffold(body: PaywallScreen())),
  );
}

void main() {
  testWidgets('renderiza los packages con precio localizado del SDK',
      (tester) async {
    final fake = FakeBillingService();
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    expect(find.text('Mensual'), findsOneWidget);
    expect(find.text('Anual'), findsOneWidget);
    expect(find.text('US\$9.99'), findsOneWidget); // del FakeBillingService
    expect(find.text('Restaurar compras'), findsOneWidget);
  });

  testWidgets('comprar un package → compra exitosa cierra el paywall',
      (tester) async {
    final fake = FakeBillingService();
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    // BUGFIX (auditoría 2026-07-12): tapear la tarjeta "Mensual" solo
    // cambia `_selectedIndex` (ver `_buildPlanSelector` en
    // paywall_screen.dart) — no dispara la compra. El botón que llama a
    // `_buySelected()` es el CTA principal, cuyo label es dinámico según
    // el estado de trial (isInTrialProvider/trialDaysRemainingProvider,
    // sin override en este test → sin trial → "Reactivar mi acceso").
    // Sin este segundo tap, `purchase()` nunca se invocaba y el status
    // quedaba en `EntitlementStatus.free()` — de ahí `isPremium == false`.
    await tester.tap(find.text('Mensual'));
    await tester.pump();
    // El CTA queda fuera del viewport chico por defecto de flutter_test
    // (800x600) — el contenido vive en un SingleChildScrollView largo.
    // `ensureVisible` lo scrollea antes de tapear; sin esto, `tap()` le
    // pega a un offset fuera del árbol renderizado y falla en silencio
    // (warnIfMissed) sin llegar nunca a invocar `_buySelected()`.
    await tester.ensureVisible(find.text('Reactivar mi acceso'));
    await tester.tap(find.text('Reactivar mi acceso'));
    await tester.pumpAndSettle();

    // El stream debe quedar en premium tras la compra.
    final status = await fake.customerInfoStream().first;
    expect(status.isPremium, true);
  });

  testWidgets('compra cancelada NO rompe ni cierra con error', (tester) async {
    final fake = FakeBillingService()..cancelNextPurchase = true;
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Anual'));
    await tester.pumpAndSettle();

    // Sigue en el paywall (no se cerró), sin SnackBar de error.
    expect(find.byType(PaywallScreen), findsOneWidget);
    final status = await fake.customerInfoStream().first;
    expect(status.isPremium, false);
  });

  testWidgets('sin packages muestra mensaje de no disponible', (tester) async {
    final fake = FakeBillingService(packages: const []);
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    // BUGFIX (auditoría 2026-07-12): el test esperaba un copy distinto
    // ('ahora mismo') al que realmente pinta paywall_screen.dart ('en este
    // momento'). Este mismatch estaba enmascarado por el timeout de
    // pumpAndSettle que causaba el AnimationController _shimmer muerto
    // (ver fix de arriba) — nunca llegaba a evaluarse el `expect`.
    expect(
      find.text('Los planes no están disponibles en este momento.'),
      findsOneWidget,
    );
  });
}
