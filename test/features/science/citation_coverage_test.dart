// SPEC-305 — blindaje contra la guía 1.4.1 de App Store.
//
// 22-nov-2026: App Review rechazó la 1.0 porque la app mostraba cálculos de
// salud sin citas con enlace. El arreglo puntual (bloques de fuentes y una
// pantalla de "Fuentes científicas") resuelve lo de hoy; este test es lo
// que impide que vuelva a pasar con la próxima feature.
//
// Qué garantiza, barriendo todo `lib/`:
//   1. Cada `citation:` de un insight resuelve, parte por parte, a una fuente
//      del catálogo (con enlace). "Walker 2017 + Fulano 2031" falla.
//   2. Cada cita "Autor AAAA" escrita dentro de un texto visible también
//      resuelve ("…respaldado por Ashwell et al. (2012)…").
//   3. Ningún texto visible usa un respaldo prohibido (marcas comerciales,
//      podcasts, documentos internos).
//   4. Las pantallas que muestran cálculos de salud siguen mostrando sus
//      fuentes.
//
// Cómo arreglar un fallo: añade la fuente a
// lib/src/features/science/domain/scientific_source.dart (con un enlace que
// hayas abierto y comprobado) o corrige la cita.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/science/domain/scientific_source.dart';

const _catalogPath = 'lib/src/features/science/domain/scientific_source.dart';

/// Pantallas que muestran un cálculo de salud. Cada una debe pintar sus
/// fuentes (SourcesFooter, CitationLink o showSourcesSheet). Si alguien
/// quita el bloque, App Review vuelve a tener motivo de rechazo.
const _calculationScreens = <String, String>{
  'lib/src/features/profile/presentation/body_composition_screen.dart':
      '% grasa, cintura-estatura, FFMI',
  'lib/src/features/auth/presentation/biometricos_detail_screen.dart':
      '% grasa estimado',
  'lib/src/features/analysis/presentation/widgets/body_silhouette.dart':
      'zonas de % grasa',
  'lib/src/features/analysis/presentation/resultados_detail_screen.dart':
      'composición corporal e IMR',
  'lib/src/features/analysis/presentation/daily_score_detail_screen.dart':
      'Score del día',
  'lib/src/features/dashboard/presentation/widgets/protocol_selector_sheet.dart':
      'tope de protocolo por IMC',
  'lib/src/features/dashboard/presentation/widgets/fasting_consciousness_card.dart':
      'bloqueo del ayuno por IMC',
  'lib/src/features/onboarding/presentation/onboarding_screen.dart':
      'medidas y cribado médico',
  'lib/src/features/auth/presentation/disclaimer_screen.dart':
      'poblaciones de riesgo',
  'lib/src/features/glucose/presentation/glucose_detail_screen.dart':
      'variabilidad glucémica',
  'lib/src/features/sleep/presentation/widgets/sleep_stages_view.dart':
      'etapas de sueño',
};

/// Palabras que la heurística de "Autor AAAA" confunde con autores porque
/// son nombres de revista ("Tasali et al., PNAS 2008").
const _venueWords = {
  'PNAS', 'Chest', 'Med', 'Care', 'Lancet', 'Rev', 'Metab', 'NEJM', 'JCEM',
  'Invest', 'Psychol', 'Nutr', 'Sci', 'Medicina', 'Fisiología', 'Physiol',
  'Open',
};

final _inlineCitation = RegExp(
  r'(?<![A-Za-zÀ-ÿ])'
  r'([A-ZÁÉÍÓÚ][A-Za-zÀ-ÿ\-]+'
  r'(?:\s(?:&|y)\s[A-Z][A-Za-zÀ-ÿ\-]+|\set al\.?)?)'
  r',?\s\(?((?:19|20)\d{2})\)?',
);

final _citationField =
    RegExp(r"citation\s*[:=]\s*\n?\s*'((?:[^'\\]|\\.)*)'");

String _sinComentarios(String source) {
  final sinBloques = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return sinBloques
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('//'))
      .join('\n');
}

/// Cadenas literales de un archivo, sin comentarios. Misma heurística que
/// test/core/copy/no_voseo_test.dart.
List<String> _literales(String source) {
  final sinBloques = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  final out = <String>[];
  for (final linea in sinBloques.split('\n')) {
    final t = linea.trimLeft();
    if (t.startsWith('//')) continue;
    if (t.startsWith('import ') || t.startsWith('export ')) continue;
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
      out.add(m.group(1)!);
    }
    for (final m in RegExp(r'"((?:[^"\\]|\\.)*)"').allMatches(codigo)) {
      out.add(m.group(1)!);
    }
  }
  return out;
}

void main() {
  late List<File> archivos;

  setUpAll(() {
    archivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.endsWith('.freezed.dart'))
        // El catálogo nombra los respaldos prohibidos a propósito.
        .where((f) => f.path.replaceAll(r'\', '/') != _catalogPath)
        .toList();
  });

  test('hay archivos que revisar (el test corre desde elena_app/)', () {
    expect(archivos, isNotEmpty);
  });

  test('cada `citation:` resuelve a fuentes con enlace, parte por parte', () {
    final fallos = <String>[];
    for (final f in archivos) {
      final src = _sinComentarios(f.readAsStringSync());
      for (final m in _citationField.allMatches(src)) {
        final cita = m.group(1)!;
        if (cita.isEmpty || cita.contains(r'$')) continue;
        final sinFuente = ScientificSources.unresolvedSegments(cita);
        if (sinFuente.isNotEmpty) {
          fallos.add('  ${f.path}\n    "$cita" → sin fuente: $sinFuente');
        }
      }
    }
    expect(fallos, isEmpty,
        reason: 'Citas sin fuente en el catálogo (guía 1.4.1):\n'
            '${fallos.join('\n')}');
  });

  test('cada "Autor AAAA" dentro de un texto visible resuelve', () {
    final fallos = <String>[];
    for (final f in archivos) {
      for (final lit in _literales(f.readAsStringSync())) {
        for (final m in _inlineCitation.allMatches(lit)) {
          final primera = m.group(1)!.split(RegExp(r'\s')).first;
          if (_venueWords.contains(primera)) continue;
          final frag = m.group(0)!;
          if (ScientificSources.resolveSegment(frag).isEmpty) {
            fallos.add('  ${f.path}\n    "$frag"  en  "$lit"');
          }
        }
      }
    }
    expect(fallos, isEmpty,
        reason: 'Citas en texto sin fuente en el catálogo:\n'
            '${fallos.join('\n')}');
  });

  test('ningún texto visible usa un respaldo prohibido', () {
    final fallos = <String>[];
    for (final f in archivos) {
      for (final lit in _literales(f.readAsStringSync())) {
        if (ScientificSources.mentionsForbidden(lit)) {
          fallos.add('  ${f.path}\n    "$lit"');
        }
      }
    }
    expect(fallos, isEmpty,
        reason: 'Respaldo no verificable en texto visible (marca, podcast '
            'o documento interno):\n${fallos.join('\n')}');
  });

  test('las pantallas de cálculo siguen mostrando sus fuentes', () {
    final fallos = <String>[];
    _calculationScreens.forEach((ruta, que) {
      final f = File(ruta);
      if (!f.existsSync()) {
        fallos.add('  $ruta ($que) — el archivo ya no existe; actualiza '
            'la lista si se movió');
        return;
      }
      final src = _sinComentarios(f.readAsStringSync());
      final muestra = src.contains('SourcesFooter(') ||
          src.contains('CitationLink(') ||
          src.contains('showSourcesSheet(');
      if (!muestra) fallos.add('  $ruta ($que)');
    });
    expect(fallos, isEmpty,
        reason: 'Pantallas con cálculos de salud sin fuentes visibles:\n'
            '${fallos.join('\n')}');
  });

  test('las fuentes se alcanzan desde Perfil y tienen ruta propia', () {
    final perfil = _sinComentarios(
        File('lib/src/features/auth/presentation/profile_screen.dart')
            .readAsStringSync());
    expect(perfil, contains("'/profile/fuentes'"),
        reason: 'Perfil debe tener la fila "Fuentes científicas"');
    final router =
        _sinComentarios(File('lib/src/router/app_router.dart').readAsStringSync());
    expect(router, contains('ScientificSourcesScreen.routePath'));
  });
}
