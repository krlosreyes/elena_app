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

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
import 'package:elena_app/src/features/badges/data/badge_repository_impl.dart';
import 'package:elena_app/src/features/badges/domain/earned_badge.dart';
import 'package:elena_app/src/features/challenges/application/challenge_providers.dart';
import 'package:elena_app/src/features/challenges/data/challenge_repository.dart';
import 'package:elena_app/src/features/challenges/data/nudge_repository.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_rings.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_scoring.dart';
import 'package:elena_app/src/features/challenges/domain/nudge.dart';
import 'package:elena_app/src/features/challenges/domain/reto_badges.dart';
import 'package:elena_app/src/features/gamification/application/gamification_notifier.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
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
  /// SPEC-264: puntos por pilar + anillos de hoy + flag "cumplió hoy".
  ChallengeScore _myScoreFor(Challenge challenge, UserModel user) {
    final history = _ref.read(challengeStreakHistoryProvider);
    final points = ChallengeScoring.pillarPoints(
      history,
      startKey: challenge.startDateKey,
      endKey: challenge.endDateKey,
    );
    final todayKey = ChallengeScoring.dateKey(DateTime.now());
    StreakEntry? todayEntry;
    for (final e in history) {
      if (e.date == todayKey) {
        todayEntry = e;
        break;
      }
    }
    return ChallengeScore(
      uid: user.id,
      displayName: user.name,
      points: points,
      todayRings: todayEntry == null
          ? ChallengeRings.empty
          : ChallengeRings.fromEntry(todayEntry),
      qualifiedToday: todayEntry?.qualifiesForStreak ?? false,
    );
  }

  /// Crea un reto nuevo. Devuelve el código de invitación generado.
  /// [asRematch] distingue una revancha (encadena el hábito) de un reto nuevo,
  /// solo para el récord/insignias.
  Future<Challenge> createChallenge({
    required String name,
    required String startDateKey,
    required String endDateKey,
    bool asRematch = false,
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
    _recordJoinAndAward(asRematch: asRematch);
    return challenge;
  }

  /// SPEC-264: revancha — clona un reto terminado con los mismos rivales
  /// (nombre derivado, 7 días nuevos). Devuelve el reto nuevo (comparte código
  /// para que el grupo se una otra vez).
  Future<Challenge> rematch(Challenge old) {
    final now = DateTime.now();
    return createChallenge(
      name: 'Revancha: ${old.name}',
      startDateKey: ChallengeScoring.dateKey(now),
      endDateKey: ChallengeScoring.dateKey(now.add(const Duration(days: 6))),
      asRematch: true,
    );
  }

  /// SPEC-264: registra el resultado de un reto que terminó ([didWin] si el
  /// usuario quedó primero) y otorga las insignias que correspondan.
  /// Idempotente por [code].
  void recordOutcome({required String code, required bool didWin}) {
    try {
      _ref.read(gamificationProvider.notifier).recordChallengeOutcome(
            code: code,
            didWin: didWin,
          );
      _awardRetoBadges();
    } catch (e) {
      AppLogger.error('ChallengeController.recordOutcome falló', e);
    }
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
    _recordJoinAndAward(asRematch: false);
    return joined;
  }

  /// Actualiza el récord de retos y otorga insignias. Best-effort: NUNCA
  /// rompe el flujo principal (crear/unirse) — la gamificación es secundaria.
  void _recordJoinAndAward({required bool asRematch}) {
    try {
      final g = _ref.read(gamificationProvider.notifier);
      if (asRematch) {
        g.recordRematch();
      } else {
        g.recordChallengeJoined();
      }
      _awardRetoBadges();
    } catch (e) {
      AppLogger.error('ChallengeController._recordJoinAndAward falló', e);
    }
  }

  /// Otorga (una sola vez) las insignias de reto que correspondan al récord
  /// actual, escribiéndolas por el sistema de insignias existente. Best-effort.
  void _awardRetoBadges() {
    try {
      final uid = _ref.read(currentUserStreamProvider).valueOrNull?.id;
      if (uid == null || uid.isEmpty) return;
      final g = _ref.read(gamificationProvider);
      final want = RetoBadges.earnedIds(
        joined: g.retosJoined,
        finished: g.retosFinished,
        won: g.retosWon,
        rematches: g.retosRematches,
      );
      final have = _ref.read(badgeProvider).earnedIds;
      final repo = _ref.read(badgeRepositoryProvider);
      final now = DateTime.now();
      for (final id in want) {
        if (have.contains(id)) continue;
        final badge = EarnedBadge(
          badgeId: id,
          category: RetoBadges.category,
          level: RetoBadges.levelFor(id),
          unlockedAt: now,
        );
        unawaited(repo.create(uid, badge).catchError((Object e) {
          AppLogger.error('ChallengeController award badge $id', e);
        }));
      }
    } catch (e) {
      AppLogger.error('ChallengeController._awardRetoBadges falló', e);
    }
  }

  /// Recalcula y publica MI puntaje en un reto ya unido (al abrirlo).
  Future<void> refreshMyScore(Challenge challenge) async {
    final user = _ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null || user.id.isEmpty) return;
    await _publishScoreQuietly(challenge, user);
  }

  /// SPEC-264: envía una interacción (zumbido/porra/fuego) a un rival. Gasta
  /// perlas de forma optimista; lanza [ChallengeException] si no alcanzan.
  Future<void> sendNudge({
    required String code,
    required String toUid,
    required NudgeKind kind,
  }) async {
    final user = _requireUser();
    if (toUid == user.id) {
      throw const ChallengeException(
        'No puedes enviarte una interacción a ti mismo.',
      );
    }
    final paid =
        _ref.read(gamificationProvider.notifier).spendPerlas(kind.cost);
    if (!paid) {
      throw ChallengeException(
        'Te faltan perlas para enviar "${kind.label}".',
      );
    }
    final nudge = Nudge(
      id: '',
      fromUid: user.id,
      fromName: user.name,
      toUid: toUid,
      typeId: kind.id,
      createdAt: DateTime.now(),
    );
    try {
      await _ref.read(nudgeRepositoryProvider).send(code, nudge);
    } catch (e) {
      AppLogger.error('ChallengeController.sendNudge falló', e);
      throw const ChallengeException(
        'No pudimos enviar la interacción. Inténtalo de nuevo.',
      );
    }
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
