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
