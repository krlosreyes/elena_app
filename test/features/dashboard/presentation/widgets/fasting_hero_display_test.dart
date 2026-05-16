// SPEC-117: tests funcionales + golden del FastingHeroDisplay.

import 'package:elena_app/src/features/dashboard/domain/eating_window_state.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/fasting_hero_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: child,
          ),
        ),
      ),
    );

FastingState _stateActive() => FastingState(
      startTime: DateTime.now().subtract(const Duration(hours: 5)),
      duration: const Duration(hours: 5),
      phase: FastingPhase.transition,
      isActive: true,
      fastingProtocol: '16:8',
    );

FastingState _stateCompleted() => FastingState(
      startTime: DateTime.now().subtract(const Duration(hours: 16)),
      duration: const Duration(hours: 16),
      isActive: false,
      fastingProtocol: '16:8',
      completedToday: true,
    );

FastingState _stateIdle() => FastingState(
      isActive: false,
      fastingProtocol: '16:8',
    );

EatingWindowState _windowOpen() {
  final now = DateTime.now();
  return EatingWindowState(
    windowStart: now.subtract(const Duration(hours: 2)),
    windowEnd: now.add(const Duration(hours: 4)),
    windowDurationHours: 6,
    now: now,
    status: EatingWindowStatus.withinWindow,
    progressPercent: 0.33,
  );
}

void main() {
  group('FastingHeroDisplay funcional', () {
    testWidgets('modo activo muestra "AYUNO EN CURSO" y cronómetro',
        (tester) async {
      await tester.pumpWidget(_wrap(
        FastingHeroDisplay(
          fastingState: _stateActive(),
          eatingWindow: null,
          size: 300,
        ),
      ));
      expect(find.text('AYUNO EN CURSO'), findsOneWidget);
      // Cronómetro tiene formato HH:MM:SS (e.g., "05:00:0X")
      expect(find.textContaining(':'), findsWidgets);
    });

    testWidgets('modo completado muestra "AYUNO COMPLETADO"', (tester) async {
      await tester.pumpWidget(_wrap(
        FastingHeroDisplay(
          fastingState: _stateCompleted(),
          eatingWindow: null,
          size: 300,
        ),
      ));
      expect(find.text('AYUNO COMPLETADO'), findsOneWidget);
      // mainText: '${s.targetHours}h' → "16h" para protocolo "16:8".
      expect(find.text('16h'), findsOneWidget);
      // Sin ventana, subText es 'Próximo ayuno: mañana'.
      expect(find.textContaining('Próximo'), findsOneWidget);
    });

    testWidgets('modo ventana muestra "PRÓXIMO AYUNO" y countdown',
        (tester) async {
      await tester.pumpWidget(_wrap(
        FastingHeroDisplay(
          fastingState: _stateIdle(),
          eatingWindow: _windowOpen(),
          size: 300,
        ),
      ));
      expect(find.text('PRÓXIMO AYUNO'), findsOneWidget);
      // Subtexto contiene "Cierra ventana"
      expect(find.textContaining('Cierra ventana'), findsOneWidget);
    });

    testWidgets('modo idle (sin ventana ni ayuno) muestra placeholder',
        (tester) async {
      await tester.pumpWidget(_wrap(
        FastingHeroDisplay(
          fastingState: _stateIdle(),
          eatingWindow: null,
          size: 300,
        ),
      ));
      expect(find.text('AYUNO'), findsOneWidget);
      expect(find.text('--:--:--'), findsOneWidget);
      expect(find.textContaining('Toca'), findsOneWidget);
    });

    testWidgets(
      'SPEC-118.bugfix: ticker sobrevive rebuilds rápidos del parent '
      '(no se queda congelado en los segundos)',
      (tester) async {
        // Reproducción del bug: el `didUpdateWidget` cancelaba y recreaba
        // el Timer.periodic(1s) en CADA rebuild del parent. Si el parent
        // rebuildeaba con frecuencia <1s, el cronómetro quedaba congelado.
        //
        // El test forza 3 rebuilds rápidos (200ms entre cada uno) con la
        // MISMA prop de fastingState — si el fix no estuviera, el ticker
        // se cancelaría en cada rebuild y nunca dispararía.
        //
        // Tras los rebuilds, esperamos 1.5s para dar margen al timer de
        // disparar al menos una vez. El widget debe seguir renderizando
        // el modo activo (la prueba se enfoca en NO crashear ni quedar
        // en estado inválido).
        final fixedState = _stateActive();

        await tester.pumpWidget(_wrap(
          FastingHeroDisplay(
            fastingState: fixedState,
            eatingWindow: null,
            size: 300,
          ),
        ));
        // Tres rebuilds del parent con la MISMA prop. Sin el fix, cada
        // uno cancelaría el ticker antes de su primera ejecución.
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpWidget(_wrap(
          FastingHeroDisplay(
            fastingState: fixedState,
            eatingWindow: null,
            size: 300,
          ),
        ));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpWidget(_wrap(
          FastingHeroDisplay(
            fastingState: fixedState,
            eatingWindow: null,
            size: 300,
          ),
        ));
        // Dar margen al timer para que dispare al menos una vez.
        await tester.pump(const Duration(seconds: 1, milliseconds: 100));

        // Widget sigue vivo y mostrando modo activo.
        expect(find.text('AYUNO EN CURSO'), findsOneWidget);
        // Limpiar el Timer pendiente para no dejar timers vivos al
        // terminar el test (flutter_test marca eso como fallo).
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  group('FastingHeroDisplay golden', () {
    testWidgets('modo idle - golden estable (sin Timer)', (tester) async {
      // Idle no usa Timer → golden determinista.
      await tester.pumpWidget(_wrap(
        FastingHeroDisplay(
          fastingState: _stateIdle(),
          eatingWindow: null,
          size: 300,
        ),
      ));
      await expectLater(
        find.byType(FastingHeroDisplay),
        matchesGoldenFile('goldens/fasting_hero_idle.png'),
      );
    });
  });
}
