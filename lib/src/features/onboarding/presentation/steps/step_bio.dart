import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Reutilizar colores si es posible o usar Theme
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
          const SizedBox(height: 32),
          const Text('Género Biológico',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  context,
                  ref,
                  user.gender,
                  Gender.female,
                  'Femenino',
                  Icons.female,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderCard(
                  context,
                  ref,
                  user.gender,
                  Gender.male,
                  'Masculino',
                  Icons.male,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Fecha de Nacimiento',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.grey[800]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${user.birthDate.day.toString().padLeft(2, '0')}/${user.birthDate.month.toString().padLeft(2, '0')}/${user.birthDate.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF009688),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.calendar_today, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(BuildContext context, WidgetRef ref, Gender currentGender, Gender optionGender, String title, IconData icon) {
    final isSelected = currentGender == optionGender;
    return InkWell(
      onTap: () {
        final user = ref.read(onboardingControllerProvider);
        if (user != null) {
          ref.read(onboardingControllerProvider.notifier).updateUser(user.copyWith(gender: optionGender));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009688).withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF009688) : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? const Color(0xFF009688) : Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
