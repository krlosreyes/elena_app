import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/presentation/login_screen.dart'; // Reutilizar colores si es posible o usar Theme
import '../../../profile/domain/user_model.dart';
import '../onboarding_controller.dart';

class StepBio extends ConsumerStatefulWidget {
  const StepBio({super.key});

  @override
  ConsumerState<StepBio> createState() => _StepBioState();
}

class _StepBioState extends ConsumerState<StepBio> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(onboardingControllerProvider);
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Comencemos por lo básico',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tu biología es única. Necesitamos estos datos para calcular tus bases metabólicas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          const Text('Género Biológico',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RadioListTile<Gender>(
            title: const Text('Femenino'),
            value: Gender.female,
            groupValue: user.gender,
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(onboardingControllerProvider.notifier)
                    .updateUser(user.copyWith(gender: value));
              }
            },
            activeColor: const Color(0xFF009688),
          ),
          RadioListTile<Gender>(
            title: const Text('Masculino'),
            value: Gender.male,
            groupValue: user.gender,
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(onboardingControllerProvider.notifier)
                    .updateUser(user.copyWith(gender: value));
              }
            },
            activeColor: const Color(0xFF009688),
          ),
          const SizedBox(height: 32),
          const Text('Fecha de Nacimiento',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: user.birthDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ref
                    .read(onboardingControllerProvider.notifier)
                    .updateUser(user.copyWith(birthDate: picked));
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              '${user.birthDate.day}/${user.birthDate.month}/${user.birthDate.year}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
