import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding_controller.dart';

class StepCircadian extends ConsumerWidget {
  const StepCircadian({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref, String current,
      Function(String) onSave) async {
    final parts = current.split(':');
    final initial =
        TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onSave(formatted);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(onboardingControllerProvider);
    if (user == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tus Ritmos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Entender tu horario nos ayuda a optimizar tus ventanas de ayuno.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildTimeRow(
            context,
            ref,
            'Hora de despertar',
            user.wakeUpTime,
            (val) => ref
                .read(onboardingControllerProvider.notifier)
                .updateUser(user.copyWith(wakeUpTime: val)),
          ),
          _buildTimeRow(
            context,
            ref,
            'Primera Comida',
            user.usualFirstMealTime,
            (val) => ref
                .read(onboardingControllerProvider.notifier)
                .updateUser(user.copyWith(usualFirstMealTime: val)),
          ),
          _buildTimeRow(
            context,
            ref,
            'Última Comida',
            user.usualLastMealTime,
            (val) => ref
                .read(onboardingControllerProvider.notifier)
                .updateUser(user.copyWith(usualLastMealTime: val)),
          ),
          _buildTimeRow(
            context,
            ref,
            'Hora de dormir',
            user.bedTime,
            (val) => ref
                .read(onboardingControllerProvider.notifier)
                .updateUser(user.copyWith(bedTime: val)),
          ),
          const SizedBox(height: 32),
          const Text(
            'Nivel de Energía / Antojos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildEnergyOption(
            context,
            ref,
            user.energyLevel1To10 ?? 7,
            10,
            'Energía estable todo el día',
            Icons.battery_full,
          ),
          const SizedBox(height: 8),
          _buildEnergyOption(
            context,
            ref,
            user.energyLevel1To10 ?? 7,
            7,
            'Bajones de energía en la tarde',
            Icons.battery_4_bar,
          ),
          const SizedBox(height: 8),
          _buildEnergyOption(
            context,
            ref,
            user.energyLevel1To10 ?? 7,
            4,
            'Muchos antojos de azúcar/carbohidratos',
            Icons.cookie,
          ),
          const SizedBox(height: 8),
          _buildEnergyOption(
            context,
            ref,
            user.energyLevel1To10 ?? 7,
            1,
            'Exhausto/a constantemente',
            Icons.battery_0_bar,
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyOption(BuildContext context, WidgetRef ref, int currentValue, int optionValue, String label, IconData icon) {
    final isSelected = currentValue == optionValue;
    return InkWell(
      onTap: () {
        final user = ref.read(onboardingControllerProvider);
        if (user != null) {
           ref.read(onboardingControllerProvider.notifier).updateUser(user.copyWith(energyLevel1To10: optionValue));
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
            Icon(icon, color: isSelected ? const Color(0xFF009688) : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
               const Icon(Icons.check_circle, color: Color(0xFF009688)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context, WidgetRef ref, String label,
      String value, Function(String) onSave) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => _pickTime(context, ref, value, onSave),
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, color: Color(0xFF009688)), // Teal
            ),
          ),
        ],
      ),
    );
  }
}
