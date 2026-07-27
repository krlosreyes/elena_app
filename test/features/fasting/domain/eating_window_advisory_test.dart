// Auditoría 2026-07-27 — hallazgo I-06 / B-10.
//
// Caso observado en ejecución: ayuno de 16h iniciado a las 07:05, con la
// ventana de alimentación abriendo a las 23:05. La app guiaba a comer a
// las once de la noche mientras su propio ScoreEngine penaliza al 50% el
// componente circadiano de quien come después del bloqueo intestinal.

import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/features/fasting/domain/eating_window_advisory.dart';

void main() {
  group('I-06 — aviso de ventana que cruza el cierre circadiano', () {
    test('reproduce el caso observado: 16h desde las 07:05 abre a las 23:05',
        () {
      final a = EatingWindowAdvisory.evaluate(
        start: DateTime(2026, 7, 27, 7, 5),
        targetHours: 16,
      );

      expect(a.crossesLock, isTrue);
      expect(a.windowOpensAt, DateTime(2026, 7, 27, 23, 5));
      expect(a.mensaje, isNotNull);
      expect(a.mensaje, contains('23:05'));
      expect(a.mensaje, contains(EatingWindowAdvisory.horaDeCierreFormateada));
    });

    test('propone un objetivo alternativo que sí cierra a tiempo', () {
      final a = EatingWindowAdvisory.evaluate(
        start: DateTime(2026, 7, 27, 7, 5),
        targetHours: 16,
      );

      expect(a.suggestedTargetHours, isNotNull);

      // La alternativa propuesta debe, ella misma, respetar el cierre.
      final conAlternativa = EatingWindowAdvisory.evaluate(
        start: DateTime(2026, 7, 27, 7, 5),
        targetHours: a.suggestedTargetHours!,
      );
      expect(conAlternativa.crossesLock, isFalse,
          reason: 'la sugerencia no puede cruzar el mismo cierre que evita');
    });

    test('un ayuno nocturno bien planteado NO dispara aviso', () {
      // 16h desde las 20:00 → abre a las 12:00 del día siguiente.
      final a = EatingWindowAdvisory.evaluate(
        start: DateTime(2026, 7, 27, 20, 0),
        targetHours: 16,
      );
      expect(a.crossesLock, isFalse);
      expect(a.mensaje, isNull);
    });

    test('una ventana que abre justo antes del cierre no dispara aviso', () {
      final cierre = CircadianRules.intestinalLockMinutes;
      final inicio = DateTime(2026, 7, 27, 5, 0);
      // Objetivo que hace abrir 1 minuto ANTES del cierre.
      final minutosDeseados = cierre - (5 * 60) - 1;
      final a = EatingWindowAdvisory.evaluate(
        start: inicio,
        targetHours: minutosDeseados ~/ 60,
      );
      expect(a.crossesLock, isFalse);
    });

    test('no sugiere acortar por debajo del mínimo de 12h', () {
      // Inicio muy tardío: cualquier alternativa quedaría por debajo del
      // umbral con ventaja metabólica documentada.
      final a = EatingWindowAdvisory.evaluate(
        start: DateTime(2026, 7, 27, 15, 0),
        targetHours: 8,
      );
      expect(a.crossesLock, isTrue);
      expect(a.suggestedTargetHours, isNull,
          reason: 'proponer <12h cambiaría un problema por otro');
      // Aun sin alternativa, la advertencia debe existir.
      expect(a.mensaje, isNotNull);
    });

    test('el aviso NUNCA bloquea: solo informa', () {
      final a = EatingWindowAdvisory.evaluate(
        start: DateTime(2026, 7, 27, 7, 5),
        targetHours: 16,
      );
      // El contrato es una recomendación redactada, no un flag de bloqueo.
      expect(a.mensaje, isA<String>());
      expect(a.mensaje!.toLowerCase(), isNot(contains('no puedes')));
      expect(a.mensaje!.toLowerCase(), isNot(contains('prohibid')));
    });

    test('horaDeCierreFormateada se deriva de CircadianRules, no de un literal',
        () {
      final m = CircadianRules.intestinalLockMinutes;
      final esperada = '${(m ~/ 60).toString().padLeft(2, '0')}:'
          '${(m % 60).toString().padLeft(2, '0')}';
      expect(EatingWindowAdvisory.horaDeCierreFormateada, esperada);
    });
  });
}
