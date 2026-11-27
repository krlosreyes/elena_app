// 22-nov-2026 — Retos se oculta en la 1.0 (guía 1.2 de App Store: hay
// interacción entre usuarios sin reportar ni bloquear). Estos tests evitan
// que vuelva a aparecer por accidente mientras el flag esté apagado.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/core/config/feature_flags.dart';
import 'package:elena_app/src/features/badges/domain/badge_definition.dart';

String _sinComentarios(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  test('Retos está apagado para esta versión', () {
    expect(kRetosEnabled, isFalse,
        reason: 'Antes de encenderlo: reportar, bloquear, salir del reto y '
            'filtro de palabras (ver feature_flags.dart).');
  });

  test('las insignias de Retos no cuentan ni se muestran', () {
    expect(
        BadgeCatalog.visibleCategories, isNot(contains(BadgeCategory.retos)));
    expect(BadgeCatalog.visible.where((d) => d.category == BadgeCategory.retos),
        isEmpty);
    expect(BadgeCatalog.visible.length, lessThan(BadgeCatalog.all.length));
  });

  test('el acceso en Progreso y la ruta dependen del flag', () {
    final progreso = _sinComentarios(
        'lib/src/features/analysis/presentation/analysis_screen.dart');
    expect(progreso, contains('if (kRetosEnabled)'));
    final router = _sinComentarios('lib/src/router/app_router.dart');
    expect(router, contains("kRetosEnabled ? null : '/analysis'"));
  });

  test('ningún otro sitio de la app navega a /retos sin pasar por el flag', () {
    final fallos = <String>[];
    for (final f
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final ruta = f.path.replaceAll(r'\', '/');
      if (!ruta.endsWith('.dart')) continue;
      if (ruta.contains('/features/challenges/')) continue;
      if (ruta.endsWith('app_router.dart')) continue;
      final src = _sinComentarios(ruta);
      final navega =
          RegExp(r"(push|go|pushReplacement)\('/retos").hasMatch(src);
      if (navega && !src.contains('kRetosEnabled')) {
        fallos.add(ruta);
      }
    }
    expect(fallos, isEmpty);
  });
}
