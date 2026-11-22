// SPEC-305 — integridad del catálogo de fuentes científicas.
//
// App Review rechazó la 1.0 por la guía 1.4.1: cálculos de salud sin citas
// con enlace. El catálogo es lo que respalda cada cálculo; si una entrada
// se rompe (enlace vacío, http, dominio raro, id repetido), la protección
// desaparece sin que nadie lo note. Estos tests lo impiden.

import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/science/domain/scientific_source.dart';

/// Dominios aceptados para un enlace de fuente. Son repositorios estables
/// (PubMed, DOI), organismos oficiales o la editorial del libro. Un dominio
/// nuevo exige revisarlo a mano y añadirlo aquí a propósito.
const _allowedHosts = {
  'pubmed.ncbi.nlm.nih.gov',
  'doi.org',
  'iris.who.int',
  'apps.dtic.mil',
  'www.nobelprize.org',
  'www.acefitness.org',
  'www.wolterskluwer.com',
  'openlibrary.org',
};

List<String> _ids(List<ScientificSource> list) =>
    list.map((s) => s.id).toList();

void main() {
  group('Catálogo', () {
    const all = ScientificSources.all;

    test('no está vacío y los ids son únicos', () {
      expect(all, isNotEmpty);
      expect(_ids(all).toSet().length, all.length,
          reason: 'Hay ids repetidos en ScientificSources.all');
    });

    test('las constantes declaradas están todas en `all`', () {
      // Si alguien añade una fuente y olvida listarla, la pantalla de
      // "Fuentes científicas" no la mostraría.
      for (final group in [
        ScientificSources.bodyFat,
        ScientificSources.bodyComposition,
        ScientificSources.fastingEligibility,
        ScientificSources.glucose,
        ScientificSources.sleepStages,
        ScientificSources.fivePillars,
      ]) {
        for (final s in group) {
          expect(all, contains(s), reason: '${s.id} no está en `all`');
        }
      }
    });

    test('cada fuente tiene enlace https a un dominio confiable', () {
      for (final s in all) {
        final uri = Uri.parse(s.url);
        expect(uri.scheme, 'https', reason: '${s.id}: ${s.url}');
        expect(_allowedHosts, contains(uri.host),
            reason: '${s.id}: dominio ${uri.host} no está en la lista '
                'revisada. Verifica el enlace y añádelo a _allowedHosts.');
      }
    });

    test('los enlaces de PubMed apuntan a un PMID concreto', () {
      final pmid = RegExp(r'^https://pubmed\.ncbi\.nlm\.nih\.gov/\d{6,8}/$');
      for (final s in all.where((s) => s.url.contains('pubmed'))) {
        expect(pmid.hasMatch(s.url), isTrue, reason: '${s.id}: ${s.url}');
      }
    });

    test('ningún campo visible está vacío y el año es plausible', () {
      for (final s in all) {
        expect(s.shortLabel.trim(), isNotEmpty, reason: s.id);
        expect(s.authors.trim(), isNotEmpty, reason: s.id);
        expect(s.title.trim(), isNotEmpty, reason: s.id);
        expect(s.venue.trim(), isNotEmpty, reason: s.id);
        expect(s.supports.trim(), isNotEmpty, reason: s.id);
        expect(s.matchTerms, isNotEmpty, reason: s.id);
        expect(s.year, inInclusiveRange(1900, DateTime.now().year),
            reason: s.id);
      }
    });

    test('los términos de búsqueda ya vienen normalizados', () {
      for (final s in all) {
        for (final t in s.matchTerms) {
          expect(ScientificSources.normalize(t), t,
              reason: '${s.id}: "$t" debe escribirse en minúsculas, sin '
                  'tildes ni signos, para que el match funcione');
        }
      }
    });

    test('todas las categorías tienen al menos una fuente', () {
      for (final c in SourceCategory.values) {
        expect(all.where((s) => s.category == c), isNotEmpty,
            reason: 'La categoría ${c.label} quedaría vacía en pantalla');
      }
    });

    test('byId encuentra cada fuente y devuelve null si no existe', () {
      for (final s in all) {
        expect(ScientificSources.byId(s.id), same(s));
      }
      expect(ScientificSources.byId('no-existe'), isNull);
    });

    test('ninguna fuente del catálogo es un respaldo prohibido', () {
      for (final s in all) {
        expect(
            ScientificSources.mentionsForbidden(
                '${s.shortLabel} ${s.authors} ${s.title}'),
            isFalse,
            reason: s.id);
      }
    });
  });

  group('Resolución de citas cortas', () {
    List<String> resolve(String c) => _ids(ScientificSources.resolve(c));

    test('separa por "+" y por "·"', () {
      expect(resolve('Walker 2017 + AASM'), ['walker_2017', 'watson_2015']);
      expect(resolve('· Hall 2019 · Monteiro 2019'),
          ['hall_2019', 'monteiro_2019']);
    });

    test('el año desambigua al mismo autor', () {
      expect(resolve('Spiegel 1999, Lancet'), ['spiegel_1999']);
      expect(resolve('Spiegel et al., Ann Intern Med 2004'), ['spiegel_2004']);
      expect(resolve('Jenkins 1981 + Jenkins 2002'),
          ['jenkins_1981', 'jenkins_2002']);
    });

    test('la coma y la raya no parten una cita', () {
      expect(resolve('Tasali et al., PNAS 2008'), ['tasali_2008']);
      expect(resolve('· Gu et al., 2020 — JCEM'), ['gu_2020']);
      expect(resolve('· Cahill, 1966 — J Clin Invest'), ['cahill_1966']);
    });

    test('OMS distingue IMC (2000) de actividad física (2020)', () {
      expect(resolve('OMS 150 min/sem + Mattson 2017'),
          ['who_2020', 'mattson_2017']);
      expect(resolve('Fuentes: OMS 2000 · de Cabo & Mattson 2019'),
          ['who_bmi', 'decabo_2019']);
    });

    test('las citas visibles en pantallas de cálculo resuelven', () {
      expect(resolve('Fórmula US Navy — Hodgdon & Beckett, 1984'),
          ['navy_men', 'navy_women']);
      expect(
          resolve('Rangos ACE (hombre) — Atlético <14, Fitness 14-17, '
              'Promedio 18-24, Alto >=25'),
          ['ace_body_fat']);
    });

    test('una etiqueta que no es cita no genera enlace ni error', () {
      expect(resolve('· Basado en tu progreso'), isEmpty);
      expect(ScientificSources.unresolvedSegments('· Basado en tu progreso'),
          isEmpty);
    });

    test('una cita desconocida o prohibida queda sin resolver', () {
      expect(ScientificSources.unresolvedSegments('Fulano 2031'),
          ['Fulano 2031']);
      expect(
          ScientificSources.unresolvedSegments(
              'Sutton 2018 + Frank Suárez §3'),
          ['Frank Suárez §3']);
      expect(ScientificSources.mentionsForbidden('Frank Suárez (Tipo A/E)'),
          isTrue);
      expect(ScientificSources.mentionsForbidden('Huberman 2021'), isTrue);
    });
  });
}
