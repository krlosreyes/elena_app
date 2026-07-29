// 29-jul (barrido de coherencia en Simulador): el pilar de nutrición se
// llamaba distinto según la pantalla — "Comidas" en los anillos del
// Dashboard y en el IMR, "nutrición" en Progreso, "Comidas" otra vez en
// el resumen semanal junto a "Hidrat." y "Ejerc." truncadas.
//
// SPEC-17 ya había declarado `PillarConstants` como "fuente única de
// verdad para el vocabulario de pilares", pero las etiquetas cortas
// (`trackingLabel*`) no las usaba NADIE: cada widget escribía la suya a
// mano. La regla existía y no estaba conectada, que es cómo se coló la
// divergencia sin que ningún test se quejara.
//
// Este test es el guardarraíl que faltaba. No comprueba que la UI se vea
// bien —eso no se puede afirmar desde acá—; comprueba que las etiquetas
// de pilar que la UI muestra salen del juego canónico y no de un literal
// suelto. Si alguien vuelve a escribir 'Comidas' en un widget, esto lo
// caza antes que un usuario.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/core/constants/pillar_constants.dart';

/// Widgets que pintan la fila/anillos de los cinco pilares. Son los que
/// el usuario compara entre sí, y por lo tanto los que tienen que
/// coincidir palabra por palabra.
const _archivosDePilares = [
  'lib/src/features/dashboard/presentation/widgets/dashboard_pillars_row.dart',
  'lib/src/features/analysis/presentation/widgets/imr_ring_with_satellites.dart',
  'lib/src/features/analysis/presentation/widgets/weekly_coaching_card.dart',
];

/// Nombres que se usaron alguna vez para un pilar y que ya no deben
/// aparecer como literal en esos widgets.
const _nombresRetirados = [
  "'Comidas'",
  "'Hidrat.'",
  "'Ejerc.'",
];

void main() {
  group('Vocabulario de pilares', () {
    test('las cinco etiquetas cortas están completas y sin repetidos', () {
      expect(PillarConstants.trackingLabels, hasLength(5));
      expect(
        PillarConstants.trackingLabels.toSet(),
        hasLength(5),
        reason: 'Dos pilares no pueden compartir etiqueta.',
      );
      expect(
        PillarConstants.trackingLabels.any((l) => l.trim().isEmpty),
        isFalse,
      );
    });

    test('ninguna etiqueta va truncada con punto', () {
      // "Hidrat." y "Ejerc." nacieron de una columna estrecha. Si vuelve
      // a pasar, la solución es ensanchar la columna, no abreviar el
      // nombre del pilar.
      for (final label in PillarConstants.trackingLabels) {
        expect(
          label.endsWith('.'),
          isFalse,
          reason: '"$label" está abreviada.',
        );
      }
    });

    test('los widgets de pilares no traen nombres retirados a mano', () {
      final infractores = <String>[];

      for (final ruta in _archivosDePilares) {
        final archivo = File(ruta);
        // Si el archivo se renombró o se borró, el test debe decirlo en
        // vez de pasar en verde vigilando un archivo inexistente — que
        // es exactamente el modo de fallo que este test combate.
        expect(
          archivo.existsSync(),
          isTrue,
          reason: '$ruta ya no existe: actualiza _archivosDePilares.',
        );

        final contenido = archivo.readAsStringSync();
        for (final retirado in _nombresRetirados) {
          if (contenido.contains(retirado)) {
            infractores.add('$ruta contiene $retirado');
          }
        }
      }

      expect(
        infractores,
        isEmpty,
        reason: 'Usa PillarConstants.trackingLabel* en vez del literal:\n'
            '${infractores.join('\n')}',
      );
    });
  });
}
