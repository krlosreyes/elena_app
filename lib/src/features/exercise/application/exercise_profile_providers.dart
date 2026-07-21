// Propuesta módulo Ejercicio (2026-07-21): providers del perfil de
// hábitos de ejercicio. Patrón simple (StreamProvider.autoDispose) —
// no requiere un StateNotifier propio porque el perfil se escribe una
// vez en onboarding y ocasionalmente se edita desde Perfil; no necesita
// estado optimista local como ExerciseNotifier (que sí escribe con
// alta frecuencia).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/exercise/data/exercise_profile_repository_impl.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_profile.dart';

/// Stream en vivo del perfil de ejercicio del usuario activo. `null`
/// mientras no hay usuario autenticado o el usuario aún no completó
/// el paso de hábitos de ejercicio (perfil `ExerciseProfile.initial()`
/// nunca se persiste explícitamente — la ausencia de doc es la señal).
final exerciseProfileStreamProvider =
    StreamProvider.autoDispose<ExerciseProfile?>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null || account.uid.isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(exerciseProfileRepositoryProvider).watch(account.uid);
});
