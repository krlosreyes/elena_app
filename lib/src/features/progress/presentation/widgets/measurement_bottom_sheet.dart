import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../profile/domain/user_model.dart';
import '../../../progress/domain/measurement_log.dart';
import '../../../coaching/data/coaching_service.dart';
import '../../data/progress_service.dart';

class MeasurementBottomSheet extends ConsumerStatefulWidget {
  final UserModel user;
  final double? initialWeight;
  final double? initialWaist;
  final double? initialNeck;
  final double? initialHip;
  final DateTime? initialDate;
  final MeasurementLog? existingLog;

  const MeasurementBottomSheet({
    super.key,
    required this.user,
    this.initialWeight,
    this.initialWaist,
    this.initialNeck,
    this.initialHip,
    this.initialDate,
    this.existingLog,
  });

  @override
  ConsumerState<MeasurementBottomSheet> createState() => _MeasurementBottomSheetState();
}

class _MeasurementBottomSheetState extends ConsumerState<MeasurementBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _weightController;
  late TextEditingController _waistController;
  late TextEditingController _neckController;
  late TextEditingController _hipController;
  
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.existingLog?.weight.toString() ?? widget.initialWeight?.toString() ?? widget.user.currentWeightKg?.toString() ?? '');
    _waistController = TextEditingController(text: widget.existingLog?.waistCircumference?.toString() ?? widget.initialWaist?.toString() ?? widget.user.waistCircumferenceCm?.toString() ?? '');
    _neckController = TextEditingController(text: widget.existingLog?.neckCircumference?.toString() ?? widget.initialNeck?.toString() ?? widget.user.neckCircumferenceCm?.toString() ?? '');
    _hipController = TextEditingController(text: widget.existingLog?.hipCircumference?.toString() ?? widget.initialHip?.toString() ?? widget.user.hipCircumferenceCm?.toString() ?? '');
    _selectedDate = widget.existingLog?.date ?? widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _neckController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final weight = double.parse(_weightController.text.replaceAll(',', '.'));
      final waist = double.tryParse(_waistController.text.replaceAll(',', '.'));
      final neck = double.tryParse(_neckController.text.replaceAll(',', '.'));
      final hip = double.tryParse(_hipController.text.replaceAll(',', '.'));

      // 1. Calculate Body Fat & Lean Mass (Navy Method)
      double? calculatedBodyFat;
      double? calculatedLeanMass;
      
      if (waist != null && neck != null) {
        calculatedBodyFat = MeasurementLog.calculateBodyFat(
          heightCm: widget.user.heightCm,
          waistCm: waist,
          neckCm: neck,
          hipCm: hip,
          isMale: widget.user.gender == Gender.male,
        );
        
        if (calculatedBodyFat != null) {
          calculatedLeanMass = 100.0 - calculatedBodyFat;
        }
      }

      // 2. Estimate Visceral Fat
      double? visceralFat;
      if (waist != null) {
        visceralFat = MeasurementLog.estimateVisceralFat(
          waistCm: waist,
          isMale: widget.user.gender == Gender.male,
        );
      }

      // 3. Determine Log Date
      // Preserve time if today, otherwise noon
      DateTime logDate = _selectedDate;
      if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
        logDate = DateTime.now();
      } else {
        logDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 12, 0);
      }

      // 4. Create or Update Log Object
      MeasurementLog logToSave;

      if (widget.existingLog != null) {
        // UPDATE existing log
        logToSave = widget.existingLog!.copyWith(
          date: logDate,
          weight: weight,
          waistCircumference: waist,
          neckCircumference: neck,
          hipCircumference: hip,
          bodyFatPercentage: calculatedBodyFat,
          muscleMassPercentage: calculatedLeanMass,
          visceralFat: visceralFat,
        );
        
        // Update in Firestore
        await ref.read(progressServiceProvider).updateMeasurement(logToSave);
      } else {
        // CREATE new log
        final tempLog = MeasurementLog(
          id: '',
          date: logDate,
          weight: weight,
          waistCircumference: waist,
          neckCircumference: neck,
          hipCircumference: hip,
          bodyFatPercentage: calculatedBodyFat,
          muscleMassPercentage: calculatedLeanMass,
          visceralFat: visceralFat,
        );
        
        // Save to Firestore (Log History)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .collection('measurements')
            .add(tempLog.toJson());
            
        // Use tempLog for profile update check
        logToSave = tempLog; 
      }

      // 6. Update User Profile if the log is recent (same day or after current data)
      // For simplicity in this refactor, we ALWAYS update the profile 'current' stats 
      // when the user explicitly saves a form, UNLESS it's a very old historical entry.
      // But typically "Editing Profile" implies updating current stats.
      // "Adding Progress" usually implies updating current stats too.
      // Safe bet: If date is today or future (unlikely), update. If past, maybe ask? 
      // For now, let's update if it is within the last 24 hours OR if it's the newest log.
      // A simple heuristic: Update profile fields if selectedDate is today.
      
      if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
          await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({
              'currentWeightKg': weight,
              if (waist != null) 'waistCircumferenceCm': waist,
              if (neck != null) 'neckCircumferenceCm': neck,
              if (hip != null) 'hipCircumferenceCm': hip,
            });
      }

      // 7. Generate Coaching Plan
      // Use logToSave w/ correct data for service
      // Note: If we just created it, it might not have ID here unless we fetch it or pass it. 
      // For add new, we ignored ID above. For CoahingService, ID matters less than data usually, 
      // but let's be safe.
      final logForService = logToSave; // ID might be empty if new, but data is fresh
      
      // Only generate plan if it's a "live" update (today)
      if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
          // We need to await this potentially? Or let it run in background?
          // It's better to await to show confirmation.
          await ref.read(coachingProvider).generatePlanFromMeasurement(logForService, widget.user);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro guardado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existingLog != null ? 'Editar Registro' : 'Registrar Medidas',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Grasa y Masa Magra se calcularán automáticamente.',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Date Picker (Shared logic)
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha del registro',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('d MMMM yyyy', 'es').format(_selectedDate),
                  style: GoogleFonts.outfit(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _waistController,
                    decoration: const InputDecoration(labelText: 'Cintura (cm)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                     validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _neckController,
                    decoration: const InputDecoration(labelText: 'Cuello (cm)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                     validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _hipController,
                    decoration: const InputDecoration(labelText: 'Cadera (cm) (Opcional)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
