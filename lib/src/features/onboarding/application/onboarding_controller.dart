import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/services/size_mapper_service.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';

/// Proveedor del repositorio (Inyectamos la dependencia de forma global)
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class OnboardingController extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repository;

  OnboardingController(this._repository) : super(const AsyncValue.data(null));

  /// Procesa la inferencia biométrica y persiste el usuario enriquecido en Firestore
  Future<void> completeOnboarding(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      UserModel enrichedUser = user;

      // 1. Ejecución de Inferencia si no hay medidas manuales validadas
      // Si waistCircumference es nulo o 0, el sistema asume que debe inferir por tallas
      if (user.waistCircumference == null || user.waistCircumference == 0) {
        final inferredData = SizeMapperService.inferCrossed(
          pantSize: user.pantSize,
          shirtSize: user.shirtSize,
          gender: user.gender,
        );

        final double inferredWaist = inferredData['waist'] ?? 0;
        final double inferredNeck = inferredData['neck'] ?? 0;

        // 2. Cálculo de Grasa Corporal basado en la inferencia (Fórmula Navy)
        final double calculatedFat = SizeMapperService.calculateBodyFat(
          waist: inferredWaist,
          neck: inferredNeck,
          height: user.height,
          gender: user.gender,
        );

        // Actualizamos el modelo con los datos proyectados
        enrichedUser = user.copyWith(
          waistCircumference: inferredWaist,
          neckCircumference: inferredNeck,
          bodyFatPercentage: calculatedFat,
          isMeasurementEstimated: true,
          confidenceLevel: 'MEDIA-PROBABILÍSTICA',
        );
      }

      // 3. Persistencia Real en la colección 'users' de Firestore
      // Esto ahora usa la instancia segura para Web del UserRepository
      await _repository.saveUser(enrichedUser);
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      // Capturamos el error para que la UI pueda mostrar un SnackBar o alerta
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider que será consumido por la OnboardingScreen
final onboardingControllerProvider = 
    StateNotifierProvider<OnboardingController, AsyncValue<void>>((ref) {
  // Usamos watch para mantener la reactividad si el provider del repositorio cambia
  final repository = ref.watch(userRepositoryProvider);
  return OnboardingController(repository);
});