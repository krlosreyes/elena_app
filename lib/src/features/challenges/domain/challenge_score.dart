// SPEC-263 / SPEC-264: puntaje de un miembro en un reto.

import 'package:elena_app/src/features/challenges/domain/challenge_rings.dart';

class ChallengeScore {
  final String uid;
  final String displayName;

  /// SPEC-264: puntos por pilar acumulados en el período (cada anillo cerrado
  /// suma 1; máx 5/día).
  final int points;

  /// SPEC-264: anillos (5 pilares) del día de hoy — lo que ve el rival.
  final ChallengeRings todayRings;

  /// SPEC-264: si hoy ya calificó para su racha (para el zumbido contextual).
  final bool qualifiedToday;

  const ChallengeScore({
    required this.uid,
    required this.displayName,
    required this.points,
    this.todayRings = ChallengeRings.empty,
    this.qualifiedToday = false,
  });
}
