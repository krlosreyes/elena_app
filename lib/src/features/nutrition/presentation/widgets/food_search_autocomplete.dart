import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/food_provider.dart';
import '../../domain/entities/food_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOOD SEARCH AUTOCOMPLETE — TypeAhead with Firestore Integration
// ─────────────────────────────────────────────────────────────────────────────

class FoodSearchAutocomplete extends ConsumerStatefulWidget {
  final Function(FoodModel) onFoodSelected;
  final TextEditingController? controller;
  final String? hintText;

  const FoodSearchAutocomplete({
    super.key,
    required this.onFoodSelected,
    this.controller,
    this.hintText,
  });

  @override
  ConsumerState<FoodSearchAutocomplete> createState() =>
      _FoodSearchAutocompleteState();
}

class _FoodSearchAutocompleteState
    extends ConsumerState<FoodSearchAutocomplete> {
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

  /// Handle search input changes
  void _onSearchChanged() {
    final query = _controller.text.trim();

    if (query.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _suggestions = []);
      return;
    }

    // Trigger search
    _performSearch(query);
  }

  /// Perform food search
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Watch the search provider (will query Firestore)
      final result = await ref.read(searchFoodProvider(query).future);

      if (result != null) {
        // Single result found
        setState(() {
          _suggestions = [result];
          _isLoading = false;
        });
      } else {
        // No exact match, get suggestions by category
        // For now, we'll search by category (e.g., 'protein')
        final proteinsResult =
            await ref.read(foodsByCategoryProvider('protein').future);
        final vegetablesResult =
            await ref.read(foodsByCategoryProvider('vegetable').future);
        final carbsResult =
            await ref.read(foodsByCategoryProvider('carb').future);

        // Filter suggestions by query match
        final suggestions = <FoodModel>[
          ...proteinsResult,
          ...vegetablesResult,
          ...carbsResult,
        ]
            .where(
                (food) => food.name.toLowerCase().contains(query.toLowerCase()))
            .take(5)
            .toList();

        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }

      // Show overlay with suggestions
      _showSuggestionsOverlay();
    } catch (e) {
      debugPrint('❌ Error searching foods: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Show suggestions overlay
  void _showSuggestionsOverlay() {
    if (_suggestions.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }

    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final food = _suggestions[index];
                  return _FoodSuggestionTile(
                    food: food,
                    onTap: () {
                      widget.onFoodSelected(food);
                      _controller.text = food.name;
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
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
          hintText: widget.hintText ?? 'Busca un alimento...',
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
// FOOD SUGGESTION TILE — Individual Suggestion Item
// ─────────────────────────────────────────────────────────────────────────────

class _FoodSuggestionTile extends StatelessWidget {
  final FoodModel food;
  final VoidCallback onTap;

  const _FoodSuggestionTile({
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final macros = food.calculateMacros(100); // Show per 100g

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food name with category badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      food.name,
                      style: GoogleFonts.publicSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Display IMR Score badge from Sovereign Master DB
                  if (food.imrScore >= 8)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '✓ Verificado',
                        style: GoogleFonts.publicSans(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // Macros per 100g
              Text(
                'P: ${macros.protein.toStringAsFixed(1)}g | F: ${macros.fat.toStringAsFixed(1)}g | C: ${macros.carbs.toStringAsFixed(1)}g | ${macros.calories.toStringAsFixed(0)}kcal',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),

              // Category badge
              if (food.category.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Chip(
                    label: Text(
                      food.category,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.grey[800],
                    labelStyle: const TextStyle(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
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
