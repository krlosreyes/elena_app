import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/food_model.dart';

/// Custom Searchable Dropdown for Food Selection
/// Bio-Engine aesthetic: Black background, Neon Green borders (#00FF00), white text
class SearchableFoodDropdown extends StatefulWidget {
  final String title;
  final String emoji;
  final List<FoodModel> foods;
  final List<String> selectedIds;
  final Function(FoodModel) onFoodSelected;

  const SearchableFoodDropdown({
    super.key,
    required this.title,
    required this.emoji,
    required this.foods,
    required this.selectedIds,
    required this.onFoodSelected,
  });

  @override
  State<SearchableFoodDropdown> createState() => _SearchableFoodDropdownState();
}

class _SearchableFoodDropdownState extends State<SearchableFoodDropdown> {
  late final TextEditingController _searchController;
  bool _isDropdownOpen = false;
  List<FoodModel> _filteredFoods = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredFoods = widget.foods;
  }

  @override
  void didUpdateWidget(SearchableFoodDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foods != widget.foods) {
      _applyFilter(_searchController.text);
    }
  }

  void _applyFilter(String query) {
    if (query.isEmpty) {
      setState(() => _filteredFoods = widget.foods);
    } else {
      final lowerQuery = query.toLowerCase();
      setState(() {
        _filteredFoods = widget.foods
            .where(
              (food) =>
                  food.name.toLowerCase().contains(lowerQuery) ||
                  food.searchTags.any(
                    (tag) => tag.toLowerCase().contains(lowerQuery),
                  ),
            )
            .toList();
      });
    }
  }

  void _handleFoodSelection(FoodModel food) {
    widget.onFoodSelected(food);
    // Clear search after selection for better UX
    _searchController.clear();
    _applyFilter('');
    // Keep dropdown open to allow multiple selections
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Button
        GestureDetector(
          onTap: () => setState(() => _isDropdownOpen = !_isDropdownOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: _isDropdownOpen ? AppTheme.primary : Colors.white24,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(widget.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.robotoMono(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              '${widget.selectedIds.length} seleccionado${widget.selectedIds.length == 1 ? '' : 's'}',
                              style: GoogleFonts.publicSans(
                                color: Colors.white54,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isDropdownOpen ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Dropdown Content (Search + List)
        if (_isDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: AppTheme.primary, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.primary, width: 1),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                    onChanged: _applyFilter,
                    decoration: InputDecoration(
                      hintText: 'Buscar ${widget.title.toLowerCase()}...',
                      hintStyle: GoogleFonts.publicSans(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                       prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    cursorColor: AppTheme.primary,
                  ),
                ),

                // Food List
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: _filteredFoods.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No se encontraron alimentos',
                            style: GoogleFonts.publicSans(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filteredFoods.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.white12,
                            height: 1,
                            indent: 12,
                            endIndent: 12,
                          ),
                          itemBuilder: (context, index) {
                            final food = _filteredFoods[index];
                            final isSelected = widget.selectedIds.contains(
                              food.id,
                            );

                            return Material(
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              child: InkWell(
                                onTap: () => _handleFoodSelection(food),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: isSelected
                                        ? Border(
                                            left: BorderSide(
                                              color: AppTheme.primary,
                                              width: 3,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppTheme.primary,
                                          size: 14,
                                        )
                                      else
                                        const Icon(
                                          Icons.circle_outlined,
                                          color: Colors.white24,
                                          size: 14,
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              food.name,
                                              style: GoogleFonts.publicSans(
                                                color: isSelected
                                                    ? AppTheme.primary
                                                    : Colors.white,
                                                fontSize: 11,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            if (food.tip.isNotEmpty)
                                              Text(
                                                food.tip,
                                                style: GoogleFonts.publicSans(
                                                  color: Colors.white54,
                                                  fontSize: 9,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            else
                                              Text(
                                                '(Sin descripción)',
                                                style: GoogleFonts.publicSans(
                                                  color: Colors.white30,
                                                  fontSize: 9,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
