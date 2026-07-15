// Sistema de insignias (2026-07-15) — orquesta la evaluación en vivo:
// escucha el historial ancho de racha (SIN el recorte de 90 días que usa
// el resto del Dashboard, ver comentario en badge_engine.dart) + el
// historial biométrico ya cargado por `progressProvider`, corre
// `BadgeEngine.evaluate`, persiste offline-first las insignias nuevas, y
// dispara la celebración correspondiente.
//
// Mismo patrón offline-first documentado y aplicado a los 5 pilares y a
// racha: nunca `await` un write de Firestore en el camino principal —
// estado local optimista primero, `unawaited(...).catchError(...)`
// después. El listener de Firestore (`watchEarned`) es la fuente de
// verdad a mediano plazo; el estado local optimista es la fuente de
// verdad inmediata para que la UI no tenga que esperar un roundtrip.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/providers/celebration_providers.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/badges/data/badge_repository_impl.dart';
import 'package:elena_app/src/features/badges/domain/badge_engine.dart';
import 'package:elena_app/src/features/badges/domain/earned_badge.dart';
import 'package:elena_app/src/features/progress/application/progress_notifier.dart';
import 'package:elena_app/src/features/streak/data/mappers/streak_entry_mapper.dart';
import 'package:elena_app/src/features/streak/data/sources/firestore_streak_v1_source.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class BadgeState {
  /// Todas las insignias ya ganadas por el usuario.
  final List<EarnedBadge> earned;

  final bool isLoading;

  const BadgeState({this.earned = const [], this.isLoading = true});

  BadgeState copyWith({List<EarnedBadge>? earned, bool? isLoading}) =>
      BadgeState(
        earned: earned ?? this.earned,
        isLoading: isLoading ?? this.isLoading,
      );

  Set<String> get earnedIds => earned.map((b) => b.badgeId).toSet();
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class BadgeNotifier extends StateNotifier<BadgeState> {
  final Ref _ref;
  String? _userId;
  StreamSubscription? _badgesSub;
  StreamSubscription? _historySub;

  bool _badgesLoaded = false;
  bool _historyLoaded = false;

  /// Evita celebrar insignias "históricas" que un usuario ya existente
  /// desbloquea de golpe apenas se activa esta feature — mismo patrón
  /// `_celebrationBaselineSet` que usa StreakNotifier (SPEC-255). Sin
  /// esto, un usuario con meses de historial vería una lluvia de
  /// banners de celebración simultáneos la primera vez que abre la app
  /// tras el lanzamiento.
  bool _baselineSet = false;

  List<StreakEntry> _fullHistory = [];

  /// Cutoff muy antiguo — en la práctica trae "todo" el historial. Se usa
  /// una fecha en vez de omitir el filtro porque `streamSince` lo exige
  /// como parámetro; no existe ningún usuario con datos anteriores a esto.
  static const String _epochCutoff = '2000-01-01';

  BadgeNotifier(this._ref) : super(const BadgeState()) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (_, next) {
        next.whenData((user) {
          if (user == null) {
            _badgesSub?.cancel();
            _historySub?.cancel();
            _badgesSub = null;
            _historySub = null;
            _userId = null;
            _badgesLoaded = false;
            _historyLoaded = false;
            _baselineSet = false;
            if (mounted) state = const BadgeState(isLoading: false);
            return;
          }
          if (_userId != user.id) {
            _userId = user.id;
            _subscribe(user.id);
          }
        });
      },
      fireImmediately: true,
    );

    // El historial biométrico ya lo carga `progressProvider` (hasta 2000
    // docs — ver biometric_repository.dart) para otras pantallas. Nos
    // enganchamos a ese mismo stream en vez de abrir una segunda
    // suscripción redundante a `biometric_history`.
    _ref.listen<ProgressState>(
      progressProvider,
      (_, __) => _maybeEvaluate(),
    );
  }

  void _subscribe(String userId) {
    _badgesSub?.cancel();
    _badgesSub = _ref.read(badgeRepositoryProvider).watchEarned(userId).listen(
      (earned) {
        _badgesLoaded = true;
        if (mounted) {
          state = state.copyWith(earned: earned, isLoading: false);
        }
        _maybeEvaluate();
      },
      onError: (Object e) {
        AppLogger.error('[BadgeNotifier] Error en stream de insignias', e);
      },
    );

    _historySub?.cancel();
    final source = FirestoreStreakV1Source();
    const mapper = StreakEntryMapper();
    _historySub = source
        .streamSince(userId: userId, cutoffDateKey: _epochCutoff)
        .listen(
      (maps) {
        _fullHistory = maps
            .map((m) {
              try {
                return mapper.fromMap(m);
              } catch (_) {
                return null;
              }
            })
            .whereType<StreakEntry>()
            .toList();
        _historyLoaded = true;
        _maybeEvaluate();
      },
      onError: (Object e) {
        AppLogger.error('[BadgeNotifier] Error en historial ancho de racha', e);
      },
    );
  }

  void _maybeEvaluate() {
    final uid = _userId;
    if (uid == null || !_badgesLoaded || !_historyLoaded) return;

    final biometricHistory = _ref.read(progressProvider).biometricHistory;
    final newlyUnlocked = BadgeEngine.evaluate(
      fullStreakHistory: _fullHistory,
      biometricHistory: biometricHistory,
      alreadyUnlockedIds: state.earnedIds,
    );

    if (newlyUnlocked.isEmpty) {
      _baselineSet = true;
      return;
    }

    // Persistencia offline-first: nunca await, nunca bloquea. El ID
    // determinístico hace que reintentos o carreras entre evaluaciones
    // sean inofensivos (sobreescriben el mismo documento).
    final repo = _ref.read(badgeRepositoryProvider);
    for (final badge in newlyUnlocked) {
      unawaited(repo.create(uid, badge).then((_) {
        AppLogger.debug('[BadgeNotifier] Insignia guardada: ${badge.badgeId}');
      }).catchError((Object e) {
        if (_userId == null) {
          AppLogger.debug('[BadgeNotifier] Create abortado por logout: $e');
        } else {
          AppLogger.error(
              '[BadgeNotifier] Error al guardar insignia ${badge.badgeId}', e);
        }
      }));
    }

    // Estado local optimista — la UI (galería, celebración) refleja la
    // insignia nueva de inmediato, sin esperar el roundtrip de Firestore.
    if (mounted) {
      state = state.copyWith(earned: [...state.earned, ...newlyUnlocked]);
    }

    // Baseline guard: en la primera evaluación de la sesión (un usuario
    // existente puede calificar de golpe para insignias "históricas"
    // apenas se lanza esta feature) no celebramos nada — solo persistimos
    // en silencio. A partir de la segunda evaluación, sí.
    if (_baselineSet) {
      // Un solo banner a la vez (CelebrationOverlay es one-shot); si se
      // desbloquea más de una insignia en el mismo instante, las demás
      // igual quedan reflejadas en el estado/galería, solo no compiten
      // por el mismo banner.
      final toCelebrate = newlyUnlocked.first;
      _ref.read(celebrationEventProvider.notifier).state = CelebrationEvent(
        type: CelebrationType.badgeUnlocked,
        pillarsCompleted: 0,
        currentStreak: 0,
        timestamp: DateTime.now(),
        badge: toCelebrate,
      );
      unawaited(AnalyticsService.logEvent(
        AnalyticsEvents.badgeUnlocked,
        params: {
          AnalyticsParams.badgeId: toCelebrate.badgeId,
          AnalyticsParams.badgeCategory: toCelebrate.category,
        },
      ));
    }
    _baselineSet = true;
  }

  @override
  void dispose() {
    _badgesSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final badgeProvider = StateNotifierProvider<BadgeNotifier, BadgeState>((ref) {
  return BadgeNotifier(ref);
});
