// SPEC-263: reto de constancia (competencia social sana).
//
// Un reto es un período con un grupo de miembros que compiten por CONSTANCIA
// (días que califican para la racha), NO por peso — decisión de salud: premiar
// el hábito, no la báscula. El value object es inmutable; la puntuación de
// cada quien sale de SU propio historial real (ver challenge_scoring.dart).

/// Estado del reto según la fecha de hoy.
enum ChallengeStatus { upcoming, active, ended }

class Challenge {
  /// Código de invitación — es también el id del documento en Firestore.
  final String code;
  final String name;
  final String ownerId;
  final String ownerName;

  /// Fechas en 'yyyy-MM-dd' (mismo formato que StreakEntry.date → comparables
  /// lexicográficamente).
  final String startDateKey;
  final String endDateKey;

  final List<String> memberIds;

  const Challenge({
    required this.code,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.startDateKey,
    required this.endDateKey,
    required this.memberIds,
  });

  bool isMember(String uid) => memberIds.contains(uid);

  int get memberCount => memberIds.length;

  ChallengeStatus statusOn(String todayKey) {
    if (todayKey.compareTo(startDateKey) < 0) return ChallengeStatus.upcoming;
    if (todayKey.compareTo(endDateKey) > 0) return ChallengeStatus.ended;
    return ChallengeStatus.active;
  }

  Challenge copyWith({List<String>? memberIds}) => Challenge(
        code: code,
        name: name,
        ownerId: ownerId,
        ownerName: ownerName,
        startDateKey: startDateKey,
        endDateKey: endDateKey,
        memberIds: memberIds ?? this.memberIds,
      );
}
