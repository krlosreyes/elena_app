// SPEC-263: providers de lectura de retos (streams reactivos para la UI).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/challenges/data/challenge_repository.dart';
import 'package:elena_app/src/features/challenges/data/nudge_repository.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_scoring.dart';
import 'package:elena_app/src/features/challenges/domain/nudge.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Historial de racha que alimenta el puntaje de constancia de los retos.
/// Seam de inyección: por defecto lee `streakProvider.history`; en tests se
/// sobrescribe con un historial fijo sin instanciar el StreakNotifier real
/// (que se suscribe a Firestore).
final challengeStreakHistoryProvider = Provider<List<StreakEntry>>((ref) {
  return ref.watch(streakProvider).history;
});

/// Retos donde el usuario actual es miembro. Vacío si no hay sesión.
final myChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null || user.id.isEmpty) {
    return Stream<List<Challenge>>.value(const []);
  }
  return ref.watch(challengeRepositoryProvider).watchMyChallenges(user.id);
});

/// Un reto por su código.
final challengeProvider =
    StreamProvider.family<Challenge?, String>((ref, code) {
  return ref.watch(challengeRepositoryProvider).watchChallenge(code);
});

/// Tablero (leaderboard) de un reto: puntajes ordenados por constancia.
final challengeLeaderboardProvider =
    StreamProvider.family<List<ChallengeScore>, String>((ref, code) {
  return ref
      .watch(challengeRepositoryProvider)
      .watchScores(code)
      .map(ChallengeScoring.leaderboard);
});

/// SPEC-264: interacciones (zumbidos) dirigidas al usuario actual en un reto.
/// Alimenta la recepción in-app (banner/animación).
final incomingNudgesProvider =
    StreamProvider.family<List<Nudge>, String>((ref, code) {
  final uid = ref.watch(currentUserStreamProvider).valueOrNull?.id;
  if (uid == null || uid.isEmpty) {
    return Stream<List<Nudge>>.value(const []);
  }
  return ref.watch(nudgeRepositoryProvider).watchForRecipient(code, uid);
});
