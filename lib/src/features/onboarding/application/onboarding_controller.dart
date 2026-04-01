import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import '../../authentication/auth_service.dart';
import '../../authentication/application/register_controller.dart';
import '../../progress/domain/measurement_log.dart';
import '../../progress/data/progress_service.dart';
import '../../../domain/logic/elena_brain.dart';
import '../../profile/data/user_repository.dart';
import '../../../shared/domain/models/user_food_preferences.dart';

class OnboardingController extends StateNotifier<UserModel?> {
  final Ref _ref;

  OnboardingController(this._ref) : super(null);

  /// Inicializa el estado con el usuario actual o carga el existente de Firestore
  Future<void> init(String uid, String email, String displayName) async {
    // 0. Si ya está inicializado (estado no nulo), no sobreescribimos
    if (state != null) return;

    // 1. Intentamos cargar el perfil base de Firestore
    final existingUser =
        await _ref.read(authServiceProvider).userStream(uid).first;

    // 2. Recuperamos el nombre del proveedor temporal si existe
    final tempName = _ref.read(tempRegistrationNameProvider);

    // 3. Establecemos el nombre final
    final String finalName =
        (existingUser?.name != null && existingUser!.name.isNotEmpty)
            ? existingUser.name
            : (tempName != null && tempName.isNotEmpty)
                ? tempName
                : displayName;

    if (existingUser != null) {
      state = existingUser.copyWith(name: finalName);
    } else {
      state = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        name: finalName,
        heightCm: 160,
        currentWeightKg: 60,
        waistCircumferenceCm: 70,
        neckCircumferenceCm: 35,
        hipCircumferenceCm: 90,
        activityLevel: ActivityLevel.sedentary,
        snackingHabit: SnackingHabit.sometimes,
        dietaryPreference: DietaryPreference.omnivore,
        birthDate: DateTime(1990, 1, 1),
        gender: Gender.female,
        wakeUpTime: '07:00',
        bedTime: '23:00',
        usualFirstMealTime: '08:00',
        usualLastMealTime: '20:00',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }
  }

  void updateUser(UserModel newUser) {
    state = newUser;
  }

  Future<void> submit(UserFoodPreferences? foodPrefs) async {
    if (state == null) {
      debugPrint('❌ OnboardingController: Intento de submit con state nulo.');
      return;
    }

    try {
      debugPrint('🚀 OnboardingController: Iniciando persistencia final...');

      // 1. Calcular índices metabólicos (metaICA, metaICC)
      final indices = ElenaBrain.calculateIndices(
        state!.heightCm,
        state!.waistCircumferenceCm,
        state!.hipCircumferenceCm,
      );

      // 2. Crear el objeto final con todos los datos recogidos
      final updatedUser = state!.copyWith(
        metaICA: indices['metaICA'],
        metaICC: indices['metaICC'],
        onboardingCompleted: true,
        updatedAt: DateTime.now(),
      );

      debugPrint('📊 User Data to Save: ${updatedUser.toJson()}');

      // 3. Guardar en Firestore usando AuthService
      await _ref.read(authServiceProvider).completeOnboarding(updatedUser);

      // 4. Guardar preferencias alimentarias si existen
      if (foodPrefs != null) {
        debugPrint('🍎 Guardando preferencias alimentarias...');
        await _ref
            .read(userRepositoryProvider)
            .saveUserFoodPreferences(updatedUser.uid, foodPrefs);
      }

      // 5. Actualizar estado local para evitar race conditions en navegación
      state = updatedUser;
      _ref.read(onboardingJustFinishedProvider.notifier).state = true;

      // 6. Generar primer MeasurementLog automático
      await _generateInitialMeasurement(updatedUser);

      debugPrint('✅ Onboarding Completado Exitosamente');
    } catch (e, stack) {
      debugPrint('❌ Error en onboarding submit: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<void> _generateInitialMeasurement(UserModel user) async {
    try {
      final isMale = user.gender == Gender.male;

      final bodyFat = ElenaBrain.calculateBodyFat(
        heightCm: user.heightCm,
        waistCm: user.waistCircumferenceCm,
        neckCm: user.neckCircumferenceCm,
        hipCm: user.hipCircumferenceCm,
        isMale: isMale,
      );

      double? muscleMass;
      if (bodyFat != null) {
        muscleMass = 100.0 - bodyFat;
      }

      final initialLog = MeasurementLog(
        id: '',
        date: DateTime.now(),
        weight: user.currentWeightKg,
        waistCircumference: user.waistCircumferenceCm,
        neckCircumference: user.neckCircumferenceCm,
        hipCircumference: user.hipCircumferenceCm,
        bodyFatPercentage: bodyFat,
        muscleMassPercentage: muscleMass,
        energyLevel: 5,
      );

      await _ref
          .read(progressServiceProvider)
          .addFullMeasurement(user.uid, initialLog);

      debugPrint('Initial Measurement Log created.');
    } catch (e) {
      debugPrint('Error creating initial measurement: $e');
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, UserModel?>((ref) {
  return OnboardingController(ref);
});

final onboardingFoodPreferencesProvider =
    StateProvider<UserFoodPreferences>((ref) {
  return UserFoodPreferences.empty();
});

/// Flag temporal para avisar al Router que acabamos de terminar el onboarding
/// y evitar el rebote por latencia de Firestore.
final onboardingJustFinishedProvider = StateProvider<bool>((ref) => false);
