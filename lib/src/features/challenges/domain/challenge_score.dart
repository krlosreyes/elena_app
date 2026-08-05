// SPEC-263: puntaje de un miembro en un reto.

class ChallengeScore {
  final String uid;
  final String displayName;

  /// Días que califican en el período (constancia).
  final int points;

  const ChallengeScore({
    required this.uid,
    required this.displayName,
    required this.points,
  });
}
