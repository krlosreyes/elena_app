// 23-nov: dónde vive cada acceso.
//   * Reloj circadiano → Hoy (no Progreso), ruta /reloj.
//   * Insignias → Perfil (no Progreso).
// Se comprueba sobre el código fuente (mismo enfoque que
// citation_coverage_test) y con un widget test de navegación.

import 'dart:io';

import 'package:elena_app/src/features/dashboard/presentation/widgets/circadian_clock_entry_card.dart';
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

String _src(String path) => File(path).readAsStringSync();

void main() {
  const analysis = 'lib/src/features/analysis/presentation/analysis_screen.dart';
  const dashboard = 'lib/src/features/dashboard/presentation/dashboard_screen.dart';
  const profile = 'lib/src/features/auth/presentation/profile_screen.dart';
  const router = 'lib/src/router/app_router.dart';

  test('Progreso ya no enlaza a Insignias ni al reloj', () {
    final s = _src(analysis);
    expect(s.contains("'Insignias'"), isFalse);
    expect(s.contains("'Tu reloj'"), isFalse);
    expect(s.contains('/analysis/reloj'), isFalse);
    expect(s.contains('/profile/badges'), isFalse);
  });

  test('Hoy muestra el acceso al reloj circadiano', () {
    expect(_src(dashboard).contains('CircadianClockEntryCard()'), isTrue);
  });

  test('Perfil muestra la entrada a Insignias', () {
    expect(_src(profile).contains('BadgesEntryCard('), isTrue);
  });

  test('el router sirve /reloj y redirige /analysis/reloj', () {
    final s = _src(router);
    expect(s.contains("path: '/reloj'"), isTrue);
    expect(s.contains("redirect: (context, state) => '/reloj'"), isTrue);
  });

  test('ningún paso del tour ilumina el reloj que ya no está en Hoy', () {
    expect(
      kTourSteps.where((s) => s.spotlight == TourSpotlightArea.clock),
      isEmpty,
    );
  });

  testWidgets('tocar "Tu reloj circadiano" abre /reloj', (tester) async {
    final r = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: CircadianClockEntryCard()),
        ),
        GoRoute(
          path: '/reloj',
          builder: (_, __) => const Scaffold(body: Text('pantalla reloj')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: r));
    expect(find.text('Tu reloj circadiano'), findsOneWidget);
    await tester.tap(find.text('Tu reloj circadiano'));
    await tester.pumpAndSettle();
    expect(find.text('pantalla reloj'), findsOneWidget);
  });
}
