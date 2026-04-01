import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/domain/entities/food_model.dart';

class ElenaDropdownMenu extends StatelessWidget {
  final String title;
  final String emoji;
  final List<FoodModel> foods;
  final List<String> selectedIds;
  final Function(FoodModel) onFoodSelected;

  const ElenaDropdownMenu({
    super.key,
    required this.title,
    required this.emoji,
    required this.foods,
    required this.selectedIds,
    required this.onFoodSelected,
  });

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ElenaDropdownOverlay(
        title: title,
        emoji: emoji,
        foods: foods,
        selectedIds: selectedIds,
        onFoodSelected: onFoodSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE0E0E0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selectedIds.length} seleccionado${selectedIds.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.unfold_more,
              color: Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ElenaDropdownOverlay extends StatefulWidget {
  final String title;
  final String emoji;
  final List<FoodModel> foods;
  final List<String> selectedIds;
  final Function(FoodModel) onFoodSelected;

  const _ElenaDropdownOverlay({
    required this.title,
    required this.emoji,
    required this.foods,
    required this.selectedIds,
    required this.onFoodSelected,
  });

  @override
  State<_ElenaDropdownOverlay> createState() => _ElenaDropdownOverlayState();
}

class _ElenaDropdownOverlayState extends State<_ElenaDropdownOverlay> {
  late List<FoodModel> _filteredFoods;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredFoods = widget.foods;
  }

  void _filter(String query) {
    setState(() {
      _filteredFoods = widget.foods
          .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF131313),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filter,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Buscar...',
                    hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
                    icon: const Icon(Icons.search, color: Colors.white24, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            
            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _filteredFoods.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1, indent: 24, endIndent: 24),
                itemBuilder: (context, index) {
                  final food = _filteredFoods[index];
                  final isSelected = widget.selectedIds.contains(food.id);
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_menu,
                          color: Colors.white38,
                          size: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      food.name,
                      style: GoogleFonts.inter(
                        color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected 
                      ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                      : const Icon(Icons.add_circle_outline, color: Colors.white10, size: 20),
                    onTap: () {
                      widget.onFoodSelected(food);
                      setState(() {}); // Refresh local state for trailing icon
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
