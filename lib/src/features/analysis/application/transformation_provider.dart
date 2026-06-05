// SPEC-148 §RF-148-04 (2026-06-05): provider derivado del snapshot
// de transformación 30 días.
//
// Combina los 3 streams canónicos (biometric_history, imr_history,
// streak history) y delega el cómputo al `TransformationComputer`
// (función pura).
//
// Devuelve `null` mientras los streams están loading. La UI usa ese
// estado para mostrar un skeleton. Si `snapshot.isEmpty == true`
// (ningún indicador tiene ambos puntos), la card pinta el placeholder
// cálido del SPEC §2.4 en vez del layout completo.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/transformation_computer.dart';
import 'package:elena_app/src/features/analysis/domain/transformation_snapshot.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';

/// Stream de los últimos N check-ins biométricos (default 90 docs —
/// cubre 3 meses con margen para encontrar el doc de hace 30d).
final _biometricHistoryProvider =
    StreamProvider.autoDispose<List<BiometricCheckIn>>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(const []);
  return ref.watch(biometricRepositoryProvider).watchHistory(
        account.uid,
        limit: 90,
      );
});

/// Stream de los últimos 12 snapshots semanales del IMR longitudinal
/// (SPEC-141 §RF-141-12). 12 semanas ≈ 3 meses, sobra para localizar
/// el snapshot de hace 30 días.
final _imrHistoryProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(const []);
  return ref
      .watch(userProfileRepositoryProvider)
      .watchImrHistory(account.uid, limit: 12);
});

/// SPEC-138 §16.4: stream de los logs nutricionales de los últimos 35
/// días. Cubre la ventana past (28-35d) + current (0-7d) del delta UPF.
final _nutritionHistoryProvider =
    StreamProvider.autoDispose<List<NutritionLog>>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(const []);
  final since = DateTime.now().subtract(const Duration(days: 35));
  return ref
      .watch(nutritionRepositoryProvider)
      .watchSinceLogs(account.uid, since);
});

/// SPEC-148 §RF-148-04: snapshot live de la transformación 30d.
///
/// - Retorna `null` mientras alguno de los 3 streams está loading
///   (estado inicial post-login).
/// - Retorna `TransformationSnapshot.empty()` si los streams resolvieron
///   pero el usuario no tiene data suficiente — la UI distingue este
///   caso vía `snapshot.isEmpty` y pinta el placeholder cálido.
/// - Retorna el snapshot real cuando hay al menos un indicador con
///   ambos puntos.
final transformationSnapshotProvider =
    Provider.autoDispose<TransformationSnapshot?>((ref) {
  final bioAsync = ref.watch(_biometricHistoryProvider);
  final imrAsync = ref.watch(_imrHistoryProvider);
  final nutritionAsync = ref.watch(_nutritionHistoryProvider);

  // Si alguno está loading o con error, retornamos null. La UI muestra
  // skeleton/placeholder según corresponda.
  if (bioAsync.isLoading || imrAsync.isLoading) return null;
  final bioHistory = bioAsync.valueOrNull;
  final imrHistory = imrAsync.valueOrNull;
  if (bioHistory == null || imrHistory == null) return null;

  // SPEC-138: nutritionHistory es secundario — si está loading o
  // null, igual computamos el snapshot (el delta UPF quedará empty).
  // No bloquear la card por una métrica que arrancó después.
  final nutritionHistory = nutritionAsync.valueOrNull ?? const <NutritionLog>[];

  // El streakProvider es síncrono — sus entradas ya viven en memoria.
  final streakState = ref.watch(streakProvider);

  return TransformationComputer.compute(
    biometricHistory: bioHistory,
    imrHistory: imrHistory,
    streakHistory: streakState.history,
    nutritionHistory: nutritionHistory,
    now: DateTime.now(),
  );
});
