import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';

class ExerciseInputSheet extends ConsumerStatefulWidget {
  const ExerciseInputSheet({super.key});

  @override
  ConsumerState<ExerciseInputSheet> createState() => _ExerciseInputSheetState();
}

class _ExerciseInputSheetState extends ConsumerState<ExerciseInputSheet> {
  int _minutes = 45;
  String _activityType = "Cardio";
  final List<String> _activities = ["Caminata", "Cardio", "Fuerza", "HIIT", "Otro"];

  void _submit() {
    ref.read(exerciseProvider.notifier).registerExercise(
      minutes: _minutes,
      activityType: _activityType,
      timestamp: DateTime.now(),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(error.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.redAccent)
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text("REGISTRAR EJERCICIO", 
             style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
             textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text("DURACIÓN (MIN)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
               Row(
                 children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.metabolicGreen),
                      onPressed: () => setState(() => _minutes = (_minutes - 5).clamp(5, 120)),
                    ),
                    Text("$_minutes", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.metabolicGreen),
                      onPressed: () => setState(() => _minutes = (_minutes + 5).clamp(5, 120)),
                    ),
                 ],
               )
            ],
          ),
          const SizedBox(height: 16),
          const Text("TIPO DE ACTIVIDAD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _activities.map((a) {
               final isSelected = _activityType == a;
               return ChoiceChip(
                  label: Text(a),
                  selected: isSelected,
                  selectedColor: AppColors.metabolicGreen.withOpacity(0.2),
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(color: isSelected ? AppColors.metabolicGreen : Colors.transparent),
                  onSelected: (val) => setState(() => _activityType = a),
               );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: state.isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.metabolicGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state.isSaving 
                 ? const CircularProgressIndicator(color: Colors.white)
                 : const Text("GUARDAR REGISTRO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16), 
        ],
      )
    );
  }
}
