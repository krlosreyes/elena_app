import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../domain/logic/elena_brain.dart';
import '../../../../features/health/data/health_repository.dart';
import '../../data/user_repository.dart';

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
  late DateTime _selectedDate;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
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
            const SizedBox(height: 16),
            // ─── Date picker ───────────────────────────────────────
            Builder(
              builder: (localContext) => GestureDetector(
                onTap: () => _pickDate(localContext),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isToday
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFFFF9D00).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isToday
                          ? Colors.white12
                          : const Color(0xFFFF9D00).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _isToday
                            ? Colors.white38
                            : const Color(0xFFFF9D00),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isToday
                              ? 'HOY — ${DateFormat('d MMM yyyy', 'es').format(_selectedDate)}'
                              : DateFormat(
                                  'EEEE d MMM yyyy',
                                  'es',
                                ).format(_selectedDate).toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isToday
                                ? Colors.white54
                                : const Color(0xFFFF9D00),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: _isToday
                            ? Colors.white24
                            : const Color(0xFFFF9D00).withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isToday) ...[
              const SizedBox(height: 8),
              Text(
                '⏪ Registro retroactivo — solo se guardará en el historial',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: Colors.white30,
                ),
              ),
            ],

            const SizedBox(height: 20),
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

  Future<void> _pickDate([BuildContext? localContext]) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: localContext ?? context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
      locale: const Locale('es'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF9D00),
              onPrimary: Colors.black,
              surface: Color(0xFF121212),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0A0A0A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final double weight =
        double.tryParse(_peso.text) ?? widget.user.currentWeightKg;
    final double waist =
        double.tryParse(_cintura.text) ??
        widget.user.waistCircumferenceCm ??
        80.0;
    final double neck =
        double.tryParse(_cuello.text) ??
        widget.user.neckCircumferenceCm ??
        35.0;
    final double? hip =
        double.tryParse(_cadera.text) ?? widget.user.hipCircumferenceCm;

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
      'cadera': hip ?? (waist * 1.1),
      'cuello': neck,
      'brazo': double.tryParse(_brazo.text) ?? 0,
      'muslo': double.tryParse(_muslo.text) ?? 0,
      'peso': weight,
      'grasa': fat ?? 24.5,
      'musculo': muscle ?? 36.2,
    };

    try {
      // 1. Guardar en body_logs (con fecha seleccionada)
      //    Si es hoy → también actualiza el doc principal del usuario
      await ref
          .read(userRepositoryProvider)
          .saveBodyLog(
            widget.user.uid,
            metrics,
            date: _isToday ? null : _selectedDate,
          );

      // 2. Si es hoy, recalcular imrScore del día
      if (_isToday) {
        await ref
            .read(healthRepositoryProvider)
            .recalculateImrForToday(widget.user.uid);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }
}
