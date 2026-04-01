import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../profile/data/user_repository.dart';
import '../../../shared/domain/models/user_model.dart';

part 'tour_controller.g.dart';

enum TourStatus {
  idle,
  active,
  completed,
}

class TourState {
  final int currentStep;
  final TourStatus status;

  const TourState({
    required this.currentStep,
    required this.status,
  });

  TourState copyWith({
    int? currentStep,
    TourStatus? status,
  }) {
    return TourState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
    );
  }
}

@riverpod
class TourController extends _$TourController {

  @override
  TourState build() {
    return const TourState(currentStep: 0, status: TourStatus.idle);
  }

  bool shouldStartTour(UserModel? user) {
    if (user == null) return false;

    // Si ya está activo o completado en esta sesión, no iniciamos
    if (state.status != TourStatus.idle) return false;

    // Si el usuario ya completó el tour en DB, no lo mostramos jamás
    return !user.hasCompletedTour;
  }

  void startTour() {
    state = state.copyWith(status: TourStatus.active, currentStep: 0);
  }

  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    } else {
      completeTour();
    }
  }

  Future<void> completeTour() async {
    state = state.copyWith(status: TourStatus.completed);

    // Persistencia en DB (Fuente Única de Verdad)
    final userRepo = ref.read(userRepositoryProvider);
    final user = await userRepo.getUser();
    if (user != null) {
      final updatedUser = user.copyWith(hasCompletedTour: true);
      await userRepo.saveUser(updatedUser);
    }
  }

  void reset() {
    state = const TourState(currentStep: 0, status: TourStatus.idle);
  }
}
