import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nutrition/application/food_provider.dart';
import '../../profile/application/user_controller.dart';
import '../../../core/services/app_logger.dart';
import 'auth_controller.dart';

class RegisterController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  RegisterController(this._ref) : super(const AsyncValue.data(null));

  @override
  void dispose() {
    _ref.read(tempRegistrationNameProvider.notifier).state = null;
    super.dispose();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!mounted) return;
    state = const AsyncLoading();
    try {
      // Guardamos el nombre temporalmente
      _ref.read(tempRegistrationNameProvider.notifier).state = name;

      final authController = _ref.read(authControllerProvider.notifier);
      await authController.createUserWithEmailAndPassword(email, password);

      // Verificamos si la creación en Auth falló antes de seguir con Firestore
      final authState = _ref.read(authControllerProvider);
      if (authState is AsyncError) {
        throw authState.error;
      }

      final user = authController.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();

        // Crear perfil base
        final userController = _ref.read(userControllerProvider.notifier);
        final baseProfile = UserModel(
          uid: user.uid,
          email: email,
          displayName: name,
          name: name,
          onboardingCompleted: false,
        );
        await userController.saveUser(baseProfile);

        // 🌱 [AUTO-SEED] Sembrar alimentos iniciales en Firestore
        AppLogger.info('🌱 [AUTO-SEED] Iniciando seeding automático después del registro...');
        try {
          await _ref.read(foodRepositoryProvider).seedInitialNutritionData();
          AppLogger.info('✅ [AUTO-SEED] Seeding completado exitosamente\n');
        } catch (e) {
          AppLogger.error('⚠️ [AUTO-SEED] Error en seeding (no crítico): $e');
          AppLogger.info('ℹ️ El usuario puede disparar manualmente desde onboarding\n');
          // No lanzamos error, es solo seed automático
        }
      }
      if (mounted) state = const AsyncData(null);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, AsyncValue<void>>(
        (ref) {
  return RegisterController(ref);
});

/// Proveedor temporal para pasar el nombre del Registro al Onboarding sin depender de la latencia de Firestore
final tempRegistrationNameProvider = StateProvider<String?>((ref) => null);
