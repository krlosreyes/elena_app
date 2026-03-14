import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../profile/application/user_controller.dart';
import '../../profile/domain/user_model.dart';
import '../../progress/domain/measurement_log.dart';
import '../../progress/data/progress_service.dart';
import '../logic/elena_brain.dart';
import '../../imx/application/imx_service.dart';

class OnboardingController extends StateNotifier<UserModel?> {
  final Ref _ref;

  OnboardingController(this._ref) : super(null);

  /// Inicializa el estado con el usuario actual o crea uno base
  Future<void> init(String uid, String email, String displayName) async {
    state = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      gender: Gender.female, // Default, será cambiado
      birthDate: DateTime(1990, 1, 1), // Default
      heightCm: 160,
      currentWeightKg: 60,
      waistCircumferenceCm: 70,
      neckCircumferenceCm: 35,
      pathologies: [],
      activityLevel: ActivityLevel.sedentary,
      snackingHabit: SnackingHabit.sometimes,
      dietaryPreference: DietaryPreference.omnivore,
      wakeUpTime: '07:00',
      bedTime: '23:00',
      usualFirstMealTime: '08:00',
      usualLastMealTime: '20:00',
    );
  }

  void updateUser(UserModel newUser) {
    state = newUser;
  }

  Future<void> submit() async {
    if (state == null) return;

    try {
      // 1. Generar Plan con ElenaBrain (Modelo Clínico)
      final clinicalPlan = ElenaBrain.generateHealthPlan(state!);

      // 2. Marcar onboarding como completado
      final userCompleted = state!.copyWith(onboardingCompleted: true);
      final repo = _ref.read(userControllerProvider.notifier);

      // 3. Guardar Plan y Usuario en Firestore
      await repo.saveHealthPlan(userCompleted.uid, clinicalPlan);
      await repo.saveUser(userCompleted);

      // 4. Generar primer MeasurementLog automático
      await _generateInitialMeasurement(userCompleted);

      // 5. Generar IMX Baseline
      await _generateBaselineIMX(userCompleted);

      debugPrint('Plan Clínico e IMX Generados Exitosamente');
      // La navegación la maneja la vista
    } catch (e) {
      debugPrint('Error en onboarding submit: $e');
      rethrow;
    }
  }

  double _calculateSleepHours(String bedTimeStr, String wakeUpTimeStr) {
    try {
      final bedParts = bedTimeStr.split(':');
      final wakeParts = wakeUpTimeStr.split(':');
      final bedHour = int.parse(bedParts[0]) + int.parse(bedParts[1]) / 60.0;
      final wakeHour = int.parse(wakeParts[0]) + int.parse(wakeParts[1]) / 60.0;
      
      double diff = wakeHour - bedHour;
      if (diff < 0) {
        diff += 24.0;
      }
      return diff;
    } catch (e) {
      return 8.0; // Fallback
    }
  }

  Future<void> _generateBaselineIMX(UserModel user) async {
      try {
        // Proxies baseados en los hábitos iniciales
        double avgFasting = user.fastingExperience == FastingExperience.advanced ? 16.0 
                          : user.fastingExperience == FastingExperience.intermediate ? 14.0 
                          : 12.0;
        int energyLevel = user.energyLevel1To10 ?? (user.snackingHabit == SnackingHabit.frequent ? 4 : 7);
        double nutritionScore = user.snackingHabit == SnackingHabit.frequent ? 40.0 : 80.0;
        double exerciseScore = user.activityLevel == ActivityLevel.heavy ? 90.0
                             : user.activityLevel == ActivityLevel.moderate ? 70.0
                             : user.activityLevel == ActivityLevel.light ? 40.0
                             : 20.0;
        
        // Sueño (Dinámico basado en ritmos circadianos)
        double sleepHours = _calculateSleepHours(user.bedTime, user.wakeUpTime); 

        await _ref.read(imxServiceProvider.notifier).calculateAndSave(
          waistCm: user.waistCircumferenceCm,
          heightCm: user.heightCm,
          hipCm: user.hipCircumferenceCm ?? user.waistCircumferenceCm * 1.2, // Fallback aproximado
          neckCm: user.neckCircumferenceCm,
          avgFastingHours: avgFasting,
          energyLevel1To10: energyLevel,
          nutritionAdherenceScore: nutritionScore,
          exerciseAdherenceScore: exerciseScore,
          avgSleepHours: sleepHours,
        );
      } catch (e) {
         debugPrint('Error generando baseline IMX: $e');
      }
  }

  Future<void> _generateInitialMeasurement(UserModel user) async {
    try {
      final bodyFat = MeasurementLog.calculateBodyFat(
        heightCm: user.heightCm,
        waistCm: user.waistCircumferenceCm,
        neckCm: user.neckCircumferenceCm,
        hipCm: user.hipCircumferenceCm,
        isMale: user.gender == Gender.male,
      );

      double? leanMass;
      if (bodyFat != null) {
        leanMass = 100.0 - bodyFat;
      }

      final initialLog = MeasurementLog(
        id: '',
        date: DateTime.now(),
        weight: user.currentWeightKg,
        waistCircumference: user.waistCircumferenceCm,
        neckCircumference: user.neckCircumferenceCm,
        hipCircumference: user.hipCircumferenceCm,
        bodyFatPercentage: bodyFat,
        muscleMassPercentage: leanMass,
        energyLevel: 5,
      );

      // Usando las capas de repositorio/servicio para aislar la BD del controlador UI
      await _ref.read(progressServiceProvider).addFullMeasurement(user.uid, initialLog);

      debugPrint('Initial Measurement Log created.');
    } catch (e) {
      debugPrint('Error creating initial measurement: $e');
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider.autoDispose<OnboardingController, UserModel?>((ref) {
  return OnboardingController(ref);
});
