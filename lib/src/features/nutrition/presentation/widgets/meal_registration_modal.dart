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
import '../../application/meal_controller.dart';
import '../../application/transition_controller.dart';
import '../../application/food_service.dart' as food_service;
import '../../domain/entities/food_model.dart';
import 'elena_food_search_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MEAL REGISTRATION MODAL - REDESIGNED FOR TAP-ONLY UX
// ─────────────────────────────────────────────────────────────────────────────

class MealRegistrationModal extends ConsumerStatefulWidget {
  const MealRegistrationModal({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const MealRegistrationModal(),
    );
  }

  @override
  ConsumerState<MealRegistrationModal> createState() =>
      _MealRegistrationModalState();
}

class _MealRegistrationModalState extends ConsumerState<MealRegistrationModal> {
  // Track selected food for visual feedback
  String? _selectedFoodName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const BeveledRectangleBorder(
        side: BorderSide(color: AppTheme.primary, width: 1),
      ),
      title: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authStateChangesProvider).valueOrNull;
          if (authState == null) {
            debugPrint(
                '⚠️ [MEAL MODAL] No auth user detected in title builder');
            return const SizedBox();
          }
          final dailyLog =
              ref.watch(todayLogProvider(authState.uid)).valueOrNull;
          final nextMealNumber = (dailyLog?.mealEntries.length ?? 0) + 1;

          return Text(
            'COMIDA $nextMealNumber 🍽️',
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 2.0,
            ),
          );
        },
      ),
      content: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authStateChangesProvider).valueOrNull;

          if (authState == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Sincronizando sesión...\nSi este mensaje persiste, verifica tu conexión.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                      color: Colors.white38, fontSize: 12),
                ),
              ),
            );
          }

          final userId = authState.uid;
          final screenWidth = MediaQuery.of(context).size.width;

          return SizedBox(
            width: screenWidth > 500 ? 420 : screenWidth * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BUSCADOR RÁPIDO (Por si no hay preferencias)
                  ElenaFoodSearchField(
                    onFoodSelected: (food) =>
                        _showQuickAddOverlay(context, food.name, ref),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'TUS PREFERENCIAS RÁPIDAS',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Build the three horizontal scrollable sections
                  _buildFoodCategoriesUI(ref, userId),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CERRAR',
            style: GoogleFonts.jetBrainsMono(color: Colors.white38),
          ),
        ),
      ],
    );
  }

  /// Build the three horizontal scrollable food categories
  Widget _buildFoodCategoriesUI(WidgetRef ref, String userId) {
    final prefsAsync = ref.watch(userFoodPreferencesProvider(userId));

    return prefsAsync.when(
      data: (prefs) {
        if (prefs.proteins.isEmpty &&
            prefs.fats.isEmpty &&
            prefs.carbs.isEmpty) {
          return Center(
            child: Text(
              'Sin preferencias guardadas',
              style: GoogleFonts.publicSans(color: Colors.white38),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // SECTION 1: PROTEINS
            if (prefs.proteins.isNotEmpty) ...[
              _buildCategorySection(
                title: 'TUS PROTEÍNAS 🥩',
                foods: prefs.proteins,
                ref: ref,
              ),
              const SizedBox(height: 20),
            ],

            // SECTION 2: FATS
            if (prefs.fats.isNotEmpty) ...[
              _buildCategorySection(
                title: 'TUS GRASAS 🥑',
                foods: prefs.fats,
                ref: ref,
              ),
              const SizedBox(height: 20),
            ],

            // SECTION 3: CARBS
            if (prefs.carbs.isNotEmpty) ...[
              _buildCategorySection(
                title: 'CARBOS/FIBRA 🌾',
                foods: prefs.carbs,
                ref: ref,
              ),
            ],
          ],
        );
      },
      loading: () => Center(
        child: Container(
          height: 150,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'CARGANDO PREFERENCIAS...',
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (err, _) => Center(
        child: Text(
          'Error: $err',
          style: GoogleFonts.publicSans(color: Colors.redAccent),
        ),
      ),
    );
  }

  /// Build a single category section with horizontal scroll
  Widget _buildCategorySection({
    required String title,
    required List<String> foods,
    required WidgetRef ref,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final foodName = foods[index];
              final isSelected = _selectedFoodName == foodName;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildFoodActionChip(
                  foodName: foodName,
                  isSelected: isSelected,
                  onTap: () => _showQuickAddOverlay(
                    context,
                    foodName,
                    ref,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build an action chip for each food
  Widget _buildFoodActionChip({
    required String foodName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.primary.withValues(alpha: 0.08),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              foodName,
              style: GoogleFonts.publicSans(
                color: isSelected ? AppTheme.primary : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                '✓',
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show the mini overlay with 3 preset portions
  Future<void> _showQuickAddOverlay(
    BuildContext context,
    String foodName,
    WidgetRef ref,
  ) async {
    // Heavy haptic feedback on selection
    HapticFeedback.heavyImpact();

    // Update UI state
    setState(() {
      _selectedFoodName = foodName;
    });

    // Fetch the full FoodModel using FoodService
    try {
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
        // Show the mini overlay with portion options
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => _buildPortionOverlay(
            context: context,
            foodModel: foodModel,
            ref: ref,
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
    } finally {
      // Reset selection
      if (mounted) {
        setState(() {
          _selectedFoodName = null;
        });
      }
    }
  }

  /// Build the portion mini-overlay with 3 preset sizes
  Widget _buildPortionOverlay({
    required BuildContext context,
    required FoodModel foodModel,
    required WidgetRef ref,
  }) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const BeveledRectangleBorder(
        side: BorderSide(color: AppTheme.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Food name
            Text(
              foodModel.name,
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),

            // Portion buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Light portion (0.7x)
                _buildPortionButton(
                  context: context,
                  label: '🥗\nLIGERO',
                  multiplier: 0.7,
                  foodModel: foodModel,
                  ref: ref,
                ),
                const SizedBox(width: 12),

                // Normal portion (1.0x)
                _buildPortionButton(
                  context: context,
                  label: '🍽️\nNORMAL',
                  multiplier: 1.0,
                  foodModel: foodModel,
                  ref: ref,
                ),
                const SizedBox(width: 12),

                // Generous portion (1.5x)
                _buildPortionButton(
                  context: context,
                  label: '🥘\nGENEROSO',
                  multiplier: 1.5,
                  foodModel: foodModel,
                  ref: ref,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a portion button
  Widget _buildPortionButton({
    required BuildContext context,
    required String label,
    required double multiplier,
    required FoodModel foodModel,
    required WidgetRef ref,
  }) {
    return GestureDetector(
      onTap: () async {
        // Heavy haptic feedback
        HapticFeedback.heavyImpact();

        // Add the meal
        await _addMealWithPortion(
          context: context,
          foodModel: foodModel,
          multiplier: multiplier,
          ref: ref,
        );

        // Close both dialogs
        if (context.mounted) {
          Navigator.of(context).pop(); // Close portion overlay
          Navigator.of(context).pop(); // Close main modal
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primary, width: 1.5),
          borderRadius: BorderRadius.circular(4),
          color: AppTheme.primary.withValues(alpha: 0.1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Add the meal with calculated macros based on portion multiplier
  Future<void> _addMealWithPortion({
    required BuildContext context,
    required FoodModel foodModel,
    required double multiplier,
    required WidgetRef ref,
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

      // Calculate macros with multiplier (4-node structure)
      final calories = (foodModel.calories * multiplier).toInt();
      final protein = (foodModel.protein * multiplier).toInt();
      final carbs = (foodModel.netCarbs * multiplier).toInt();
      final fat = (foodModel.fat * multiplier).toInt();

      // Register the meal
      final success = await ref.read(mealControllerProvider.notifier).registerMeal(
            name: foodModel.name,
            type: mealType,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
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

      // Record first meal transition if applicable
      if (mealNum == 1) {
        await ref.read(transitionProvider.notifier).recordFirstMeal(
              foodModel.name,
              DateTime.now(),
            );
      }

      // Invalidate biometric provider to update IMR
      ref.invalidate(biometricResultProvider);

      // Disable modal trigger
      ref.read(mealModalTriggerProvider.notifier).state = false;

      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${foodModel.name} añadido a Comida $mealNum'),
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
