// SPEC-117: tests funcionales + golden para ProfileDataGroupCard y ProfileDataRow.

import 'package:elena_app/src/features/auth/presentation/widgets/data_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wrapper estándar para tests visuales: dark theme + fondo del Perfil.
Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );

void main() {
  group('ProfileDataGroupCard funcional', () {
    testWidgets('renderea N filas con divisores entre ellas', (tester) async {
      await tester.pumpWidget(_wrap(
        ProfileDataGroupCard(
          rows: [
            ProfileDataRow.readonly('Nombre', 'charlie'),
            ProfileDataRow.readonly('Edad', '49 años'),
            ProfileDataRow.readonly('Género', 'Masculino'),
          ],
        ),
      ));

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('charlie'), findsOneWidget);
      expect(find.text('Edad'), findsOneWidget);
      expect(find.text('49 años'), findsOneWidget);
      expect(find.text('Género'), findsOneWidget);
      expect(find.text('Masculino'), findsOneWidget);
    });

    testWidgets('una sola fila no muestra divisor', (tester) async {
      await tester.pumpWidget(_wrap(
        ProfileDataGroupCard(
          rows: [ProfileDataRow.readonly('Solo', 'una')],
        ),
      ));
      expect(find.text('Solo'), findsOneWidget);
      expect(find.text('una'), findsOneWidget);
    });
  });

  group('ProfileDataRow.editable', () {
    testWidgets('dispara onTap al tocar la fila', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(
        ProfileDataGroupCard(
          rows: [
            ProfileDataRow.editable(
              label: 'Peso',
              value: '82 kg',
              onTap: () => taps++,
            ),
          ],
        ),
      ));

      expect(taps, 0);
      await tester.tap(find.text('Peso'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('muestra chevron a la derecha', (tester) async {
      await tester.pumpWidget(_wrap(
        ProfileDataGroupCard(
          rows: [
            ProfileDataRow.editable(label: 'X', value: 'Y', onTap: () {}),
          ],
        ),
      ));
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });
  });

  group('ProfileDataRow.info', () {
    testWidgets('muestra tag y dispara onInfoTap', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(
        ProfileDataGroupCard(
          rows: [
            ProfileDataRow.info(
              label: '% Grasa',
              value: '33.9%',
              tag: 'confianza ALTA',
              tagColor: const Color(0xFF10B981),
              onInfoTap: () => taps++,
            ),
          ],
        ),
      ));

      expect(find.text('% Grasa'), findsOneWidget);
      expect(find.text('33.9%'), findsOneWidget);
      expect(find.text('confianza ALTA'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('ProfileDataRow.icon', () {
    testWidgets('renderea icono coloreado y dispara onTap', (tester) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(
        ProfileDataGroupCard(
          rows: [
            ProfileDataRow.icon(
              icon: Icons.wb_sunny_outlined,
              iconColor: const Color(0xFFEAB308),
              label: 'Despertar',
              value: '6:00 AM',
              valueColor: const Color(0xFFEAB308),
              onTap: () => taps++,
            ),
          ],
        ),
      ));

      expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
      expect(find.text('Despertar'), findsOneWidget);
      expect(find.text('6:00 AM'), findsOneWidget);

      await tester.tap(find.text('Despertar'));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('ProfileDataGroupCard golden', () {
    testWidgets('grupo mixto se renderea como golden', (tester) async {
      await tester.pumpWidget(_wrap(
        ProfileDataGroupCard(
          rows: [
            ProfileDataRow.readonly('Nombre', 'charlie'),
            ProfileDataRow.readonly('Edad', '49 años'),
            ProfileDataRow.editable(label: 'Peso', value: '82 kg', onTap: () {}),
            ProfileDataRow.info(
              label: '% Grasa',
              value: '33.9%',
              tag: 'confianza ALTA',
              tagColor: const Color(0xFF10B981),
              onInfoTap: () {},
            ),
          ],
        ),
      ));

      await expectLater(
        find.byType(ProfileDataGroupCard),
        matchesGoldenFile('goldens/data_group_card_mixed.png'),
      );
    });
  });
}
