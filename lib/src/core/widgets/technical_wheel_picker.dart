import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_theme.dart';

/// 🛠️ DUAL-PRECISION TECHNICAL STEPPER (Ver 4.0 - Blueprint Aesthetic)
///
/// A high-authority numeric picker designed for health metrics.
/// Separates "Units" (Integers) from "Decimals" to allow faster and more
/// intuitive data entry. The +/- buttons act on the active part.
class TechnicalWheelPicker extends StatefulWidget {
  final String title;
  final double initialValue;
  final double min;
  final double max;
  final double step;
  final String unit;
  final Function(double) onValueSelected;

  const TechnicalWheelPicker({
    super.key,
    required this.title,
    required this.initialValue,
    required this.min,
    required this.max,
    this.step = 1.0,
    required this.unit,
    required this.onValueSelected,
  });

  @override
  State<TechnicalWheelPicker> createState() => _TechnicalWheelPickerState();
}

class _TechnicalWheelPickerState extends State<TechnicalWheelPicker> {
  late double _currentValue;
  late int _integerPart;
  late int _decimalPart;
  bool _isIntegerActive = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _integerPart = _currentValue.toInt();
    _decimalPart = ((_currentValue - _integerPart) * 10).round();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCurrentValue() {
    _currentValue = _integerPart + (_decimalPart / 10.0);
    _currentValue = _currentValue.clamp(widget.min, widget.max);
    // Sync components back if clamped
    _integerPart = _currentValue.toInt();
    _decimalPart = ((_currentValue - _integerPart) * 10).round();
  }

  void _increment() {
    setState(() {
      if (_isIntegerActive) {
        if (_integerPart < widget.max.toInt()) {
          _integerPart++;
        }
      } else {
        if (_decimalPart < 9) {
          _decimalPart++;
        } else {
          _decimalPart = 0;
          if (_integerPart < widget.max.toInt()) _integerPart++;
        }
      }
      _updateCurrentValue();
    });
    HapticFeedback.lightImpact();
  }

  void _decrement() {
    setState(() {
      if (_isIntegerActive) {
        if (_integerPart > widget.min.toInt()) {
          _integerPart--;
        }
      } else {
        if (_decimalPart > 0) {
          _decimalPart--;
        } else {
          _decimalPart = 9;
          if (_integerPart > widget.min.toInt()) _integerPart--;
        }
      }
      _updateCurrentValue();
    });
    HapticFeedback.lightImpact();
  }

  void _startContinuous(VoidCallback action) {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      action();
    });
  }

  void _stopContinuous() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDecimals = widget.step < 1.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
          decoration: const BoxDecoration(
            color: Color(0xFF030A09), // Deep Obsidian
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: Colors.black, blurRadius: 40, spreadRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white38, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Technical Hint
              Text(
                _isIntegerActive
                    ? 'CALIBRANDO UNIDADES'
                    : 'CALIBRANDO DECIMALES',
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.primary.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              // Main Multi-Stepper Control
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // DECREMENT
                    _buildStepperButton(Icons.remove, _decrement),

                    // DUAL VALUE DISPLAY
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // INTEGER PART
                        GestureDetector(
                          onTap: () => setState(() => _isIntegerActive = true),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.jetBrainsMono(
                              color: _isIntegerActive
                                  ? Colors.white
                                  : Colors.white24,
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -4,
                            ),
                            child: Text('$_integerPart'),
                          ),
                        ),

                        if (hasDecimals) ...[
                          // DECIMAL POINT
                          Text(
                            '.',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white24,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          // DECIMAL PART
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isIntegerActive = false),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.jetBrainsMono(
                                color: !_isIntegerActive
                                    ? Colors.white
                                    : Colors.white24,
                                fontSize: 72,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -4,
                              ),
                              child: Text('$_decimalPart'),
                            ),
                          ),
                        ],

                        const SizedBox(width: 8),
                        // UNIT
                        Text(
                          widget.unit.toLowerCase(),
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // INCREMENT
                    _buildStepperButton(Icons.add, _increment, isPrimary: true),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    widget.onValueSelected(_currentValue);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'FIJAR PARÁMETRO',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperButton(IconData icon, VoidCallback action,
      {bool isPrimary = false}) {
    return GestureDetector(
      onTapDown: (_) => action(),
      onLongPress: () => _startContinuous(action),
      onLongPressUp: _stopContinuous,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: isPrimary
                ? AppTheme.primary.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: isPrimary ? AppTheme.primary : Colors.white70,
          size: 36,
        ),
      ),
    );
  }
}
