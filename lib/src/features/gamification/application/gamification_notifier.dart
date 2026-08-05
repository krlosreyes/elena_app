// SPEC-262: notifier de la economía de gamificación.
//
// Offline-first (patrón de ConsumptionNotifier / HydrationNotifier): las
// acciones actualizan el estado local de inmediato y persisten en segundo
// plano sin bloquear la UI (nunca `await` un write). Se suscribe al doc del
// usuario cuando hay sesión; sin usuario (tests sin Firebase) NO toca
// Firestore.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/gamification/data/gamification_repository.dart';
import 'package:elena_app/src/features/gamification/domain/gamification_state.dart';
import 'package:elena_app/src/features/gamification/domain/shop_item.dart';
import 'package:elena_app/src/features/gamification/domain/star_action.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier(this._ref) : super(const GamificationState()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<GamificationState?>? _sub;
  String? _userId;

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        final user = next.valueOrNull;
        if (user == null) {
          _sub?.cancel();
          _sub = null;
          _userId = null;
          if (mounted) state = const GamificationState();
          return;
        }
        if (user.id == _userId) return;
        _userId = user.id;
        _subscribe(user.id);
      },
      fireImmediately: true,
    );
  }

  void _subscribe(String userId) {
    _sub?.cancel();
    // Resiliente: si Firestore no está disponible (p. ej. tests sin Firebase
    // con un usuario activo), NO propagamos el error — la gamificación es
    // best-effort y jamás debe tumbar a quien nos lea desde otro feature.
    try {
      _sub = _ref.read(gamificationRepositoryProvider).watch(userId).listen(
        (remote) {
          if (remote != null && mounted) state = remote;
        },
        onError: (Object e) => AppLogger.error('gamification.watch', e),
      );
    } catch (e) {
      AppLogger.error('GamificationNotifier._subscribe falló', e);
    }
  }

  void _persist() {
    final uid = _userId;
    if (uid == null) return;
    // Auto-protegido: si construir el repo/Firestore lanza (tests sin
    // Firebase), no propagamos — el estado local ya se actualizó.
    try {
      unawaited(
        _ref.read(gamificationRepositoryProvider).save(uid, state).catchError(
          (Object e) {
            AppLogger.error('GamificationNotifier.save falló', e);
          },
        ),
      );
    } catch (e) {
      AppLogger.error('GamificationNotifier._persist falló', e);
    }
  }

  // ── API pública ───────────────────────────────────────────────────────

  /// Premia una acción registrada (estrellas + XP).
  void reward(StarAction action) {
    if (!mounted) return;
    state = state.earn(action);
    _persist();
  }

  /// Un día que calificó para la racha: bonus + avance hacia el congelador.
  void onDayQualified() {
    if (!mounted) return;
    state = state.onDayQualified();
    _persist();
  }

  /// Acumula horas de ayuno de por vida (al cerrar un ayuno).
  void recordFastingHours(double hours) {
    if (!mounted || hours <= 0) return;
    state = state.addFastingHours(hours);
    _persist();
  }

  /// Compra un paquete de la Tienda. Devuelve true si se concretó (había
  /// estrellas suficientes).
  bool buyFrosty(ShopItem item) {
    if (!mounted) return false;
    final next = state.purchase(item);
    if (next == null) return false;
    state = next;
    _persist();
    return true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  return GamificationNotifier(ref);
});

/// Premia una acción desde CUALQUIER feature sin poder romper al llamador.
/// La gamificación es best-effort: si algo falla, se traga el error.
void awardStar(Ref ref, StarAction action) {
  try {
    ref.read(gamificationProvider.notifier).reward(action);
  } catch (_) {
    // best-effort: nunca romper el registro del pilar.
  }
}
