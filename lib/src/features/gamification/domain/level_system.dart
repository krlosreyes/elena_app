// SPEC-262: curva de niveles a partir del XP total. Puro y determinístico.
//
// XP acumulado para ESTAR en el nivel L:  cumXp(L) = 100 · L · (L−1).
//   nivel 1 → 0 XP, nivel 2 → 200, nivel 3 → 600, … nivel 8 → 5600.
// El XP que exige un nivel es cumXp(L+1) − cumXp(L) = 200·L (crece con el
// nivel: cada nivel cuesta más que el anterior).

/// Foto del nivel para un XP dado. `progress` es 0..1 para la barra.
class LevelInfo {
  final int level;
  final String title;

  /// XP acumulado DENTRO del nivel actual.
  final int xpIntoLevel;

  /// XP total que exige el nivel actual (ancho de la barra).
  final int xpForNext;

  final int totalXp;

  const LevelInfo({
    required this.level,
    required this.title,
    required this.xpIntoLevel,
    required this.xpForNext,
    required this.totalXp,
  });

  double get progress =>
      xpForNext <= 0 ? 1.0 : (xpIntoLevel / xpForNext).clamp(0.0, 1.0);
}

abstract final class LevelSystem {
  /// XP acumulado necesario para estar en el nivel [level] (nivel 1 = 0).
  static int cumulativeXpForLevel(int level) {
    if (level <= 1) return 0;
    return 100 * level * (level - 1);
  }

  /// Nivel correspondiente a un XP total.
  static int levelForXp(int totalXp) {
    if (totalXp <= 0) return 1;
    var level = 1;
    while (cumulativeXpForLevel(level + 1) <= totalXp) {
      level++;
    }
    return level;
  }

  /// Títulos por nivel. Del 9 en adelante: "Leyenda".
  static const List<String> _titles = [
    'Novato',
    'Aprendiz',
    'Constante',
    'Disciplinado',
    'Experto',
    'Maestro',
    'Élite',
    'Gurú de la salud',
  ];

  static String titleForLevel(int level) {
    if (level <= 1) return _titles.first;
    final idx = level - 1;
    if (idx < _titles.length) return _titles[idx];
    return 'Leyenda';
  }

  static LevelInfo infoForXp(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;
    final level = levelForXp(xp);
    final base = cumulativeXpForLevel(level);
    final next = cumulativeXpForLevel(level + 1);
    return LevelInfo(
      level: level,
      title: titleForLevel(level),
      xpIntoLevel: xp - base,
      xpForNext: next - base,
      totalXp: xp,
    );
  }
}
