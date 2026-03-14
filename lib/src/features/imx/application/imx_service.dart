import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../domain/imx_calculator.dart';
import '../domain/imx_model.dart';
import './imx_providers.dart';
import '../../authentication/application/auth_controller.dart';

part 'imx_service.g.dart';

@riverpod
class ImxService extends _$ImxService {
  @override
  FutureOr<ImxModel?> build() async {
    // Escuchar cambios de autenticación
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) {
      return null;
    }
    
    // Cargar el último IMX al inicializar el provider
    final repository = ref.watch(imxRepositoryProvider);
    return repository.getLatestImx(user.uid);
  }

  /// Helper para clasificar el puntaje IMX.
  ImxClassification _classifyScore(double score) {
    if (score <= 30) return ImxClassification.highRisk;
    if (score <= 50) return ImxClassification.warning;
    if (score <= 70) return ImxClassification.moderate;
    if (score <= 85) return ImxClassification.good;
    return ImxClassification.optimal;
  }

  /// Calcula el IMX y lo guarda en Firebase si hay un usuario logueado.
  /// Actualiza inmediatamente el estado del provider.
  Future<ImxModel> calculateAndSave({
    required double waistCm,
    required double heightCm,
    required double hipCm,
    required double neckCm,
    required double avgFastingHours,
    required int energyLevel1To10,
    required double nutritionAdherenceScore,
    required double exerciseAdherenceScore,
    required double avgSleepHours,
  }) async {
    state = const AsyncValue.loading();

    // 1. Cálculos de Dominio (Puros)
    final bodyScore = ImxCalculator.calculateBodyScore(waistCm, heightCm, hipCm, neckCm);
    final metabolicScore = ImxCalculator.calculateMetabolicScore(avgFastingHours, energyLevel1To10);
    final lifestyleScore = ImxCalculator.calculateLifestyleScore(nutritionAdherenceScore, exerciseAdherenceScore, avgSleepHours);
    
    final finalScore = ImxCalculator.calculateTotalIMX(
      waistCm: waistCm,
      heightCm: heightCm,
      hipCm: hipCm,
      neckCm: neckCm,
      avgFastingHours: avgFastingHours,
      energyLevel1To10: energyLevel1To10,
      nutritionAdherenceScore: nutritionAdherenceScore,
      exerciseAdherenceScore: exerciseAdherenceScore,
      avgSleepHours: avgSleepHours,
    );

    // 2. Crear Modelo
    final imx = ImxModel(
      id: const Uuid().v4(),
      score: finalScore,
      bodyScore: bodyScore,
      metabolicScore: metabolicScore,
      lifestyleScore: lifestyleScore,
      classification: _classifyScore(finalScore),
      calculatedAt: DateTime.now(),
    );

    // 3. Persistir en Firestore si existe usuario
    final user = ref.read(authControllerProvider.notifier).currentUser;
    if (user != null) {
      try {
        await ref.read(imxRepositoryProvider).saveImxCalculation(user.uid, imx);
      } catch (e) {
         // Podríamos manejar reintentos aquí, por ahora solo log y set state = data
         print("Error saving IMX, but updating local state.");
      }
    }

    // 4. Actualizar Estado (Optimistic / Reactive Update)
    state = AsyncValue.data(imx);
    
    return imx;
  }
}
