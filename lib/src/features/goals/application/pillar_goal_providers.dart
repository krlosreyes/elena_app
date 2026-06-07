// BUGFIX objetivos (2026-06-07) — providers de meta efectiva por pilar.
// Los pilares consumen estos en vez de leer el UserModel directo, para que
// editar un objetivo en "Mis objetivos" se refleje en el pilar.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_resolver.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Meta efectiva de ejercicio (min/día): goal activo > UserModel (default 20).
final effectiveExerciseGoalProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return 20;
  return PillarGoalResolver.exerciseMinutes(ref.watch(goalsProvider), user);
});

/// Meta efectiva de sueño (horas/noche): goal activo > default 8h.
final effectiveSleepGoalProvider = Provider<double>((ref) {
  return PillarGoalResolver.sleepHours(ref.watch(goalsProvider));
});
