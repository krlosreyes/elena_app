import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../nutrition/domain/entities/food_model.dart';

/// PortionSelector - Simple dialog for selecting food portion size in grams
/// Provides a slider to set portion size with real-time updates to macro display
class PortionSelector extends StatefulWidget {
  final FoodModel food;
  final VoidCallback onConfirm;
  final Function(double)? onPortionChanged;

  const PortionSelector({
    super.key,
    required this.food,
    required this.onConfirm,
    this.onPortionChanged,
  });

  @override
  State<PortionSelector> createState() => _PortionSelectorState();
}

class _PortionSelectorState extends State<PortionSelector> {
  late double _portion;

  @override
  void initState() {
    super.initState();
    // Default portion: 100g (standard nutrition label)
    _portion = 100.0;
    widget.onPortionChanged?.call(_portion);
  }

  /// Calculate adjusted macros based on portion (4-node structure)
  Map<String, double> _getAdjustedMacros() {
    final factor = _portion / 100.0;
    return {
      'protein': widget.food.protein * factor,
      'fat': widget.food.fat * factor,
      'carbs': widget.food.netCarbs * factor,
      'calories': widget.food.calories * factor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final macros = _getAdjustedMacros();

    return Dialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const BeveledRectangleBorder(
        side: BorderSide(color: AppTheme.primary, width: 1),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'SELECCIONA PORCIÓN',
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Food name
              Text(
                widget.food.name,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Portion Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primary, width: 1),
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.primary.withValues(alpha: 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Porción: ${_portion.toStringAsFixed(0)}g',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Macro display
                    Text(
                      'P: ${macros['protein']!.toStringAsFixed(1)}g | F: ${macros['fat']!.toStringAsFixed(1)}g | C: ${macros['carbs']!.toStringAsFixed(1)}g | Cal: ${macros['calories']!.toStringAsFixed(0)}',
                      style: GoogleFonts.publicSans(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajusta la porción (50-500g)',
                    style: GoogleFonts.publicSans(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4.0,
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _portion,
                      min: 50,
                      max: 500,
                      divisions: 45, // 50-500 in 10g steps
                      onChanged: (value) {
                        setState(() {
                          _portion = value;
                        });
                        widget.onPortionChanged?.call(_portion);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick portion presets
              Text(
                'Atajos rápidos:',
                style: GoogleFonts.publicSans(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [50, 100, 150, 200, 250, 300].map((g) {
                  final isSelected = _portion == g.toDouble();
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _portion = g.toDouble();
                      });
                      widget.onPortionChanged?.call(_portion);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.white12,
                          width: isSelected ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.03),
                      ),
                      child: Text(
                        '${g}g',
                        style: GoogleFonts.publicSans(
                          color: isSelected ? AppTheme.primary : Colors.white70,
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCELAR',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _portion);
                      widget.onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      shape: const BeveledRectangleBorder(),
                    ),
                    child: Text(
                      'CONFIRMAR',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
