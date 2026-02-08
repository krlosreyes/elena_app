import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../profile/domain/user_model.dart';
import '../logic/elena_brain.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  UserModel? build() {
    // Inicializamos con datos vacíos o parciales si ya existe el usuario
    // Por ahora retornamos null hasta que carguemos o creemos uno nuevo
    return null;
  }

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
      final repo = ref.read(userRepositoryProvider);

      // 3. Guardar Plan y Usuario en Firestore
      await repo.saveHealthPlan(userCompleted.uid, clinicalPlan);
      await repo.saveUser(userCompleted);

      // 4. Log debug
      debugPrint('Plan Clínico Generado: $clinicalPlan');
      
      // La navegación la maneja la vista
    } catch (e) {
      debugPrint('Error en onboarding submit: $e');
      rethrow; // Para que la vista maneje el error
    }
  }
}
