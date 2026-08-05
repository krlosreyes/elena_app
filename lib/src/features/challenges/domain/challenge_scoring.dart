// SPEC-263: cálculo puro de la competencia. Sin I/O ni reloj propio.
//
// La métrica es CONSTANCIA: cuántos días del período califican para la racha
// (regla real `StreakEntry.qualifiesForStreak`). Sale del historial REAL y
// persistido del usuario (`streak_history`), así que no se puede inflar
// registrando agua 50 veces — un día cuenta si cumple ≥3 pilares con ancla.

import 'dart:math';

import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

abstract final class ChallengeScoring {
  /// Formatea una fecha como 'yyyy-MM-dd' (comparable con StreakEntry.date).
  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Puntos de constancia: días que califican en [startKey, endKey] inclusive.
  ///
  /// SPEC-264: superado por [pillarPoints] como métrica del reto. Se conserva
  /// como utilidad (y para su test de regresión).
  static int consistencyPoints(
    List<StreakEntry> history, {
    required String startKey,
    required String endKey,
  }) {
    var points = 0;
    for (final e in history) {
      if (e.date.compareTo(startKey) >= 0 &&
          e.date.compareTo(endKey) <= 0 &&
          e.qualifiesForStreak) {
        points++;
      }
    }
    return points;
  }

  /// SPEC-264 (métrica vigente del reto): PUNTOS POR PILAR. Cada anillo cerrado
  /// suma 1 (máx 5/día); se acumulan en [startKey, endKey] inclusive. Premia
  /// también los días parciales — cada pilar cuenta. Sigue siendo constancia
  /// (no peso): sale del registro real de pilares, no se puede inflar.
  static int pillarPoints(
    List<StreakEntry> history, {
    required String startKey,
    required String endKey,
  }) {
    var points = 0;
    for (final e in history) {
      if (e.date.compareTo(startKey) >= 0 && e.date.compareTo(endKey) <= 0) {
        points += e.pillarsCompleted;
      }
    }
    return points;
  }

  /// Ordena el tablero: más puntos primero; empates por nombre (A→Z).
  static List<ChallengeScore> leaderboard(List<ChallengeScore> scores) {
    final sorted = [...scores]..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        if (byPoints != 0) return byPoints;
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });
    return sorted;
  }

  /// Ganador (o null si no hay participantes). Empate → gana el primero por
  /// orden del tablero (nombre A→Z) — informativo, no vinculante.
  static ChallengeScore? winner(List<ChallengeScore> scores) {
    if (scores.isEmpty) return null;
    return leaderboard(scores).first;
  }

  /// Alfabeto sin caracteres confusos (sin 0/O/1/I) para el código.
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Genera un código de invitación de [length] caracteres.
  static String generateInviteCode({int length = 6, Random? random}) {
    final r = random ?? Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      buf.write(_alphabet[r.nextInt(_alphabet.length)]);
    }
    return buf.toString();
  }
}
