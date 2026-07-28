// Auditoría 2026-07-27 — hallazgo C-04.
//
// Antes, si `_bootstrap()` lanzaba, `main()` terminaba sin llamar a
// `runApp` y el usuario se quedaba mirando una pantalla negra permanente.
// La regla que estos tests protegen es: pase lo que pase en el arranque,
// siempre se monta una UI con un camino de salida.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/core/widgets/bootstrap_error_app.dart';

void main() {
  group('C-04 — pantalla de fallo de arranque', () {
    testWidgets('monta una UI con mensaje humano y botón de reintento',
        (tester) async {
      await tester.pumpWidget(
        BootstrapErrorApp(onRetry: () async {}),
      );

      expect(find.text('No pudimos abrir Elena'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.textContaining('revisa tu internet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no depende de Riverpod ni del tema de la app', (tester) async {
      // Se monta como raíz absoluta, sin ProviderScope ni AppTheme: si
      // dependiera de ellos, cualquiera podría ser justamente lo que falló.
      await tester.pumpWidget(BootstrapErrorApp(onRetry: () async {}));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('el detalle técnico se muestra colapsado, no en la cara',
        (tester) async {
      await tester.pumpWidget(
        BootstrapErrorApp(
          onRetry: () async {},
          technicalDetail: 'FirebaseException: plist ausente',
        ),
      );

      expect(find.text('Detalle técnico'), findsOneWidget);
      expect(find.text('FirebaseException: plist ausente'), findsNothing);

      await tester.tap(find.text('Detalle técnico'));
      await tester.pumpAndSettle();
      expect(find.text('FirebaseException: plist ausente'), findsOneWidget);
    });

    testWidgets('sin detalle técnico no se muestra la sección', (tester) async {
      await tester.pumpWidget(BootstrapErrorApp(onRetry: () async {}));
      expect(find.text('Detalle técnico'), findsNothing);
    });

    testWidgets('el botón invoca onRetry y muestra progreso mientras corre',
        (tester) async {
      var invocaciones = 0;
      final completer = Completer<void>();

      await tester.pumpWidget(
        BootstrapErrorApp(
          onRetry: () {
            invocaciones++;
            return completer.future;
          },
        ),
      );

      await tester.tap(find.text('REINTENTAR'));
      await tester.pump();

      expect(invocaciones, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('REINTENTAR'), findsNothing);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.text('REINTENTAR'), findsOneWidget);
    });

    testWidgets('pulsar dos veces seguidas no dispara dos reintentos',
        (tester) async {
      var invocaciones = 0;
      final completer = Completer<void>();

      await tester.pumpWidget(
        BootstrapErrorApp(
          onRetry: () {
            invocaciones++;
            return completer.future;
          },
        ),
      );

      await tester.tap(find.text('REINTENTAR'));
      await tester.pump();
      // El botón ya está deshabilitado; el segundo tap no debe llegar.
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      expect(invocaciones, 1);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('un onRetry que falla no rompe la pantalla', (tester) async {
      // Esta es la última pantalla que le queda al usuario: si el reintento
      // falla, tiene que volver a ofrecer el botón, no tumbar el árbol.
      var intentos = 0;
      await tester.pumpWidget(
        BootstrapErrorApp(
          onRetry: () async {
            intentos++;
            throw Exception('sigue sin haber red');
          },
        ),
      );

      await tester.tap(find.text('REINTENTAR'));
      await tester.pumpAndSettle();

      expect(intentos, 1);
      // La excepción se absorbe dentro del widget (ver `_pulsar`): no debe
      // escapar al framework ni dejar la pantalla en un estado muerto.
      expect(tester.takeException(), isNull);
      expect(find.text('No pudimos abrir Elena'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);

      // Y el botón vuelve a estar operativo para un segundo intento.
      await tester.tap(find.text('REINTENTAR'));
      await tester.pumpAndSettle();
      expect(intentos, 2);
    });
  });
}
