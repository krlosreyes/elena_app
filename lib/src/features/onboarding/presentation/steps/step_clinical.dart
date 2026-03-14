import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/domain/user_model.dart';
import '../onboarding_controller.dart';

class StepClinical extends ConsumerWidget {
  const StepClinical({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(onboardingControllerProvider);
    if (user == null) return const SizedBox.shrink();

    final pathologies = user.pathologies;

    void togglePathology(String key, bool? value) {
      final currentList = List<String>.from(pathologies);
      if (value == true) {
        currentList.add(key);
      } else {
        currentList.remove(key);
      }
      ref
          .read(onboardingControllerProvider.notifier)
          .updateUser(user.copyWith(pathologies: currentList));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Perfil Clínico',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecciona si tienes alguna de estas condiciones diagnosticadas:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Prediabetes / Resistencia Insulina'),
            value: pathologies.contains('prediabetes') ||
                pathologies.contains('insulin_resistance'),
            onChanged: (val) {
              togglePathology('prediabetes', val);
              togglePathology('insulin_resistance', val);
            },
            activeColor: const Color(0xFF009688),
          ),
          CheckboxListTile(
            title: const Text('Hipotiroidismo'),
            value: pathologies.contains('hypothyroidism'),
            onChanged: (val) => togglePathology('hypothyroidism', val),
            activeColor: const Color(0xFF009688),
          ),
          CheckboxListTile(
            title: const Text('Síndrome Metabólico'),
            value: pathologies.contains('metabolic_syndrome'),
            onChanged: (val) => togglePathology('metabolic_syndrome', val),
            activeColor: const Color(0xFF009688),
          ),
          CheckboxListTile(
            title: const Text('Anemia'),
            value: pathologies.contains('anemia'),
            onChanged: (val) => togglePathology('anemia', val),
            activeColor: const Color(0xFF009688),
          ),
          CheckboxListTile(
            title: const Text('Ninguna de las anteriores'),
            value: pathologies.contains('none'),
            onChanged: (val) {
                // Si selecciona 'none', limpiamos las otras
                if (val == true) {
                    ref.read(onboardingControllerProvider.notifier).updateUser(
                        user.copyWith(pathologies: ['none']));
                } else {
                    togglePathology('none', val);
                }
            },
            activeColor: const Color(0xFF009688),
          ),
          const SizedBox(height: 32),
          const Text(
            'Nivel de Actividad o Ejercicio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildActivityOption(
            context,
            ref,
            user.activityLevel,
            ActivityLevel.heavy,
            'Atleta / Intenso',
            'Entreno duro 5-6 días por semana.',
            Icons.fitness_center,
          ),
          const SizedBox(height: 8),
          _buildActivityOption(
            context,
            ref,
            user.activityLevel,
            ActivityLevel.moderate,
            'Moderado / Frecuente',
            'Hago ejercicio moderado 3-5 días por semana.',
            Icons.directions_run,
          ),
          const SizedBox(height: 8),
          _buildActivityOption(
            context,
            ref,
            user.activityLevel,
            ActivityLevel.light,
            'Ligero / Ocasional',
            'Camino o hago algo ligero 1-3 días por semana.',
            Icons.directions_walk,
          ),
          const SizedBox(height: 8),
          _buildActivityOption(
            context,
            ref,
            user.activityLevel,
            ActivityLevel.sedentary,
            'Sedentario',
            'Trabajo en escritorio, poco movimiento diario.',
            Icons.event_seat,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityOption(BuildContext context, WidgetRef ref, ActivityLevel currentValue, ActivityLevel optionValue, String title, String description, IconData icon) {
    final isSelected = currentValue == optionValue;
    return InkWell(
      onTap: () {
        final user = ref.read(onboardingControllerProvider);
        if (user != null) {
           ref.read(onboardingControllerProvider.notifier).updateUser(user.copyWith(activityLevel: optionValue));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009688).withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF009688) : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF009688) : Colors.grey, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
               const Icon(Icons.check_circle, color: Color(0xFF009688)),
          ],
        ),
      ),
    );
  }
}
