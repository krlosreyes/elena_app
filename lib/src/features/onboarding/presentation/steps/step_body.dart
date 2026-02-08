import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/domain/user_model.dart';
import '../onboarding_controller.dart';

class StepBody extends ConsumerWidget {
  const StepBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(onboardingControllerProvider);
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Medidas Corporales',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Altura: ${user.heightCm.toStringAsFixed(0)} cm',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: user.heightCm,
            min: 100,
            max: 220,
            divisions: 120,
            label: user.heightCm.round().toString(),
            activeColor: const Color(0xFF009688),
            onChanged: (value) {
              ref
                  .read(onboardingControllerProvider.notifier)
                  .updateUser(user.copyWith(heightCm: value));
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Peso Actual: ${user.currentWeightKg.toStringAsFixed(1)} kg',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: user.currentWeightKg,
            min: 30,
            max: 150,
            divisions: 240,
            label: user.currentWeightKg.toStringAsFixed(1),
            activeColor: const Color(0xFF009688),
            onChanged: (value) {
              ref
                  .read(onboardingControllerProvider.notifier)
                  .updateUser(user.copyWith(currentWeightKg: value));
            },
          ),
        ],
      ),
    );
  }
}
