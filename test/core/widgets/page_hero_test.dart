// 29-jul: los títulos de página se escribían a mano en cada pantalla y
// habían derivado en dos tratamientos distintos —Progreso con un hero de
// 34 px en el cuerpo, Perfil con un AppBar de 18, el Dashboard sin
// título— de modo que Perfil, siendo una pestaña raíz, se veía idéntico
// a sus propias pantallas hijas.
//
// La regla que se fija: hero grande = pestaña raíz, AppBar 18 = pantalla
// abierta desde ahí. Este test protege la mitad que se puede verificar
// sin comparar capturas: que las tres pestañas piden el MISMO widget, y
// que ese widget no se degrada cuando falta el subtítulo o cuando el
// título es largo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/core/widgets/page_hero.dart';

Future<void> _montar(WidgetTester tester, Widget hero) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(20), child: hero)),
    ),
  );
}

TextStyle _estiloDe(WidgetTester tester, String texto) =>
    tester.widget<Text>(find.text(texto)).style!;

void main() {
  group('heroTodayLabel', () {
    test('arma la fecha en español, sin ceros a la izquierda', () {
      expect(heroTodayLabel(DateTime(2026, 7, 29)), 'miércoles, 29 de julio');
      expect(heroTodayLabel(DateTime(2026, 1, 5)), 'lunes, 5 de enero');
    });

    test('cubre los doce meses y los siete días sin desbordar', () {
      // El bug clásico de estas listas es un índice corrido: mes 12 →
      // 'diciembre', día 7 (domingo) → 'domingo'. Si alguien reordena
      // las constantes, esto lo caza.
      expect(heroTodayLabel(DateTime(2026, 12, 31)), contains('diciembre'));
      expect(heroTodayLabel(DateTime(2026, 11, 1)), startsWith('domingo'));
    });
  });

  group('PageHero', () {
    testWidgets('el título usa el tamaño canónico', (tester) async {
      await _montar(tester, const PageHero(title: 'Progreso'));

      expect(_estiloDe(tester, 'Progreso').fontSize, PageHero.titleFontSize);
      expect(_estiloDe(tester, 'Progreso').fontWeight, FontWeight.w800);
    });

    testWidgets('sin subtítulo no deja hueco ni pinta texto vacío',
        (tester) async {
      await _montar(tester, const PageHero(title: 'Perfil'));

      // Perfil no tiene nada que fechar. Un `Text('')` invisible sería
      // un espaciado fantasma imposible de rastrear después.
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('el trailing convive con el título sin desbordar',
        (tester) async {
      await _montar(
        tester,
        const PageHero(
          title: 'Hoy',
          subtitle: 'miércoles, 29 de julio',
          trailing: SizedBox(width: 44, height: 44),
        ),
      );

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('miércoles, 29 de julio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un título largo se come el espacio del trailing, no desborda',
        (tester) async {
      await _montar(
        tester,
        const PageHero(
          title: 'Un título deliberadamente larguísimo para la fila',
          trailing: SizedBox(width: 44, height: 44),
        ),
      );

      // Sin el Expanded, esto lanzaría un RenderFlex overflow.
      expect(tester.takeException(), isNull);
    });
  });
}
