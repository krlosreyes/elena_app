// SPEC-146 §8.2: tests del SplashScreen widget.

import 'package:elena_app/src/features/auth/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('SPEC-146 §8.2 — SplashScreen render', () {
    testWidgets('Renderiza branding + tagline', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      await tester.pump();

      expect(find.text('Metamorfosis Real'), findsOneWidget);
      expect(find.text('Elena · Salud metabólica'), findsOneWidget);
    });

    testWidgets('Renderiza CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Centrado vertical y horizontal', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      await tester.pump();

      // Verificación estructural: hay un Center wrapping el contenido.
      expect(find.byType(Center), findsWidgets);
    });
  });
}
