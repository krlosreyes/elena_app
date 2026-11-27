// SPEC-305 — las fuentes se ven, se tocan y abren el enlace correcto.
//
// La guía 1.4.1 pide citas "con enlace" y "fáciles de encontrar". Estos
// tests verifican el comportamiento, no solo que el widget exista:
//   - el bloque de fuentes pinta cada fuente y al tocarla abre SU url;
//   - la cita corta de un insight abre una hoja con sus fuentes;
//   - una etiqueta que no es cita no se disfraza de enlace;
//   - la pantalla completa lista todo el catálogo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/science/application/source_link_opener.dart';
import 'package:elena_app/src/features/science/domain/scientific_source.dart';
import 'package:elena_app/src/features/science/presentation/scientific_sources_screen.dart';
import 'package:elena_app/src/features/science/presentation/widgets/sources_footer.dart';

Future<void> _montar(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  late List<Uri> abiertos;
  var resultado = true;

  setUp(() {
    abiertos = [];
    resultado = true;
    SourceLinkOpener.handlerForTesting = (uri) async {
      abiertos.add(uri);
      return resultado;
    };
  });

  tearDown(() => SourceLinkOpener.handlerForTesting = null);

  group('SourcesFooter', () {
    testWidgets('pinta cada fuente y abre su url al tocarla', (tester) async {
      await _montar(
        tester,
        const SourcesFooter(sources: ScientificSources.bodyComposition),
      );

      expect(find.text('Fuentes científicas'), findsOneWidget);
      for (final s in ScientificSources.bodyComposition) {
        expect(find.text(s.shortLabel), findsOneWidget, reason: s.id);
      }

      await tester.tap(find.text(ScientificSources.ashwell2012.shortLabel));
      await tester.pumpAndSettle();
      expect(abiertos, [Uri.parse(ScientificSources.ashwell2012.url)]);
    });

    testWidgets('el texto es legible: 13 pt o más en color de acento',
        (tester) async {
      await _montar(
        tester,
        const SourcesFooter(sources: [ScientificSources.whoBmi]),
      );
      final estilo = tester
          .widget<Text>(find.text(ScientificSources.whoBmi.shortLabel))
          .style!;
      expect(estilo.fontSize, greaterThanOrEqualTo(13));
      expect(estilo.decoration, TextDecoration.underline);
    });

    testWidgets('si el enlace no abre, avisa con el nombre de la fuente',
        (tester) async {
      resultado = false;
      await _montar(
        tester,
        const SourcesFooter(sources: [ScientificSources.monnier2017]),
      );
      await tester.tap(find.text(ScientificSources.monnier2017.shortLabel));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Monnier'), findsWidgets);
    });

    testWidgets('"Ver todas" lleva a la pantalla completa', (tester) async {
      await _montar(
        tester,
        const SourcesFooter(sources: [ScientificSources.efsa2010]),
      );
      await tester.tap(find.byKey(const ValueKey('sources-footer-see-all')));
      await tester.pumpAndSettle();
      expect(find.byType(ScientificSourcesScreen), findsOneWidget);
    });
  });

  group('CitationLink', () {
    testWidgets('una cita del catálogo abre una hoja con sus fuentes',
        (tester) async {
      await _montar(tester, const CitationLink('Walker 2017 + AASM'));

      await tester.tap(find.byType(CitationLink));
      await tester.pumpAndSettle();

      expect(
          find.text(ScientificSources.walker2017.shortLabel), findsOneWidget);
      expect(
          find.text(ScientificSources.watson2015.shortLabel), findsOneWidget);

      await tester.tap(find.text(ScientificSources.watson2015.shortLabel));
      await tester.pumpAndSettle();
      expect(abiertos, [Uri.parse(ScientificSources.watson2015.url)]);
    });

    testWidgets('una etiqueta que no es cita se pinta como texto normal',
        (tester) async {
      await _montar(tester, const CitationLink('· Basado en tu progreso'));

      final texto = find.text('· Basado en tu progreso');
      expect(texto, findsOneWidget);
      expect(tester.widget<Text>(texto).style?.decoration,
          isNot(TextDecoration.underline));
      await tester.tap(texto);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('mantiene el texto exacto de la cita y se ve como enlace',
        (tester) async {
      await _montar(
          tester, const CitationLink('· Cahill, 1966 — J Clin Invest'));
      final texto = find.text('· Cahill, 1966 — J Clin Invest');
      expect(texto, findsOneWidget);
      expect(tester.widget<Text>(texto).style?.decoration,
          TextDecoration.underline);
    });
  });

  group('ScientificSourcesScreen', () {
    testWidgets('lista todas las fuentes del catálogo', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(const MaterialApp(home: ScientificSourcesScreen()));

      for (final s in ScientificSources.all) {
        final finder = find.byKey(ValueKey('source-tile-${s.id}'));
        await tester.scrollUntilVisible(finder, 300,
            scrollable: find.byType(Scrollable).first);
        expect(finder, findsOneWidget, reason: s.id);
      }
    });

    testWidgets(
        'aclara que el IMR es un índice propio y que no reemplaza al '
        'médico', (tester) async {
      await tester
          .pumpWidget(const MaterialApp(home: ScientificSourcesScreen()));
      expect(find.textContaining('índice propio'), findsOneWidget);
      expect(find.textContaining('no reemplaza a tu médico'), findsOneWidget);
    });
  });
}
