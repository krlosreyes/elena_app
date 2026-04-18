// SPEC-15: Road Map de Avance Personal
// ProgressNotifier combina el historial de IMR (StreakEntry × 30 días)
// con el historial biométrico (BiometricCheckIn) en un único estado.
// Sigue el mismo patrón de inicialización de HydrationNotifier:
// escucha currentUserStreamProvider con fireImmediately: true.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class ProgressState {
  /// Historial de racha: hasta 30 días con imrScore por día.
  /// Ordenado cronológicamente (más antiguo primero) para gráficas.
  final List<StreakEntry> imrHistory;

  /// Historial de check-ins biométricos.
  /// Ordenado cronológicamente (más antiguo primero).
  final List<BiometricCheckIn> biometricHistory;

  final bool isLoading;

  const ProgressState({
    this.imrHistory        = const [],
    this.biometricHistory  = const [],
    this.isLoading         = true,
  });

  ProgressState copyWith({
    List<StreakEntry>?        imrHistory,
    List<BiometricCheckIn>?   biometricHistory,
    bool?                     isLoading,
  }) {
    return ProgressState(
      imrHistory:       imrHistory       ?? this.imrHistory,
      biometricHistory: biometricHistory ?? this.biometricHistory,
      isLoading:        isLoading        ?? this.isLoading,
    );
  }

  // ─── Helpers de presentación ──────────────────────────────────────────────

  /// Puntos de la gráfica IMR (0–100), del más antiguo al más reciente.
  List<double> get imrChartPoints =>
      imrHistory.map((e) => e.imrScore.toDouble()).toList();

  /// IMR del primer día registrado (línea de base).
  int? get baselineImr => imrHistory.isNotEmpty ? imrHistory.first.imrScore : null;

  /// IMR más reciente.
  int? get latestImr => imrHistory.isNotEmpty ? imrHistory.last.imrScore : null;

  /// Diferencia de IMR respecto al inicio (+/-).
  int? get imrDelta => (baselineImr != null && latestImr != null)
      ? latestImr! - baselineImr!
      : null;

  /// Peso del check-in más reciente.
  double? get latestWeight =>
      biometricHistory.isNotEmpty ? biometricHistory.last.weight : null;

  /// %Grasa del check-in más reciente con ese dato.
  double? get latestBodyFat {
    try {
      return biometricHistory
          .lastWhere((c) => c.bodyFatPercentage != null)
          .bodyFatPercentage;
    } catch (_) {
      return null;
    }
  }

  /// Puntos de la gráfica de peso (cronológico).
  List<double> get weightChartPoints => biometricHistory
      .map((c) => c.weight)
      .toList();

  /// Puntos de la gráfica de %grasa corporal (solo check-ins con ese dato).
  List<double> get bodyFatChartPoints => biometricHistory
      .where((c) => c.bodyFatPercentage != null)
      .map((c) => c.bodyFatPercentage!)
      .toList();

  bool get hasEnoughImrData  => imrHistory.length  >= 3;
  bool get hasEnoughBfData   => bodyFatChartPoints.length >= 2;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ProgressNotifier extends StateNotifier<ProgressState> {
  final Ref _ref;
  StreamSubscription<List<BiometricCheckIn>>? _bioSub;
  String? _currentUserId;

  ProgressNotifier(this._ref) : super(const ProgressState()) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (_, next) {
        next.whenData((user) {
          if (user != null && user.id.isNotEmpty) {
            if (_currentUserId != user.id) {
              _currentUserId = user.id;
              _subscribeToBiometric(user.id);
            }
          } else {
            _bioSub?.cancel();
            _bioSub = null;
            _currentUserId = null;
            if (mounted) state = const ProgressState(isLoading: false);
          }
        });
      },
      fireImmediately: true,
    );

    // Escucha el historial de racha (ya existe en streakProvider)
    _ref.listen<StreakState>(streakProvider, (_, next) {
      // history viene descendente de Firestore — invertimos para gráficas
      final ordered = [...next.history.reversed];
      if (mounted) {
        state = state.copyWith(imrHistory: ordered, isLoading: false);
      }
    }, fireImmediately: true);
  }

  void _subscribeToBiometric(String userId) {
    _bioSub?.cancel();
    _bioSub = _ref
        .read(biometricRepositoryProvider)
        .watchHistory(userId)
        .listen((list) {
      // Firestore devuelve descendente — invertimos
      if (mounted) {
        state = state.copyWith(biometricHistory: list.reversed.toList());
      }
    });
  }

  // ─── API pública ────────────────────────────────────────────────────────────

  /// Guarda un nuevo check-in biométrico.
  Future<void> saveCheckIn(BiometricCheckIn checkIn) async {
    await _ref.read(biometricRepositoryProvider).saveCheckIn(checkIn);
    // El stream actualizará el estado automáticamente
  }

  @override
  void dispose() {
    _bioSub?.cancel();
    super.dispose();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  return ProgressNotifier(ref);
});
