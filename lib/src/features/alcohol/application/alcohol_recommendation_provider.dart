// SPEC-261.4: provider que arma el plan recomendado desde la sesión + perfil.
//
// Combina los insumos de la ocasión (tipo de trago, hora de inicio, agenda de
// mañana) con los datos del usuario (peso, sexo, hora habitual de dormir) y
// devuelve un DrinkRecommendation. Null mientras falten insumos.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/alcohol/application/consumption_notifier.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_math.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_recommendation.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_type.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final drinkRecommendationProvider = Provider<DrinkRecommendation?>((ref) {
  final session = ref.watch(consumptionProvider);
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  final type = DrinkTypes.byId(session.drinkTypeId);
  final start = session.startTime;

  if (user == null || type == null || start == null) return null;

  final sex = user.gender == 'M' ? WidmarkSex.male : WidmarkSex.female;
  // Hora habitual de dormir del usuario, anclada a la noche de la fiesta.
  final habitualBedtime = DateTime(
    start.year,
    start.month,
    start.day,
    user.profile.sleepTime.hour,
    user.profile.sleepTime.minute,
  );

  return DrinkRecommendation.compute(
    type: type,
    weightKg: user.weight,
    sex: sex,
    startTime: start,
    worksTomorrow: session.worksTomorrow,
    wakeTime: session.wakeTime,
    habitualBedtime: habitualBedtime,
  );
});
