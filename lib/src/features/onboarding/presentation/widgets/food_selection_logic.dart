import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../nutrition/domain/entities/food_model.dart';
import '../../../nutrition/presentation/widgets/elena_food_search_field.dart';

/// Proveedor para gestionar lista local de alimentos seleccionados
final selectedFoodsProvider = StateProvider<List<FoodModel>>((ref) => []);

/// Widget de selección de alimentos con búsqueda y chips
class FoodSelectionLogic extends ConsumerWidget {
  final String title;
  final String hintText;
  final VoidCallback? onRemove;

  const FoodSelectionLogic({
    super.key,
    this.title = 'SELECCIONA ALIMENTOS',
    this.hintText = 'Ej: Pollo, Arroz, Manzana...',
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFoods = ref.watch(selectedFoodsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label con tema BlueprintGrid
        Text(
          title,
          style: GoogleFonts.publicSans(
            color: AppTheme.primary, // Neon Orange
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Campo de búsqueda
        ElenaFoodSearchField(
          onFoodSelected: (FoodModel food) {
            if (!selectedFoods.any((f) => f.id == food.id)) {
              ref.read(selectedFoodsProvider.notifier).state = [
                ...selectedFoods,
                food,
              ];
            }
          },
          onManuallyAddFood: () {},
          label: '',
          hintText: hintText,
        ),
        const SizedBox(height: 16),

        // Wrap de FilterChips con alimentos seleccionados
        if (selectedFoods.isEmpty)
          Text(
            'Selecciona al menos uno...',
            style: GoogleFonts.publicSans(
              color: Colors.white38,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedFoods.map((food) {
              return FilterChip(
                label: Text(food.name),
                onSelected: (_) {},
                onDeleted: () {
                  ref.read(selectedFoodsProvider.notifier).state =
                      selectedFoods.where((f) => f.id != food.id).toList();
                  onRemove?.call();
                },
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                deleteIcon: const Icon(Icons.close, size: 14),
                deleteIconColor: AppTheme.primary,
                labelStyle: GoogleFonts.publicSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                side: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
