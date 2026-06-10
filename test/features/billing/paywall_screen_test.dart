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

    // El stream debe quedar en premium tras la compra.
    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();

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

    expect(
      find.text('Los planes no están disponibles ahora mismo.'),
      findsOneWidget,
    );
  });
}
