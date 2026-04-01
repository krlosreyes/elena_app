import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/food_model.dart';
import 'elena_food_search_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PORTION ADJUSTMENT VIEW — Adjust Weight & See Macros in Real-Time
// ─────────────────────────────────────────────────────────────────────────────
//
// Used in MealRegistrationModal to allow users to:
// 1. View selected food details
// 2. Adjust portion size (grams or standard units)
// 3. See macros update in real-time
// 4. Confirm selection

class PortionAdjustmentView extends StatefulWidget {
  /// The food model being adjusted
  final FoodModel food;

  /// Initial weight in grams (default: 100g)
  final double initialWeightGrams;

  /// Called when user confirms the selection with adjusted weight
  final Function(FoodModel food, double weightGrams) onConfirm;

  /// Called when user wants to go back and change the food
  final VoidCallback? onBack;

  /// Custom title for the view
  final String? title;

  const PortionAdjustmentView({
    super.key,
    required this.food,
    required this.onConfirm,
    this.initialWeightGrams = 100,
    this.onBack,
    this.title,
  });

  @override
  State<PortionAdjustmentView> createState() => _PortionAdjustmentViewState();
}

class _PortionAdjustmentViewState extends State<PortionAdjustmentView> {
  late double _weightGrams;
  late final TextEditingController _weightController;
  late final FocusNode _weightFocusNode;

  // Standard units mapping (these could be customized per food)
  final Map<String, double> _standardUnits = {
    'Pequeña porción': 50,
    'Porción mediana': 100,
    'Porción grande': 150,
    '1 puño': 75,
    '1 taza': 240,
    '1 plato': 300,
  };

  @override
  void initState() {
    super.initState();
    _weightGrams = widget.initialWeightGrams;
    _weightController =
        TextEditingController(text: _weightGrams.toStringAsFixed(0));
    _weightFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  void _updateWeight(double value) {
    setState(() {
      _weightGrams = value.clamp(1, 1000);
      _weightController.text = _weightGrams.toStringAsFixed(0);
    });
  }

  void _handleWeightInput() {
    final value = double.tryParse(_weightController.text);
    if (value != null && value > 0) {
      _updateWeight(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final macroRatio = widget.food.macroRatio;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title ?? 'AJUSTAR PORCIÓN',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    if (widget.onBack != null)
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Icon(
                          Icons.close,
                          color: Colors.white54,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.food.name,
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Display IMR Score instead of isVerified flag
                if (widget.food.imrScore >= 8)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Alimento Verificado',
                          style: GoogleFonts.publicSans(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: AppTheme.primary.withValues(alpha: 0.2),
          ),

          // Weight Adjustment Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Manual weight input
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PESO EN GRAMOS',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Decrease button
                          GestureDetector(
                            onTap: () => _updateWeight(_weightGrams - 10),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white10,
                                ),
                              ),
                              child: Icon(
                                Icons.remove,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Weight input field
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              focusNode: _weightFocusNode,
                              keyboardType: TextInputType.number,
                              onSubmitted: (_) => _handleWeightInput(),
                              style: GoogleFonts.jetBrainsMono(
                                color: AppTheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.03),
                                hintText: '100',
                                hintStyle: GoogleFonts.jetBrainsMono(
                                  color: Colors.white30,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.white10,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.white10,
                                  ),
                                ),
                                suffixText: 'g',
                                suffixStyle: GoogleFonts.publicSans(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Increase button
                          GestureDetector(
                            onTap: () => _updateWeight(_weightGrams + 10),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white10,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Slider for weight adjustment
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O DESLIZA PARA AJUSTAR',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: _weightGrams,
                        min: 10,
                        max: 500,
                        divisions: 49,
                        activeColor: AppTheme.primary,
                        inactiveColor: Colors.white10,
                        onChanged: _updateWeight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Standard units (optional)
                if (_standardUnits.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIDADES ESTÁNDAR',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _standardUnits.entries.map((entry) {
                          final isActive =
                              (_weightGrams - entry.value).abs() < 5;
                          return GestureDetector(
                            onTap: () => _updateWeight(entry.value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.primary.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isActive
                                      ? AppTheme.primary
                                      : Colors.white10,
                                ),
                              ),
                              child: Text(
                                entry.key,
                                style: GoogleFonts.publicSans(
                                  color: isActive
                                      ? AppTheme.primary
                                      : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: AppTheme.primary.withValues(alpha: 0.2),
          ),

          // Macros Display
          Padding(
            padding: const EdgeInsets.all(20),
            child: FoodMacroDisplay(
              food: widget.food,
              weightGrams: _weightGrams,
              showTitle: false,
            ),
          ),

          // Macro Ratio Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PROPORCIÓN DE MACROS',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (macroRatio.proteinPercent * 100).toInt(),
                        child: Container(
                          height: 24,
                          color: Colors.red,
                          child: Center(
                            child: macroRatio.proteinPercent > 0.15
                                ? Text(
                                    '${macroRatio.proteinPercent.toStringAsFixed(0)}%',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (macroRatio.fatPercent * 100).toInt(),
                        child: Container(
                          height: 24,
                          color: Colors.yellow,
                          child: Center(
                            child: macroRatio.fatPercent > 0.15
                                ? Text(
                                    '${macroRatio.fatPercent.toStringAsFixed(0)}%',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (macroRatio.carbsPercent * 100).toInt(),
                        child: Container(
                          height: 24,
                          color: Colors.blue,
                          child: Center(
                            child: macroRatio.carbsPercent > 0.15
                                ? Text(
                                    '${macroRatio.carbsPercent.toStringAsFixed(0)}%',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Proteína (${macroRatio.proteinPercent.toStringAsFixed(0)}%)',
                      style: GoogleFonts.publicSans(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Grasas (${macroRatio.fatPercent.toStringAsFixed(0)}%)',
                      style: GoogleFonts.publicSans(
                        color: Colors.yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Carbs (${macroRatio.carbsPercent.toStringAsFixed(0)}%)',
                      style: GoogleFonts.publicSans(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Divider(
            height: 1,
            color: AppTheme.primary.withValues(alpha: 0.2),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(widget.food, _weightGrams);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  'CONFIRMAR PORCIÓN',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
