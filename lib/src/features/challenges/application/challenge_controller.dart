// SPEC-263: acciones de retos (crear, unirse, publicar puntaje, borrar).
//
// La métrica es CONSTANCIA y sale del historial REAL del usuario
// (`streakProvider.history`, ver challenge_scoring.dart). Cada quien calcula
// y publica SU propio puntaje: las reglas de Firestore solo dejan a cada
// usuario leer su propio `streak_history` y escribir su propio doc de score,
// así que el tablero se construye con puntajes ya publicados por cada miembro.
//
// A diferencia del registro de pilares (hot-path offline-first que nunca
// hace `await`), crear/unirse son acciones deliberadas donde el usuario
// necesita saber el resultado (¿cuál es el código?, ¿ya entré?). Por eso
// estas sí esperan el write y propagan el error a la UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/challenges/application/challenge_providers.dart';
import 'package:elena_app/src/features/challenges/data/challenge_repository.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_scoring.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Errores de dominio de retos (mensajes ya listos para la UI, sin voseo).
class ChallengeException implements Exception {
  final String message;
  const ChallengeException(this.message);
  @override
  String toString() => message;
}

class ChallengeController {
  ChallengeController(this._ref);

  final Ref _ref;

  ChallengeRepository get _repo => _ref.read(challengeRepositoryProvider);

  UserModel _requireUser() {
    final user = _ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null || user.id.isEmpty) {
      throw const ChallengeException(
        'Necesitas iniciar sesión para participar en retos.',
      );
    }
    return user;
  }

  /// Puntaje del usuario en la ventana del reto, a partir de su racha real.
  ChallengeScore _myScoreFor(Challenge challenge, UserModel user) {
    final history = _ref.read(challengeStreakHistoryProvider);
    final points = ChallengeScoring.consistencyPoints(
      history,
      startKey: challenge.startDateKey,
      endKey: challenge.endDateKey,
    );
    return ChallengeScore(
      uid: user.id,
      displayName: user.name,
      points: points,
    );
  }

  /// Crea un reto nuevo. Devuelve el código de invitación generado.
  Future<Challenge> createChallenge({
    required String name,
    required String startDateKey,
    required String endDateKey,
  }) async {
    final user = _requireUser();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ChallengeException('Ponle un nombre al reto.');
    }
    if (endDateKey.compareTo(startDateKey) < 0) {
      throw const ChallengeException(
        'La fecha de fin no puede ser anterior a la de inicio.',
      );
    }

    final challenge = Challenge(
      code: ChallengeScoring.generateInviteCode(),
      name: trimmed,
      ownerId: user.id,
      ownerName: user.name,
      startDateKey: startDateKey,
      endDateKey: endDateKey,
      memberIds: [user.id],
    );

    try {
      await _repo.create(challenge);
    } catch (e) {
      AppLogger.error('ChallengeController.create falló', e);
      throw const ChallengeException(
        'No pudimos crear el reto. Revisa tu conexión e inténtalo de nuevo.',
      );
    }

    // Publica el puntaje inicial (best-effort: el reto ya existe aunque esto
    // falle; se reintenta cada vez que el usuario abre el reto).
    await _publishScoreQuietly(challenge, user);
    return challenge;
  }

  /// Unirse a un reto con su código de invitación.
  Future<Challenge> joinByCode(String rawCode) async {
    final user = _requireUser();
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw const ChallengeException('Escribe el código del reto.');
    }

    final Challenge? challenge;
    try {
      challenge = await _repo.watchChallenge(code).first;
    } catch (e) {
      AppLogger.error('ChallengeController.join read falló', e);
      throw const ChallengeException(
        'No pudimos buscar el reto. Revisa tu conexión.',
      );
    }
    if (challenge == null) {
      throw const ChallengeException(
        'No encontramos un reto con ese código. Revísalo con quien te invitó.',
      );
    }
    if (challenge.isMember(user.id)) {
      // Ya está dentro: no es error, solo republicamos y devolvemos.
      await _publishScoreQuietly(challenge, user);
      return challenge;
    }

    final joined = challenge.copyWith(
      memberIds: [...challenge.memberIds, user.id],
    );
    try {
      await _repo.join(code, joined.memberIds);
    } catch (e) {
      AppLogger.error('ChallengeController.join write falló', e);
      throw const ChallengeException(
        'No pudimos unirte al reto. Inténtalo de nuevo.',
      );
    }
    await _publishScoreQuietly(joined, user);
    return joined;
  }

  /// Recalcula y publica MI puntaje en un reto ya unido (al abrirlo).
  Future<void> refreshMyScore(Challenge challenge) async {
    final user = _ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null || user.id.isEmpty) return;
    await _publishScoreQuietly(challenge, user);
  }

  /// Borra el reto (solo el dueño; las reglas rechazan al resto).
  Future<void> deleteChallenge(String code) async {
    _requireUser();
    try {
      await _repo.delete(code);
    } catch (e) {
      AppLogger.error('ChallengeController.delete falló', e);
      throw const ChallengeException('No pudimos borrar el reto.');
    }
  }

  Future<void> _publishScoreQuietly(Challenge challenge, UserModel user) async {
    try {
      await _repo.publishScore(challenge.code, _myScoreFor(challenge, user));
    } catch (e) {
      // Best-effort: el puntaje se republicará al abrir el reto.
      AppLogger.error('ChallengeController.publishScore falló', e);
    }
  }
}

final challengeControllerProvider = Provider<ChallengeController>((ref) {
  return ChallengeController(ref);
});
