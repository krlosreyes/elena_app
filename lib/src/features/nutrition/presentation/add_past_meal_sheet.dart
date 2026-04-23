/// SPEC-21: Bottom sheet para registrar comidas pasadas (datos históricos)
/// Permite usuario nuevo poblar datos reales desde el inicio del día

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/nutrition/presentation/widgets/meal_time_picker.dart';

class AddPastMealSheet extends ConsumerStatefulWidget {
  const AddPastMealSheet({super.key});

  @override
  ConsumerState<AddPastMealSheet> createState() => _AddPastMealSheetState();
}

class _AddPastMealSheetState extends ConsumerState<AddPastMealSheet> {
  late TimeOfDay _selectedTime;
  String _selectedMeal = 'Desayuno';
  bool _isSaving = false;
  bool _isOutsideWindow = false;

  final List<String> _mealOptions = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _checkIfOutsideWindow();
  }

  /// Verifica si la hora seleccionada está fuera de la ventana circadiana
  void _checkIfOutsideWindow() {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    final first = user.profile.firstMealGoal;
    final last = user.profile.lastMealGoal;
    if (first == null || last == null) return;

    final timeMinutes = _selectedTime.hour * 60 + _selectedTime.minute;
    final firstMinutes = first.hour * 60 + first.minute;
    final lastMinutes = last.hour * 60 + last.minute;

    setState(() {
      _isOutsideWindow = !(timeMinutes >= firstMinutes && timeMinutes <= lastMinutes);
    });
  }

  Future<void> _saveMeal() async {
    if (_isSaving) return;

    final now = DateTime.now();
    final mealDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() => _isSaving = true);

    try {
      await ref
          .read(nutritionProvider.notifier)
          .logMeal(label: _selectedMeal, mealTime: mealDateTime);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ $_selectedMeal registrado a las ${_selectedTime.format(context)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF2D9B60),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserStreamProvider).value;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────────────
              const Text(
                'REGISTRAR COMIDA PASADA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registra comidas que ya ocurrieron hoy para construir tu historial',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),

              // ── Selector de tipo de comida ─────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TIPO DE COMIDA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _mealOptions.map((meal) {
                      final isSelected = _selectedMeal == meal;
                      return FilterChip(
                        label: Text(
                          meal,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedMeal = meal);
                          }
                        },
                        backgroundColor: Colors.transparent,
                        selectedColor: const Color(0xFF2D9B60).withOpacity(0.3),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2D9B60)
                              : Colors.white.withOpacity(0.2),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Time Picker ────────────────────────────────────────────────────
              MealTimePicker(
                initialTime: _selectedTime,
                label: 'HORA DE LA COMIDA',
                onTimeSelected: (dateTime) {
                  setState(() {
                    _selectedTime = TimeOfDay.fromDateTime(dateTime);
                    _checkIfOutsideWindow();
                  });
                },
              ),
              const SizedBox(height: 24),

              // ── Advertencia si está fuera de ventana ───────────────────────────
              if (_isOutsideWindow) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fuera de ventana circadiana',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Esta comida está fuera de tu ventana configurada (${user?.profile.firstMealGoal?.hour}:${user?.profile.firstMealGoal?.minute.toString().padLeft(2, '0')} - ${user?.profile.lastMealGoal?.hour}:${user?.profile.lastMealGoal?.minute.toString().padLeft(2, '0')})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Vista previa ───────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: _isOutsideWindow ? Colors.orange : const Color(0xFF2D9B60),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vas a registrar: $_selectedMeal a las ${_selectedTime.format(context)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Botones ────────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMeal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar comida',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9B60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
