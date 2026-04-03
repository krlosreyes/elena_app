import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/models/meal_log.dart';
import '../../../authentication/data/auth_repository.dart';
import '../../../fasting/application/fasting_controller.dart'
    show mealModalTriggerProvider;
import '../../../health/data/health_repository.dart';
import '../../../profile/application/biometric_provider.dart';
import '../../../profile/data/user_repository.dart';
import '../../application/food_service.dart' as food_service;
import '../../application/meal_controller.dart';
import '../../application/transition_controller.dart';
import '../../domain/entities/food_model.dart';
import 'elena_dropdown_menu.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MEAL REGISTRATION MODAL - REDESIGNED FOR TAP-ONLY UX (DESIGN INVISIBLE)
// ─────────────────────────────────────────────────────────────────────────────

class MealRegistrationModal extends ConsumerStatefulWidget {
  const MealRegistrationModal({super.key});

  /// Opens the registration interface using the premium Dropdown Menu style
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authStateChangesProvider).valueOrNull;
    if (authState == null) return;

    final userId = authState.uid;
    final prefs = await ref.read(userFoodPreferencesProvider(userId).future);

    if (!context.mounted) return;

    // Map preferences to Dropdown Categories
    final categories = <ElenaDropdownCategory>[];

    if (prefs.proteins.isNotEmpty) {
      categories.add(ElenaDropdownCategory(
        title: 'Proteínas 🥩',
        items: prefs.proteins.map((name) => ElenaDropdownItem(
          title: name,
          icon: Icons.egg_rounded,
          onTap: () => _handleSelection(context, name, ref),
        )).toList(),
      ));
    }

    if (prefs.fats.isNotEmpty) {
      categories.add(ElenaDropdownCategory(
        title: 'Grasas 🥑',
        items: prefs.fats.map((name) => ElenaDropdownItem(
          title: name,
          icon: Icons.opacity_rounded,
          onTap: () => _handleSelection(context, name, ref),
        )).toList(),
      ));
    }

    if (prefs.carbs.isNotEmpty) {
      categories.add(ElenaDropdownCategory(
        title: 'Carbos/Fibra 🌾',
        items: prefs.carbs.map((name) => ElenaDropdownItem(
          title: name,
          icon: Icons.eco_rounded,
          onTap: () => _handleSelection(context, name, ref),
        )).toList(),
      ));
    }

    final dailyLog = ref.read(todayLogProvider(userId)).valueOrNull;
    final nextMealNumber = (dailyLog?.mealEntries.length ?? 0) + 1;

    return ElenaDropdownMenu.show(
      context: context,
      title: 'COMIDA $nextMealNumber',
      categories: categories,
    );
  }

  static Future<void> _handleSelection(BuildContext context, String foodName, WidgetRef ref) async {
    // We close the dropdown first to show the portion selection
    Navigator.pop(context);
    
    final foodService = ref.read(food_service.foodServiceProvider);
    final foodModel = await foodService.searchFood(foodName);

    if (foodModel == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontró: $foodName'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => _PortionSelectionDialog(
          foodModel: foodModel,
          ref: ref,
        ),
      );
    }
  }

  @override
  ConsumerState<MealRegistrationModal> createState() =>
      _MealRegistrationModalState();
}

class _PortionSelectionDialog extends StatelessWidget {
  final FoodModel foodModel;
  final WidgetRef ref;

  const _PortionSelectionDialog({
    required this.foodModel,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              foodModel.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SELECCIONA PORCIÓN',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPortionButton(
                  context: context,
                  label: 'LIGERO',
                  emoji: '🥗',
                  multiplier: 0.7,
                ),
                const SizedBox(width: 12),
                _buildPortionButton(
                  context: context,
                  label: 'NORMAL',
                  emoji: '🍽️',
                  multiplier: 1.0,
                ),
                const SizedBox(width: 12),
                _buildPortionButton(
                  context: context,
                  label: 'GENEROSO',
                  emoji: '🥘',
                  multiplier: 1.5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortionButton({
    required BuildContext context,
    required String label,
    required String emoji,
    required double multiplier,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          await _addMealWithPortion(
            context: context,
            multiplier: multiplier,
          );
          if (context.mounted) Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addMealWithPortion({
    required BuildContext context,
    required double multiplier,
  }) async {
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      final dailyLog = user != null
          ? ref.read(todayLogProvider(user.uid)).valueOrNull
          : null;

      if (user == null) return;

      final mealNum = (dailyLog?.mealEntries.length ?? 0) + 1;
      final mealType = mealNum == 1
          ? MealType.breakfast
          : (mealNum == 2
              ? MealType.lunch
              : (mealNum == 3 ? MealType.dinner : MealType.snack));

      final success = await ref.read(mealControllerProvider.notifier).registerMeal(
        name: foodModel.name,
        type: mealType,
        calories: (foodModel.calories * multiplier).toInt(),
        protein: (foodModel.protein * multiplier).toInt(),
        carbs: (foodModel.netCarbs * multiplier).toInt(),
        fat: (foodModel.fat * multiplier).toInt(),
      );

      if (!success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ LA VENTANA DE ESTA COMIDA AÚN NO ESTÁ ABIERTA'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return;
      }

      if (mealNum == 1) {
        await ref.read(transitionProvider.notifier).recordFirstMeal(
          foodModel.name,
          DateTime.now(),
        );
      }

      ref.invalidate(biometricResultProvider);
      ref.read(mealModalTriggerProvider.notifier).state = false;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${foodModel.name} añadido'),
            backgroundColor: AppTheme.primary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

class _MealRegistrationModalState extends ConsumerState<MealRegistrationModal> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
