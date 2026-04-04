import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/food_provider.dart';
import '../../domain/entities/food_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ELENA FOOD SEARCH FIELD — Universal Food Search Experience
// ─────────────────────────────────────────────────────────────────────────────
//
// This widget provides a consistent food search experience across:
// - OnboardingFoodPreferences (building food list)
// - MealRegistrationModal (adding to meal)
//
// Features:
// • Verified badge (neon green checkmark) for verified foods
// • Manual add option ("No se encuentra el alimento? Agregar manualmente")
// • BlueprintGrid styled overlay background
// • Callback-based architecture for flexibility
// • Automatic macro calculation based on weight

class ElenaFoodSearchField extends ConsumerWidget {
  /// Called when user selects a food from the autocomplete list
  final Function(FoodModel food) onFoodSelected;

  /// Called when user taps "Agregar manualmente" to add custom food
  final Function()? onManuallyAddFood;

  /// Hint text for the search field
  final String hintText;

  /// Label for the field
  final String? label;

  /// Optional controller for external management
  final TextEditingController? controller;

  const ElenaFoodSearchField({
    super.key,
    required this.onFoodSelected,
    this.onManuallyAddFood,
    this.hintText = 'Busca tu alimento (ej: Pollo, Arroz, Manzana)',
    this.label,
    this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label (optional)
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label!,
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),

        // Enhanced FoodSearchAutocomplete with custom overlay
        _EnhancedFoodSearchAutocomplete(
          onFoodSelected: onFoodSelected,
          onManuallyAddFood: onManuallyAddFood,
          hintText: hintText,
          controller: controller,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal: Enhanced Food Search with Custom Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _EnhancedFoodSearchAutocomplete extends ConsumerStatefulWidget {
  final Function(FoodModel food) onFoodSelected;
  final Function()? onManuallyAddFood;
  final String hintText;
  final TextEditingController? controller;

  const _EnhancedFoodSearchAutocomplete({
    required this.onFoodSelected,
    required this.onManuallyAddFood,
    required this.hintText,
    required this.controller,
  });

  @override
  ConsumerState<_EnhancedFoodSearchAutocomplete> createState() =>
      _EnhancedFoodSearchAutocompleteState();
}

class _EnhancedFoodSearchAutocompleteState
    extends ConsumerState<_EnhancedFoodSearchAutocomplete> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<FoodModel> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _controller.text.trim();

    if (query.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _suggestions = []);
      return;
    }

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Watch the search provider (will query Firestore)
      final result = await ref.read(searchFoodProvider(query).future);

      if (result != null) {
        setState(() {
          _suggestions = [result];
          _isLoading = false;
        });
      } else {
        // No exact match, get suggestions by category
        final proteinsResult =
            await ref.read(foodsByCategoryProvider('protein').future);
        final vegetablesResult =
            await ref.read(foodsByCategoryProvider('vegetable').future);
        final carbsResult =
            await ref.read(foodsByCategoryProvider('carb').future);

        final suggestions = <FoodModel>[
          ...proteinsResult,
          ...vegetablesResult,
          ...carbsResult,
        ]
            .where(
                (food) => food.name.toLowerCase().contains(query.toLowerCase()))
            .take(8)
            .toList();

        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }

      _showEnhancedOverlay();
    } catch (e) {
      debugPrint('❌ Error searching foods: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showEnhancedOverlay() {
    if (_suggestions.isEmpty && !_isLoading) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }

    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(maxHeight: 340),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Loading state
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                          ),
                        ),
                      ),

                    // Food suggestions with verified badges
                    ..._suggestions.map((food) => _buildFoodTile(food)),

                    // Divider before manual add option
                    if (_suggestions.isNotEmpty)
                      Divider(
                        height: 1,
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),

                    // Manual add option
                    if (widget.onManuallyAddFood != null) _buildManualAddTile(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildFoodTile(FoodModel food) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onFoodSelected(food);
          _overlayEntry?.remove();
          _overlayEntry = null;
          _controller.clear();
          _focusNode.unfocus();
          setState(() => _suggestions = []);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Food name with verified badge and IMR score
              Row(
                children: [
                  Expanded(
                    child: Text(
                      food.name,
                      style: GoogleFonts.publicSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // IMR Score badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getImrScoreColor(food.imrScore.round()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'IMR ${food.imrScore}/10',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Nutritional info per 100g (4-node structure)
              Text(
                '${food.protein.toStringAsFixed(1)}g P • ${food.fat.toStringAsFixed(1)}g F • ${food.netCarbs.toStringAsFixed(1)}g C • ${food.calories.toStringAsFixed(0)} kcal',
                style: GoogleFonts.publicSans(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Sovereign Master DB Tip (from app_integration node)
              Text(
                '💡 ${food.tip}',
                style: GoogleFonts.publicSans(
                  color: AppTheme.primary.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to color-code IMR scores
  Color _getImrScoreColor(int score) {
    if (score >= 9) return const Color(0xFF39FF14); // Neon green
    if (score >= 7) return const Color(0xFFFFD700); // Gold
    if (score >= 5) return const Color(0xFFFFA500); // Orange
    return const Color(0xFFFF6B6B); // Red
  }

  Widget _buildManualAddTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onManuallyAddFood,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '❓ No se encuentra el alimento? Agregar manualmente',
                  style: GoogleFonts.publicSans(
                    color: AppTheme.primary.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: GoogleFonts.publicSans(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          hintText: widget.hintText,
          hintStyle: GoogleFonts.publicSans(color: Colors.white38),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          suffixIcon: _isLoading
              ? const SizedBox(
                  width: 20,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper class for macro calculation display
// ─────────────────────────────────────────────────────────────────────────────

class FoodMacroDisplay extends StatelessWidget {
  final FoodModel food;
  final double weightGrams;
  final bool showTitle;

  const FoodMacroDisplay({
    super.key,
    required this.food,
    required this.weightGrams,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final macros = food.calculateMacros(weightGrams);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '${food.name} (${weightGrams}g)',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMacroColumn(
              label: 'Proteína',
              value: macros.protein.toStringAsFixed(1),
              color: Colors.red,
            ),
            _buildMacroColumn(
              label: 'Grasas',
              value: macros.fat.toStringAsFixed(1),
              color: Colors.yellow,
            ),
            _buildMacroColumn(
              label: 'Carbohidratos',
              value: macros.carbs.toStringAsFixed(1),
              color: Colors.blue,
            ),
            _buildMacroColumn(
              label: 'Calorías',
              value: macros.kcal.toStringAsFixed(0),
              color: AppTheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.publicSans(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
