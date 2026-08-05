// SPEC-264: qué insignias de reto corresponden dado el récord del usuario.
//
// Función PURA (sin I/O). El controlador la usa al cierre de un reto para
// otorgar, a través del sistema de insignias existente, las que aún no tenga.
// Se enganchan a la categoría `retos` de BadgeCategory (whitelist en
// firestore.rules).

abstract final class RetoBadges {
  static const String category = 'retos';

  /// Ids (deterministas) de insignias de reto que corresponden a estos conteos.
  /// Son acumulativas: una vez alcanzado el umbral, la insignia es permanente.
  static Set<String> earnedIds({
    required int joined,
    required int finished,
    required int won,
    required int rematches,
  }) {
    final ids = <String>{};
    if (joined >= 1) ids.add('retos_participar');
    if (finished >= 1) ids.add('retos_terminar');
    if (won >= 1) ids.add('retos_ganar_1');
    if (won >= 3) ids.add('retos_ganar_3');
    if (won >= 10) ids.add('retos_ganar_10');
    if (rematches >= 3) ids.add('retos_revancha');
    return ids;
  }

  /// Nivel de cada insignia (para EarnedBadge.level y orden en la galería).
  static int levelFor(String badgeId) => switch (badgeId) {
        'retos_participar' => 1,
        'retos_terminar' => 2,
        'retos_ganar_1' => 3,
        'retos_ganar_3' => 4,
        'retos_ganar_10' => 5,
        'retos_revancha' => 6,
        _ => 1,
      };
}
