import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/domain/user_model.dart';
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
          const Text('Nivel de Actividad',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<ActivityLevel>(
            value: user.activityLevel,
            items: ActivityLevel.values.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(onboardingControllerProvider.notifier)
                    .updateUser(user.copyWith(activityLevel: value));
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
