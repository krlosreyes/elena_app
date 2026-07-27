// Auditoría 2026-07-27 — hallazgo C-01.
//
// Antes de este test existían cinco definiciones divergentes de la misma
// taxonomía de fases del ayuno. En ejecución real, con 17 minutos de ayuno
// acumulados, el Dashboard mostraba simultáneamente:
//
//   anillo   → "Quema de grasa en 11h 43m"
//   tarjeta  → "Descenso de insulina en 11h 42m"
//
// Dos afirmaciones fisiológicas distintas para el mismo instante, y ninguna
// coincidente con el enum canónico `FastingPhase`, que sitúa la cetosis
// nutricional entre las 18 y las 24 horas.
//
// Este test barre el ayuno completo de 0 a 50 horas en pasos de 30 minutos y
// afirma que la clasificación, el countdown y las etiquetas salen todos del
// mismo sitio. Debe fallar si alguien vuelve a hardcodear un umbral
// fisiológico fuera del dominio.

import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/fasting/domain/fasting_benefits.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';

FastingState _stateAt(Duration d) => FastingState(
      startTime: DateTime(2026, 7, 27, 7, 5),
      duration: d,
      isActive: true,
      fastingProtocol: '16:8',
      phase: FastingState.determinePhase(d),
    );

void main() {
  group('C-01 — coherencia de la taxonomía de fases del ayuno', () {
    test('los umbrales del enum son estrictamente crecientes', () {
      const orden = [
        FastingPhase.postAbsorption,
        FastingPhase.transition,
        FastingPhase.fatBurning,
        FastingPhase.autophagy,
        FastingPhase.survival,
      ];
      for (var i = 1; i < orden.length; i++) {
        expect(
          orden[i].startsAt,
          greaterThan(orden[i - 1].startsAt),
          reason: '${orden[i].name} debe empezar después de ${orden[i - 1].name}',
        );
      }
    });

    test('los umbrales coinciden con IMR_BIBLIOGRAPHY.md (12/18/24/48h)', () {
      expect(FastingPhase.postAbsorption.startsAt, Duration.zero);
      expect(FastingPhase.transition.startsAt, const Duration(hours: 12));
      expect(FastingPhase.fatBurning.startsAt, const Duration(hours: 18));
      expect(FastingPhase.autophagy.startsAt, const Duration(hours: 24));
      expect(FastingPhase.survival.startsAt, const Duration(hours: 48));
    });

    test(
      'determinePhase clasifica en la fase cuyo umbral se acaba de cruzar, '
      'de 0 a 50h en pasos de 30 min',
      () {
        for (var m = 0; m <= 50 * 60; m += 30) {
          final d = Duration(minutes: m);
          final phase = FastingState.determinePhase(d);

          expect(
            d,
            greaterThanOrEqualTo(phase.startsAt),
            reason: 'a los ${d.inMinutes} min se clasificó como ${phase.name}, '
                'cuyo umbral de entrada es ${phase.startsAt.inHours}h',
          );

          final siguiente = switch (phase) {
            FastingPhase.postAbsorption => FastingPhase.transition,
            FastingPhase.transition => FastingPhase.fatBurning,
            FastingPhase.fatBurning => FastingPhase.autophagy,
            FastingPhase.autophagy => FastingPhase.survival,
            _ => null,
          };
          if (siguiente != null) {
            expect(
              d,
              lessThan(siguiente.startsAt),
              reason: 'a los ${d.inMinutes} min todavía no debería estar en '
                  '${siguiente.name}',
            );
          }
        }
      },
    );

    test(
      'el hito anunciado NUNCA es la fase en la que el usuario ya está '
      '(error de índice histórico)',
      () {
        for (var m = 0; m <= 50 * 60; m += 30) {
          final s = _stateAt(Duration(minutes: m));
          final next = s.nextPhase;
          if (next == null) continue;
          expect(
            next,
            isNot(s.phase),
            reason: 'a los ${m}min se anuncia como próximo hito la fase actual',
          );
          expect(
            next.milestoneName,
            isNot(s.phase.milestoneName),
            reason: 'a los ${m}min el nombre del hito repite el de la fase actual',
          );
        }
      },
    );

    test('el countdown apunta siempre al umbral de la fase anunciada', () {
      for (var m = 0; m <= 50 * 60; m += 30) {
        final d = Duration(minutes: m);
        final s = _stateAt(d);
        final next = s.nextPhase;
        if (next == null) {
          expect(s.timeRemainingForNextMilestone, Duration.zero);
          continue;
        }
        expect(
          s.timeRemainingForNextMilestone,
          next.startsAt - d,
          reason: 'a los ${m}min el countdown no coincide con el umbral de '
              '${next.name} (${next.startsAt.inHours}h)',
        );
        expect(s.timeRemainingForNextMilestone, isNot(Duration.zero));
      }
    });

    test(
      'el anillo y la tarjeta del Dashboard anuncian el MISMO hito '
      '(reproduce el bug observado a los 17 min)',
      () {
        for (var m = 0; m <= 50 * 60; m += 30) {
          final s = _stateAt(Duration(minutes: m));

          // fasting_hero_display._friendlyMilestone
          final anillo = s.phase.next?.milestoneName ?? 'Próximo hito';
          // fasting_consciousness_card._formatNextMilestone
          final tarjeta = s.nextPhase?.milestoneName ?? 'Próximo hito';

          expect(
            anillo,
            tarjeta,
            reason: 'a los ${m}min el anillo dice "$anillo" y la tarjeta '
                '"$tarjeta"',
          );
        }
      },
    );

    test(
      'a los 17 minutos de ayuno NO se afirma quema de grasa ni autofagia',
      () {
        final s = _stateAt(const Duration(minutes: 17));

        expect(s.phase, FastingPhase.postAbsorption);
        expect(s.nextPhase, FastingPhase.transition);
        expect(s.nextPhase!.milestoneName, 'Inicio de cetogénesis');
        expect(s.timeRemainingForNextMilestone,
            const Duration(hours: 12) - const Duration(minutes: 17));

        final beneficios = FastingBenefits.benefitsFor(s.phase, s.duration);
        for (final b in beneficios) {
          final lower = b.toLowerCase();
          expect(lower.contains('cetosis'), isFalse, reason: b);
          expect(lower.contains('autofagia'), isFalse, reason: b);
          expect(lower.contains('quema'), isFalse, reason: b);
        }
      },
    );

    test('nextMilestoneLabel construye la hora desde el umbral del enum', () {
      expect(
        _stateAt(const Duration(hours: 2)).nextMilestoneLabel,
        'SIGUIENTE ETAPA: INICIO DE CETOGÉNESIS (12H)',
      );
      expect(
        _stateAt(const Duration(hours: 14)).nextMilestoneLabel,
        'SIGUIENTE ETAPA: QUEMA DE GRASA (18H)',
      );
      expect(
        _stateAt(const Duration(hours: 20)).nextMilestoneLabel,
        'SIGUIENTE ETAPA: AUTOFAGIA (24H)',
      );
      expect(
        _stateAt(const Duration(hours: 30)).nextMilestoneLabel,
        'FASE DE REGENERACIÓN PROFUNDA',
      );
    });

    test(
      'un ayuno de 48h+ NUNCA se anuncia como meta (requiere supervisión '
      'médica)',
      () {
        expect(FastingPhase.autophagy.next, isNull);
        expect(FastingPhase.survival.next, isNull);
        for (var m = 24 * 60; m <= 50 * 60; m += 30) {
          expect(_stateAt(Duration(minutes: m)).nextPhase, isNull);
        }
      },
    );

    test('los beneficios mostrados corresponden a la fase real', () {
      expect(
        FastingBenefits.benefitsFor(
            FastingPhase.fatBurning, const Duration(hours: 19)),
        contains(startsWith('Cetosis nutricional activa')),
      );
      expect(
        FastingBenefits.benefitsFor(
            FastingPhase.autophagy, const Duration(hours: 26)),
        contains(startsWith('Autofagia activa')),
      );
    });
  });
}
