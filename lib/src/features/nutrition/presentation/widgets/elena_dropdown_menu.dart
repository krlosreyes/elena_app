import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// 🎨 ELENA DROPDOWN MENU - Minimalist & Premium Selection Interface
/// 
/// Replaces neon-heavy lists with a clean, high-end overlay.
/// Features: Backdrop blur, monochromatic icons, and subtle interactive states.

class ElenaDropdownItem {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  ElenaDropdownItem({
    required this.title,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });
}

class ElenaDropdownCategory {
  final String title;
  final List<ElenaDropdownItem> items;

  ElenaDropdownCategory({
    required this.title,
    required this.items,
  });
}

class ElenaDropdownMenu extends StatelessWidget {
  final List<ElenaDropdownCategory> categories;
  final String title;

  const ElenaDropdownMenu({
    super.key,
    required this.categories,
    required this.title,
  });

  /// Static helper to trigger the menu as a bottom sheet
  static Future<void> show({
    required BuildContext context,
    required List<ElenaDropdownCategory> categories,
    required String title,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => ElenaDropdownMenu(
        categories: categories,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewPadding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2.0,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Categories list scrollable
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: categories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    final isFirst = index == 0;

                    return _DropdownCategorySection(
                      category: category,
                      isFirst: isFirst,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownCategorySection extends StatelessWidget {
  final ElenaDropdownCategory category;
  final bool isFirst;

  const _DropdownCategorySection({
    required this.category,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst) const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            category.title.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.015),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.03),
              width: 1,
            ),
          ),
          child: Column(
            children: category.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == category.items.length - 1;

              return Column(
                children: [
                  _ElenaDropdownMenuItem(item: item),
                  if (!isLast)
                    Divider(
                      color: Colors.white.withValues(alpha: 0.04),
                      height: 1,
                      indent: 60,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ElenaDropdownMenuItem extends StatefulWidget {
  final ElenaDropdownItem item;

  const _ElenaDropdownMenuItem({required this.item});

  @override
  State<_ElenaDropdownMenuItem> createState() => _ElenaDropdownMenuItemState();
}

class _ElenaDropdownMenuItemState extends State<_ElenaDropdownMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.item.onTap,
        onHover: (value) => setState(() => _isHovered = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              // Leading Icon with muted background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.item.isSelected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 20,
                  color: widget.item.isSelected ? AppTheme.primary : Colors.white38,
                ),
              ),
              const SizedBox(width: 16),
              
              // Title
              Expanded(
                child: Text(
                  widget.item.title,
                  style: GoogleFonts.inter(
                    color: widget.item.isSelected ? Colors.white : const Color(0xFFE0E0E0),
                    fontSize: 14,
                    fontWeight: widget.item.isSelected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              
              // Selection indicator
              if (widget.item.isSelected || _isHovered)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.item.isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
