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

  Future<void> submit(dynamic context) async {
    if (state == null) return;

    try {
      // 1. Generar Plan con ElenaBrain
      final plan = ElenaBrain.generatePlan(state!);

      // 2. Marcar onboarding como completado
      final userCompleted = state!.copyWith(onboardingCompleted: true);

      // 3. Guardar Usuario en Firestore
      await ref.read(userRepositoryProvider).saveUser(userCompleted);

      // 4. Guardar Plan (Idealmente en una subcolección 'plans' o en el usuario)
      // Por simplicidad en este paso, lo podríamos imprimir o guardar en un provider de "Plan Actual"
      // Para persistencia real, el UserRepository debería tener un método savePlan.
      // Vamos a asumir que por ahora solo guardamos el usuario y el plan se recalcula o se guarda después.
      // TODO: Implementar persistencia del RecommendationPlan
      debugPrint('Plan Generado: $plan');

      // 5. Navegar al Dashboard
      // ignore: use_build_context_synchronously
      (context as GoRouter).go('/dashboard');
    } catch (e) {
      debugPrint('Error en onboarding submit: $e');
      // Manejar error UI
    }
  }
}
