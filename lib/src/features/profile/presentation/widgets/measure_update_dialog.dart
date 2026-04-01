import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/user_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import '../../../../domain/logic/elena_brain.dart';

class MeasureUpdateDialog extends ConsumerStatefulWidget {
  final UserModel user;
  const MeasureUpdateDialog({super.key, required this.user});

  static void show(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MeasureUpdateDialog(user: user),
    );
  }

  @override
  ConsumerState<MeasureUpdateDialog> createState() =>
      _MeasureUpdateDialogState();
}

class _MeasureUpdateDialogState extends ConsumerState<MeasureUpdateDialog> {
  late TextEditingController _cintura;
  late TextEditingController _cadera;
  late TextEditingController _cuello;
  late TextEditingController _brazo;
  late TextEditingController _muslo;
  late TextEditingController _peso;

  @override
  void initState() {
    super.initState();
    _cintura = TextEditingController(
        text: widget.user.waistCircumferenceCm?.toStringAsFixed(1) ?? '80.0');
    _cadera = TextEditingController(
        text: widget.user.hipCircumferenceCm?.toStringAsFixed(1) ?? '100.0');
    _cuello = TextEditingController(
        text: widget.user.neckCircumferenceCm?.toStringAsFixed(1) ?? '35.0');
    _brazo = TextEditingController(text: '0.0');
    _muslo = TextEditingController(text: '0.0');
    _peso = TextEditingController(
        text: widget.user.currentWeightKg.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _cintura.dispose();
    _cadera.dispose();
    _cuello.dispose();
    _brazo.dispose();
    _muslo.dispose();
    _peso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF020205),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'REGISTRO TELEMÉTRICO SEMANAL',
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFFF9D00),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildField('CUELLO (cm)', _cuello)),
                const SizedBox(width: 16),
                Expanded(child: _buildField('CINTURA (cm)', _cintura)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField('CADERA (cm)', _cadera)),
                const SizedBox(width: 16),
                Expanded(child: _buildField('BRAZO (cm)', _brazo)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField('MUSLO (cm)', _muslo)),
                const SizedBox(width: 16),
                Expanded(child: _buildField('PESO ACTUAL (kg)', _peso)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9D00),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: const BeveledRectangleBorder(),
                ),
                child: Text(
                  'RECALIBRAR BIOMETRÍA',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white12),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF9D00)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final double weight =
        double.tryParse(_peso.text) ?? widget.user.currentWeightKg;
    final double waist = double.tryParse(_cintura.text) ??
        widget.user.waistCircumferenceCm ??
        80.0;
    final double neck =
        double.tryParse(_cuello.text) ?? widget.user.neckCircumferenceCm ?? 35.0;
    final double? hip = double.tryParse(_cadera.text) ??
        widget.user.hipCircumferenceCm;

    final double? fat = ElenaBrain.calculateFatPercentage(
      heightCm: widget.user.heightCm,
      waistCm: waist,
      neckCm: neck,
      hipCm: hip,
      isMale: widget.user.gender == Gender.male,
    );

    final double? muscle = ElenaBrain.calculateMuscleMass(fatPercentage: fat);

    final Map<String, double> metrics = {
      'cintura': waist,
      'cadera': hip ?? (waist * 1.1), // Fallback sensible
      'cuello': neck,
      'brazo': double.tryParse(_brazo.text) ?? 0,
      'muslo': double.tryParse(_muslo.text) ?? 0,
      'peso': weight,
      'grasa': fat ?? 24.5,
      'musculo': muscle ?? 36.2,
    };

    try {
      await ref
          .read(userRepositoryProvider)
          .saveBodyLog(widget.user.uid, metrics);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }
}

