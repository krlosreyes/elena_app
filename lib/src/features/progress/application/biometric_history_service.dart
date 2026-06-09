// SPEC-143: BiometricHistoryService — punto único de escritura de
// biometría. Toda mutación de peso/cintura/cuello/%grasa/flag de
// estimación debe pasar por este servicio para garantizar que el doc
// raíz del usuario y el historial queden en sync atómicamente.
//
// CONSTITUTION §3.2: este servicio NO importa cloud_firestore. Solo
// conoce las interfaces de los repos. La transacción atómica vive en
// BiometricRepository.applyBiometricUpdate (que sí conoce Firestore).
//
// 5 métodos públicos, uno por gatillo de §RF-143-02:
//   - updateFromProfileEdit
//   - updateFromCheckInSheet
//   - updateFromHealthKitSync     (con filtro de ruido §RF-143-05)
//   - updateFromBodyFatRecompute  (con throttle §R-08)
//   - writeOnboardingBaseline
//
// Throttle de bodyfat_recompute (§R-08): mapa en memoria userId →
// último timestamp. Si se invoca dos veces en < 30s, la segunda
// llamada se descarta sin escribir. El throttle es por instancia del
// servicio; el provider Riverpod es Provider (singleton) para que el
// estado se preserve durante la sesión.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/progress/domain/biometric_delta.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class BiometricHistoryService {
  BiometricHistoryService({
    required BiometricRepository biometricRepo,
    DateTime Function() clock = _systemClock,
  })  : _biometricRepo = biometricRepo,
        _clock = clock;

  final BiometricRepository _biometricRepo;
  final DateTime Function() _clock;

  // SPEC-143 §R-08: throttle por userId del bodyfat_recompute.
  // Inyectado como instance field — el provider Riverpod debe ser
  // Provider (no autoDispose) para preservar el estado entre llamadas.
  final Map<String, DateTime> _lastBodyfatRecompute = {};
  static const Duration _bodyfatThrottleWindow = Duration(seconds: 30);

  static DateTime _systemClock() => DateTime.now();

  // ─── API pública ──────────────────────────────────────────────────────────

  /// Gatillo A — edit manual desde Profile.
  /// Siempre escribe si el delta tiene contenido (no filtra por ruido —
  /// el usuario explícitamente cambió los valores).
  Future<void> updateFromProfileEdit({
    required UserModel currentUser,
    required BiometricDelta delta,
  }) async {
    if (delta.isEmpty) return;
    await _writeSnapshot(
      currentUser: currentUser,
      delta: delta,
      source: BiometricSource.profileEdit,
    );
  }

  /// Gatillo del sheet de check-in manual. Preserva el comportamiento
  /// del callsite existente (notes + imrScore opcionales del sheet).
  ///
  /// [checkInData] viene del sheet con los campos biométricos +
  /// metadatos opcionales (notas, imrScore del momento).
  Future<void> updateFromCheckInSheet({
    required UserModel currentUser,
    required BiometricCheckIn checkInData,
  }) async {
    final delta = BiometricDelta(
      weight: checkInData.weight,
      waistCircumference: checkInData.waistCircumference,
      neckCircumference: checkInData.neckCircumference,
      bodyFatPercentage: checkInData.bodyFatPercentage,
    );
    if (delta.isEmpty) return;
    await _writeSnapshot(
      currentUser: currentUser,
      delta: delta,
      source: BiometricSource.checkinSheet,
      explicitNotes: checkInData.notes,
      explicitImrScore: checkInData.imrScore,
    );
  }

  /// Gatillo desde sync de HealthKit / Health Connect (SPEC-141.2
  /// conectará el listener real). Aplica filtro de ruido §RF-143-05:
  /// si el delta no es significativo, no escribe nada.
  Future<void> updateFromHealthKitSync({
    required UserModel currentUser,
    required BiometricDelta delta,
  }) async {
    if (delta.isEmpty) return;
    if (!delta.isSignificant(baseline: currentUser)) {
      // Ruido del sensor — no se persiste. SPEC-143 §RF-143-05.
      return;
    }
    await _writeSnapshot(
      currentUser: currentUser,
      delta: delta,
      source: BiometricSource.healthkitSync,
    );
  }

  /// Gatillo desde recálculo de %grasa por `BodyFatCalculator` (SPEC-92).
  /// Aplica throttle §R-08: si el último write con esta fuente fue
  /// hace menos de 30s, descarta sin escribir para evitar ruido cuando
  /// el usuario edita cintura/cuello en cascada.
  Future<void> updateFromBodyFatRecompute({
    required UserModel currentUser,
    required double newBodyFatPercentage,
  }) async {
    final now = _clock();
    final lastWrite = _lastBodyfatRecompute[currentUser.id];
    if (lastWrite != null &&
        now.difference(lastWrite) < _bodyfatThrottleWindow) {
      return;
    }
    final delta = BiometricDelta(bodyFatPercentage: newBodyFatPercentage);
    if (delta.isEmpty) return;
    await _writeSnapshot(
      currentUser: currentUser,
      delta: delta,
      source: BiometricSource.bodyFatRecompute,
    );
    _lastBodyfatRecompute[currentUser.id] = now;
  }

  /// Baseline al completar onboarding. Crea la primera entrada del
  /// historial del usuario con los valores actuales. NO actualiza
  /// `users/{uid}` — el OnboardingController ya persistió el perfil
  /// antes de invocar este método.
  Future<void> writeOnboardingBaseline({
    required UserModel currentUser,
  }) async {
    final now = _clock();
    final snapshot = BiometricCheckIn(
      date: _formatDateKey(now),
      userId: currentUser.id,
      weight: currentUser.weight,
      bodyFatPercentage: currentUser.bodyFatPercentage,
      waistCircumference: currentUser.waistCircumference,
      neckCircumference: currentUser.neckCircumference,
      createdAt: now,
      source: BiometricSource.onboardingBaseline,
      previousValues: null, // primera entrada — no hay versión anterior
      recordedAt: now,
    );
    await _biometricRepo.saveCheckIn(snapshot);
  }

  /// SPEC-143 §RF-143-07: backfill mínimo al primer login post-deploy.
  /// Crea UNA entrada con los valores actuales si `biometric_history`
  /// está vacía. Idempotente — si ya existe, no escribe.
  ///
  /// El llamador (user bootstrap provider) verifica primero si la
  /// historia está vacía consultando `repo.fetchLatest`.
  Future<void> writeSpec143BackfillEntry({
    required UserModel currentUser,
  }) async {
    final now = _clock();
    final snapshot = BiometricCheckIn(
      date: _formatDateKey(now),
      userId: currentUser.id,
      weight: currentUser.weight,
      bodyFatPercentage: currentUser.bodyFatPercentage,
      waistCircumference: currentUser.waistCircumference,
      neckCircumference: currentUser.neckCircumference,
      createdAt: now,
      source: BiometricSource.spec143Backfill,
      previousValues: null,
      recordedAt: now,
    );
    await _biometricRepo.saveCheckIn(snapshot);
  }

  /// Auditoría P3/C1 (2026-06-08): propaga el peso más reciente del
  /// historial al doc raíz `users/{uid}.weight` que lee la card de
  /// Perfil. Reemplaza el band-aid `saveProfile(user.copyWith(weight))`
  /// del HealthAutoSyncController, centralizando TODA escritura
  /// biométrica en este servicio.
  ///
  /// A diferencia de los otros gatillos, NO crea una entrada nueva de
  /// historial: el ImportService ya escribió el check-in del día. Aquí
  /// solo reescribimos esa misma entrada con merge (idempotente) dentro
  /// del mismo batch que actualiza el doc raíz, garantizando que Perfil
  /// y Análisis queden coherentes atómicamente.
  ///
  /// No-op si el peso ya coincide o la entrada no trae peso.
  Future<void> syncCanonicalWeightFromHistory({
    required UserModel currentUser,
    required BiometricCheckIn latestHistoryEntry,
  }) async {
    final w = latestHistoryEntry.weight;
    if (w == null) return;
    if (currentUser.weight == w) return;
    await _biometricRepo.applyBiometricUpdate(
      userId: currentUser.id,
      historySnapshot: latestHistoryEntry,
      userDocUpdates: {'weight': w},
    );
  }

  // ─── Lógica interna ──────────────────────────────────────────────────────

  /// Escribe atómicamente el doc raíz del usuario + snapshot histórico.
  /// Patrón compartido por todos los gatillos que tocan biometría
  /// existente (no aplica a onboarding/backfill, que solo escriben
  /// historia inicial).
  Future<void> _writeSnapshot({
    required UserModel currentUser,
    required BiometricDelta delta,
    required String source,
    String? explicitNotes,
    int? explicitImrScore,
  }) async {
    final now = _clock();
    final dateKey = _formatDateKey(now);

    final previousValues = delta.previousValuesAgainst(currentUser);
    final newUser = delta.applyTo(currentUser);

    final snapshot = BiometricCheckIn(
      date: dateKey,
      userId: currentUser.id,
      weight: newUser.weight,
      bodyFatPercentage: newUser.bodyFatPercentage,
      waistCircumference: newUser.waistCircumference,
      neckCircumference: newUser.neckCircumference,
      imrScore: explicitImrScore,
      notes: explicitNotes,
      createdAt: now,
      source: source,
      previousValues: previousValues.isEmpty ? null : previousValues,
      recordedAt: now,
    );

    final userUpdates = <String, dynamic>{};
    if (delta.weight != null) userUpdates['weight'] = delta.weight;
    if (delta.waistCircumference != null) {
      userUpdates['waistCircumference'] = delta.waistCircumference;
    }
    if (delta.neckCircumference != null) {
      userUpdates['neckCircumference'] = delta.neckCircumference;
    }
    if (delta.bodyFatPercentage != null) {
      userUpdates['bodyFatPercentage'] = delta.bodyFatPercentage;
    }
    if (delta.isMeasurementEstimated != null) {
      userUpdates['isMeasurementEstimated'] = delta.isMeasurementEstimated;
    }

    await _biometricRepo.applyBiometricUpdate(
      userId: currentUser.id,
      historySnapshot: snapshot,
      userDocUpdates: userUpdates,
    );
  }

  static String _formatDateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

// ─── Provider ───────────────────────────────────────────────────────────────

/// SPEC-143: Provider singleton (no autoDispose) para preservar el
/// throttle de bodyfat_recompute entre llamadas dentro de una sesión.
final biometricHistoryServiceProvider = Provider<BiometricHistoryService>(
  (ref) {
    final repo = ref.watch(biometricRepositoryProvider);
    return BiometricHistoryService(biometricRepo: repo);
  },
);
