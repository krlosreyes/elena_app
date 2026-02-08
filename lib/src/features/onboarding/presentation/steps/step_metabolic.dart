import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_controller.dart';

class StepMetabolic extends ConsumerWidget {
  const StepMetabolic({super.key});

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
            'Indicadores Metabólicos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Estos datos son cruciales para calcular tu porcentaje de grasa real (RFM) y riesgo cardiovascular.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Text(
            'Cintura (ombligo): ${user.waistCircumferenceCm.toStringAsFixed(1)} cm',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: user.waistCircumferenceCm,
            min: 40,
            max: 150,
            divisions: 220,
            label: user.waistCircumferenceCm.toStringAsFixed(1),
            activeColor: const Color(0xFF009688),
            onChanged: (value) {
              ref
                  .read(onboardingControllerProvider.notifier)
                  .updateUser(user.copyWith(waistCircumferenceCm: value));
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Cuello: ${user.neckCircumferenceCm.toStringAsFixed(1)} cm',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: user.neckCircumferenceCm,
            min: 20,
            max: 60,
            divisions: 80,
            label: user.neckCircumferenceCm.toStringAsFixed(1),
            activeColor: const Color(0xFF009688),
            onChanged: (value) {
              ref
                  .read(onboardingControllerProvider.notifier)
                  .updateUser(user.copyWith(neckCircumferenceCm: value));
            },
          ),
        ],
      ),
    );
  }
}
