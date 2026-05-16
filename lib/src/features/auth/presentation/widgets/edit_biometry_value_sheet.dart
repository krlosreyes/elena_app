// SPEC-88: bottom sheet reutilizable para edición rápida de un valor
// biométrico (peso, cintura, cuello, %grasa). Sin lógica de dominio —
// solo captura el nuevo valor, valida que esté dentro de un rango UI,
// y dispara un callback que el llamador implementa.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class EditBiometryValueSheet extends StatefulWidget {
  final String title;
  final String fieldLabel;
  final String unit;
  final double initialValue;
  final double minValue;
  final double maxValue;
  final int decimalPlaces;
  final ValueChanged<double> onSave;

  const EditBiometryValueSheet({
    super.key,
    required this.title,
    required this.fieldLabel,
    required this.unit,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.onSave,
    this.decimalPlaces = 1,
  });

  /// Helper estático que muestra el sheet y resuelve con el valor
  /// guardado (o null si el usuario canceló).
  static Future<double?> show(
    BuildContext context, {
    required String title,
    required String fieldLabel,
    required String unit,
    required double initialValue,
    required double minValue,
    required double maxValue,
    int decimalPlaces = 1,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: EditBiometryValueSheet(
          title: title,
          fieldLabel: fieldLabel,
          unit: unit,
          initialValue: initialValue,
          minValue: minValue,
          maxValue: maxValue,
          decimalPlaces: decimalPlaces,
          onSave: (value) => Navigator.of(ctx).pop(value),
        ),
      ),
    );
  }

  @override
  State<EditBiometryValueSheet> createState() => _EditBiometryValueSheetState();
}

class _EditBiometryValueSheetState extends State<EditBiometryValueSheet> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(widget.decimalPlaces),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      setState(() => _errorText = 'Ingresa un número válido');
      return;
    }
    if (parsed < widget.minValue || parsed > widget.maxValue) {
      setState(() => _errorText =
          'Debe estar entre ${widget.minValue.toStringAsFixed(0)} y '
              '${widget.maxValue.toStringAsFixed(0)} ${widget.unit}');
      return;
    }
    widget.onSave(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle visual.
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.fieldLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*[\.,]?\d*'),
              ),
            ],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.backgroundDark,
              suffixText: widget.unit,
              suffixStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              errorText: _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF10B981),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rango válido: ${widget.minValue.toStringAsFixed(0)} – '
            '${widget.maxValue.toStringAsFixed(0)} ${widget.unit}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.metabolicGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'GUARDAR',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
