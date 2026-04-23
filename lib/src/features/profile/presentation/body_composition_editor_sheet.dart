/// SPEC-25: Editor de Composición Corporal
/// BottomSheet para verificar y corregir datos de composición corporal

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/profile/domain/body_composition_validator.dart';
import 'package:elena_app/src/features/profile/domain/body_fat_calculator.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class BodyCompositionEditorSheet extends ConsumerStatefulWidget {
  const BodyCompositionEditorSheet({
    super.key,
    required this.currentWeight,
    required this.currentBodyFat,
    required this.currentWaist,
    required this.currentNeck,
    required this.height,
  });

  final double currentWeight;
  final double? currentBodyFat;  // Nullable — puede ser null en nuevos usuarios
  final double? currentWaist;
  final double? currentNeck;
  final double height;

  @override
  ConsumerState<BodyCompositionEditorSheet> createState() =>
      _BodyCompositionEditorSheetState();
}

class _BodyCompositionEditorSheetState
    extends ConsumerState<BodyCompositionEditorSheet> {
  late TextEditingController _weightCtrl;
  late TextEditingController _waistCtrl;
  late TextEditingController _neckCtrl;

  bool _isSaving = false;
  String? _errorMessage;
  double? _calculatedBodyFat; // Nullable — se calcula cuando hay medidas

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.currentWeight.toString());
    _waistCtrl = TextEditingController(
        text: (widget.currentWaist ?? '').toString().replaceAll('null', ''));
    _neckCtrl = TextEditingController(
        text: (widget.currentNeck ?? '').toString().replaceAll('null', ''));
    // Inicializar con el valor actual — null para nuevos usuarios sin medidas
    _calculatedBodyFat = widget.currentBodyFat;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _waistCtrl.dispose();
    _neckCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _errorMessage = null);

    // Parsear valores
    final weight = double.tryParse(_weightCtrl.text);
    final waist = _waistCtrl.text.isEmpty ? null : double.tryParse(_waistCtrl.text);
    final neck = _neckCtrl.text.isEmpty ? null : double.tryParse(_neckCtrl.text);

    if (weight == null) {
      setState(() => _errorMessage = 'Peso es requerido');
      return;
    }

    // Calcular % de grasa automáticamente (nunca es ingresado por el usuario)
    if (waist != null && neck != null) {
      final isMale = ref.read(currentUserStreamProvider).value?.gender == Gender.male;
      final calculatedBodyFat = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: waist,
        neckCm: neck,
        heightCm: widget.height,
        isMale: isMale,
      );
      setState(() => _calculatedBodyFat = calculatedBodyFat);
    } else {
      // Si no hay medidas de cintura/cuello, usar el valor anterior o null
      // No cambiar _calculatedBodyFat si no tenemos nuevas medidas
    }

    // Validar datos — bodyFatPercentage puede ser null para nuevos usuarios
    final validation = BodyCompositionValidator.validate(
      weight: weight,
      height: widget.height,
      bodyFatPercentage: _calculatedBodyFat ?? 0.0, // Usar 0.0 como fallback para validación
      waistCircumference: waist,
      neckCircumference: neck,
    );

    if (!validation.isValid) {
      setState(() => _errorMessage = '• ${validation.errorMessage}');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserStreamProvider).value;
      if (user == null) {
        throw Exception('Usuario no encontrado');
      }

      // Detectar cambios significativos
      final significantWeightChange = BodyCompositionValidator.isSignificantChange(
        oldValue: widget.currentWeight,
        newValue: weight,
        threshold: 0.10,
      );
      final significantFatChange = _calculatedBodyFat != null && widget.currentBodyFat != null
          ? BodyCompositionValidator.isSignificantChange(
              oldValue: widget.currentBodyFat!,
              newValue: _calculatedBodyFat!,
              threshold: 0.10,
            )
          : false;

      // Guardar cambios
      final updatedUser = user.copyWith(
        currentWeightKg: weight,
        waistCircumferenceCm: waist,
        neckCircumferenceCm: neck,
        isMeasurementEstimated: false, // Ahora son datos reales
      );

      await ref.read(userRepositoryProvider).saveUser(updatedUser);

      if (mounted) {
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✓ Composición corporal actualizada',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (significantWeightChange || significantFatChange) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Cambios detectados en tu composición corporal. '
                    'Tu IMR se ha recalculado.',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                  ),
                ],
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green.withOpacity(0.2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              const Text(
                'EDITAR COMPOSICIÓN CORPORAL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Actualiza tus medidas para un cálculo de IMR más preciso.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),

              // ── Campos ─────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Peso (kg)',
                      controller: _weightCtrl,
                      hint: 'ej: 75.5',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDisplayField(
                      label: '% Grasa (calculado)',
                      value: _calculatedBodyFat != null
                          ? '${_calculatedBodyFat!.toStringAsFixed(1)}%'
                          : '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Cintura (cm)',
                      controller: _waistCtrl,
                      hint: 'ej: 82',
                      optional: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Cuello (cm)',
                      controller: _neckCtrl,
                      hint: 'ej: 38',
                      optional: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Validación visual ───────────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.withOpacity(0.85),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Nota informativa ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.blueAccent, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '% Grasa se calcula automáticamente usando fórmula US Navy '
                        'basada en tus medidas de cintura y cuello. Proporciona estas '
                        'medidas para mayor precisión.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueAccent.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Botones ─────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9B60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          optional ? '$label (opcional)' : label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: !_isSaving,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 12,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2D9B60)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  /// Widget para mostrar valor calculado de solo lectura (SPEC-25)
  Widget _buildDisplayField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2D9B60).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2D9B60).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D9B60),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF2D9B60).withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
