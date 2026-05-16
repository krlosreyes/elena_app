// Widget tests del PillarRing — SPEC-66 v2.
//
// Cubre:
// - Render del label e ícono.
// - onTap se invoca al tocar el widget.
// - Cuando isSelected es true, el label usa color saturado (igual al accent
//   del pilar) y peso w800.
// - Cuando isSelected es false, el label usa blanco semitransparente y peso
//   w600.
// - Cuando completed es true, aparece el badge de check verde.
// - Cuando completed es false, NO aparece el badge.

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('PillarRing — render básico', () {
    testWidgets('Renderiza el label dado', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PillarRing(
            icon: Icons.timer_rounded,
            color: AppColors.metabolicGreen,
            progress: 0.5,
            label: 'Ayuno',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Ayuno'), findsOneWidget);
    });

    testWidgets('Renderiza el ícono dado', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PillarRing(
            icon: Icons.water_drop_rounded,
            color: Colors.blueAccent,
            progress: 0.3,
            label: 'Hidratación',
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
    });
  });

  group('PillarRing — interacción', () {
    testWidgets('onTap se invoca al tocar el widget', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          PillarRing(
            icon: Icons.timer_rounded,
            color: AppColors.metabolicGreen,
            progress: 0,
            label: 'Ayuno',
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.byType(PillarRing));
      expect(taps, 1);
      await tester.tap(find.byType(PillarRing));
      expect(taps, 2);
    });
  });

  group('PillarRing — selección visual', () {
    testWidgets('isSelected=true: label en color del pilar y peso w800',
        (tester) async {
      const accent = Color(0xFF818CF8);
      await tester.pumpWidget(
        _wrap(
          PillarRing(
            icon: Icons.nightlight_round,
            color: accent,
            progress: 0.7,
            label: 'Sueño',
            onTap: () {},
            isSelected: true,
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.text('Sueño'));
      expect(textWidget.style?.color, accent);
      expect(textWidget.style?.fontWeight, FontWeight.w800);
    });

    testWidgets('isSelected=false: label en blanco semi-translúcido y w600',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PillarRing(
            icon: Icons.nightlight_round,
            color: const Color(0xFF818CF8),
            progress: 0.7,
            label: 'Sueño',
            onTap: () {},
            isSelected: false,
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.text('Sueño'));
      // Color blanco con opacidad 0.6 (alpha ~ 153/255 ≈ 0.6).
      expect(textWidget.style?.color, isNot(const Color(0xFF818CF8)));
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });
  });

  group('PillarRing — badge de completado', () {
    testWidgets('completed=true: muestra check verde', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PillarRing(
            icon: Icons.fitness_center_rounded,
            color: Colors.tealAccent,
            progress: 1.0,
            label: 'Ejercicio',
            onTap: () {},
            completed: true,
          ),
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('completed=false: NO muestra check', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PillarRing(
            icon: Icons.fitness_center_rounded,
            color: Colors.tealAccent,
            progress: 0.3,
            label: 'Ejercicio',
            onTap: () {},
            completed: false,
          ),
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });
  });
}
