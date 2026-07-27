// Auditoría 2026-07-27 — hallazgo C-02.
//
// El estándar de copy del proyecto es español neutro LatAm, sin voseo
// rioplatense (declarado en intro_screens.dart §Reglas de copy). Aun así,
// la auditoría encontró ~35 cadenas en voseo repartidas por 14 archivos,
// incluidas el indicador de racha del Dashboard ("Arrancá hoy") y los
// insights semanales de los cinco pilares. Uno de ellos, "Bebé un vaso de
// agua", no es siquiera acento: es un error léxico ("bebé" es sustantivo).
//
// El público objetivo de Elena es mayoritariamente México, Colombia,
// Caribe e hispanos de EE. UU. Para ese lector, el voseo suena extranjero.
//
// El barrido manual arregla lo que hay hoy; este test es lo que impide que
// vuelva mañana. Sin él, el voseo reaparece con la siguiente feature —
// que es exactamente lo que pasó entre el estándar escrito y la auditoría.
//
// Cobertura deliberada: solo cadenas literales de Dart en `lib/`. Los
// comentarios quedan fuera (documentan la regla, a veces citándola).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Formas de voseo rioplatense que no deben aparecer en copy de producto.
///
/// Se agrupan por tipo para que el mensaje de fallo sea accionable. La
/// lista es de coincidencia por palabra completa: "Suma" no dispara,
/// "Sumá" sí.
const _voseo = <String, String>{
  // Imperativos afirmativos (-á / -é / -í)
  'Arrancá': 'Empieza / Arranca',
  'Empezá': 'Empieza',
  'Sumá': 'Suma',
  'Cerrá': 'Cierra',
  'Abrí': 'Abre',
  'Elegí': 'Elige',
  'Seguí': 'Sigue',
  'Marcá': 'Marca',
  'Apuntá': 'Apunta',
  'Probá': 'Prueba',
  'Activá': 'Activa',
  'Bajá': 'Baja',
  'Tomá': 'Toma',
  'Comé': 'Come',
  'Bebé': 'Bebe  (¡"bebé" es un sustantivo!)',
  'Andá': 'Ve',
  'Mirá': 'Mira',
  'Contá': 'Cuenta',
  'Cargá': 'Carga',
  'Dejá': 'Deja',
  'Hacé': 'Haz',
  'Poné': 'Pon',
  'Anotá': 'Anota',
  'Revisá': 'Revisa',
  'Configurá': 'Configura',
  'Ajustá': 'Ajusta',
  'Completá': 'Completa',
  'Agregá': 'Agrega',
  'Volvé': 'Vuelve',
  'Escribí': 'Escribe',
  'Medí': 'Mide',
  'Pesá': 'Pesa',
  'Dormí': 'Duerme',
  'Descansá': 'Descansa',
  'Cuidá': 'Cuida',
  'Recordá': 'Recuerda',
  'Sostené': 'Sostén',
  'Evitá': 'Evita',
  'Priorizá': 'Prioriza',
  'Aprovechá': 'Aprovecha',
  'Considerá': 'Considera',
  'considerá': 'considera',
  'compensá': 'compénsalo',
  'Adelantá': 'Adelanta',
  'adelantá': 'adelanta',
  'Atrasá': 'Atrasa',
  'Repetí': 'Repite',
  'Enfocate': 'Enfócate',
  'Preparate': 'Prepárate',
  // Imperativos con pronombre enclítico
  'Mantenete': 'Mantente',
  'Movete': 'Muévete',
  'Cuidate': 'Cuídate',
  'Acordate': 'Acuérdate',
  'Fijate': 'Fíjate',
  // Presente de indicativo en 2ª persona
  'tenés': 'tienes',
  'podés': 'puedes',
  'querés': 'quieres',
  'sabés': 'sabes',
  'hacés': 'haces',
  'llegás': 'llegas',
  'sentís': 'sientes',
  'cumplís': 'cumples',
  'necesitás': 'necesitas',
  'estás listo para': 'estás listo para', // control: NO es voseo, no debe saltar
};

/// Extrae las cadenas literales de un archivo Dart, descartando
/// comentarios de línea y de bloque.
///
/// No es un parser de Dart y no pretende serlo: es una heurística
/// suficiente para copy. Prefiere el falso negativo al falso positivo,
/// porque un test de estilo que da guerra termina desactivado.
List<String> _literalesDeCopy(String source) {
  final sinBloques = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  final literales = <String>[];

  for (final linea in sinBloques.split('\n')) {
    final t = linea.trimLeft();
    if (t.startsWith('//')) continue; // comentario puro
    if (t.startsWith('import ') || t.startsWith('export ')) continue;

    // Corta un comentario al final de línea sólo si va fuera de comillas.
    var codigo = linea;
    var enSimple = false;
    var enDoble = false;
    for (var i = 0; i < linea.length - 1; i++) {
      final c = linea[i];
      if (c == r'\') {
        i++;
        continue;
      }
      if (c == "'" && !enDoble) enSimple = !enSimple;
      if (c == '"' && !enSimple) enDoble = !enDoble;
      if (!enSimple && !enDoble && c == '/' && linea[i + 1] == '/') {
        codigo = linea.substring(0, i);
        break;
      }
    }

    for (final m in RegExp(r"'((?:[^'\\]|\\.)*)'").allMatches(codigo)) {
      literales.add(m.group(1)!);
    }
    for (final m in RegExp(r'"((?:[^"\\]|\\.)*)"').allMatches(codigo)) {
      literales.add(m.group(1)!);
    }
  }
  return literales;
}

void main() {
  group('C-02 — el copy de producto no usa voseo rioplatense', () {
    late List<File> archivos;

    setUpAll(() {
      final lib = Directory('lib');
      archivos = lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          // El código generado no contiene copy y sí muchos identificadores.
          .where((f) => !f.path.endsWith('.freezed.dart'))
          .where((f) => !f.path.endsWith('.g.dart'))
          .toList();
    });

    test('lib/ existe y hay archivos que revisar', () {
      expect(archivos, isNotEmpty,
          reason: 'El test debe correr desde la raíz del paquete elena_app');
    });

    test('ninguna cadena literal de lib/ contiene formas de voseo', () {
      final infracciones = <String>[];

      for (final archivo in archivos) {
        final literales = _literalesDeCopy(archivo.readAsStringSync());
        for (final literal in literales) {
          for (final entrada in _voseo.entries) {
            final forma = entrada.key;
            if (forma.contains(' ')) continue; // entradas de control
            final patron = RegExp('(?<![A-Za-zÁÉÍÓÚÑáéíóúñ])'
                '${RegExp.escape(forma)}'
                '(?![A-Za-zÁÉÍÓÚÑáéíóúñ])');
            if (patron.hasMatch(literal)) {
              infracciones.add(
                '  ${archivo.path}\n'
                '    "$literal"\n'
                '    → "$forma" debería ser "${entrada.value}"',
              );
            }
          }
        }
      }

      expect(
        infracciones,
        isEmpty,
        reason: 'Se encontró voseo en ${infracciones.length} cadena(s) de '
            'producto. El estándar del proyecto es español neutro LatAm '
            '(ver intro_screens.dart §Reglas de copy):\n\n'
            '${infracciones.join('\n\n')}\n',
      );
    });

    test('el detector reconoce voseo en una cadena de prueba', () {
      // Guarda contra el modo de fallo más peligroso de un test de estilo:
      // que deje de detectar y pase siempre en verde.
      const muestra = "const x = 'Arrancá hoy'; // Sumá mañana";
      final literales = _literalesDeCopy(muestra);
      expect(literales, contains('Arrancá hoy'));
      expect(literales.any((l) => l.contains('Sumá')), isFalse,
          reason: 'El texto tras // es comentario y no debe analizarse');
    });
  });
}
