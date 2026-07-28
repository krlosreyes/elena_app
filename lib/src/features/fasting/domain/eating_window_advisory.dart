// Auditoría 2026-07-27 — hallazgo I-06 / B-10.
//
// En ejecución real, la app mostraba un ayuno de 16h corriendo de 07:05 a
// 23:05. Es decir: guiaba al usuario a romper el ayuno —a comer— a las
// once de la noche.
//
// Eso contradice frontalmente al propio motor de scoring. `ScoreEngine`
// aplica `_kCircadianLockPenaltyScore = 0.5` a quien coma después del
// bloqueo intestinal (Lopez-Minguez 2018, melatonina-MTNR1B), y el
// componente circadiano pesa el 38% del bloque Conducta. La app proponía
// un horario que después castigaba, sin decirlo en ningún momento.
//
// Este helper es una función pura: no cambia el comportamiento del ayuno
// ni bloquea nada. Solo detecta la incoherencia para que la UI pueda
// advertirla y ofrecer una alternativa coherente con la propia ciencia
// que la app declara.

import 'package:elena_app/src/core/rules/circadian_rules.dart';

/// Resultado de evaluar si la ventana de alimentación que abriría un ayuno
/// respeta el cierre circadiano recomendado.
class EatingWindowAdvisory {
  const EatingWindowAdvisory({
    required this.crossesLock,
    required this.windowOpensAt,
    required this.suggestedTargetHours,
  });

  /// True si la ventana abriría DESPUÉS del bloqueo intestinal.
  final bool crossesLock;

  /// Momento en que el usuario rompería el ayuno con el objetivo actual.
  final DateTime windowOpensAt;

  /// Objetivo de ayuno (en horas) que dejaría la ventana abriendo antes
  /// del bloqueo. `null` cuando no existe alternativa razonable — por
  /// ejemplo, si haría falta un ayuno de menos de 12h, que ya no
  /// calificaría como ayuno intermitente.
  final int? suggestedTargetHours;

  /// Mínimo por debajo del cual no sugerimos acortar: por debajo de 12h no
  /// hay ventaja metabólica documentada (Mattson 2017) y proponerlo sería
  /// cambiar un problema por otro.
  static const int kMinimoSugeribleHoras = 12;

  /// Evalúa el ayuno que empieza en [start] con objetivo [targetHours].
  static EatingWindowAdvisory evaluate({
    required DateTime start,
    required int targetHours,
  }) {
    final abre = start.add(Duration(hours: targetHours));
    final minutosDeCierre = CircadianRules.intestinalLockMinutes;
    final minutosDeApertura = abre.hour * 60 + abre.minute;

    // Solo es incoherencia si la apertura cae el MISMO día natural que el
    // cierre y ya lo pasó. Una ventana que abre a las 08:00 del día
    // siguiente no cruza nada.
    final mismoDia = abre.day == start.day && abre.month == start.month;
    final cruza = mismoDia && minutosDeApertura >= minutosDeCierre;

    if (!cruza) {
      return EatingWindowAdvisory(
        crossesLock: false,
        windowOpensAt: abre,
        suggestedTargetHours: null,
      );
    }

    // Objetivo que dejaría la ventana abriendo justo en el cierre o antes.
    final minutosDeInicio = start.hour * 60 + start.minute;
    final horasHastaCierre = (minutosDeCierre - minutosDeInicio) / 60.0;
    final sugerido = horasHastaCierre.floor();

    return EatingWindowAdvisory(
      crossesLock: true,
      windowOpensAt: abre,
      suggestedTargetHours: sugerido >= kMinimoSugeribleHoras ? sugerido : null,
    );
  }

  /// Hora de cierre recomendada, formateada como "21:30".
  static String get horaDeCierreFormateada {
    final m = CircadianRules.intestinalLockMinutes;
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final min = (m % 60).toString().padLeft(2, '0');
    return '$h:$min';
  }

  /// Mensaje listo para mostrar, o `null` si no hay nada que advertir.
  ///
  /// Deliberadamente en primera persona del producto y sin alarmismo: es
  /// una recomendación, no un bloqueo. El usuario manda sobre su ayuno.
  String? get mensaje {
    if (!crossesLock) return null;
    final h = windowOpensAt.hour.toString().padLeft(2, '0');
    final m = windowOpensAt.minute.toString().padLeft(2, '0');
    final base = 'Con este objetivo romperías el ayuno a las $h:$m, después '
        'del cierre recomendado de las $horaDeCierreFormateada.';
    if (suggestedTargetHours == null) return base;
    return '$base Un objetivo de ${suggestedTargetHours}h cerraría tu '
        'ventana a tiempo.';
  }
}
