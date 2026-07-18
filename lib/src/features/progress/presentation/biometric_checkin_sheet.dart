// SPEC-15: Road Map de Avance Personal
// Bottom sheet para registrar un snapshot biométrico periódico.
// Campos: peso (obligatorio), %grasa (opcional), cintura (opcional), nota.
// Diseño consistente con IMRDetailSheet.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/core/engine/longitudinal_imr_provider.dart';
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/theme/app_icons.dart';
import 'package:elena_app/src/core/engine/weekly_imr_snapshot_service.dart';
import 'package:elena_app/src/features/progress/application/biometric_history_service.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/profile/domain/body_fat_calculator.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────

void showBiometricCheckInSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const BiometricCheckInSheet(),
  );
}

// ─── Widget principal ─────────────────────────────────────────────────────────

class BiometricCheckInSheet extends ConsumerStatefulWidget {
  const BiometricCheckInSheet({super.key});

  @override
  ConsumerState<BiometricCheckInSheet> createState() =>
      _BiometricCheckInSheetState();
}

class _BiometricCheckInSheetState extends ConsumerState<BiometricCheckInSheet> {
  final _weightCtrl = TextEditingController();
  final _bfCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-rellenar con los valores actuales del perfil
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user != null) {
      _weightCtrl.text = user.weight.toStringAsFixed(1);
      // SPEC-92: bodyFat nullable. Si no hay valor, dejar el campo
      // vacío para que el usuario tipee (o lo deje sin tocar si el
      // check-in es de peso/cintura solamente).
      _bfCtrl.text = user.bodyFatPercentage != null
          ? user.bodyFatPercentage!.toStringAsFixed(0)
          : '';
      if (user.waistCircumference != null) {
        _waistCtrl.text = user.waistCircumference!.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bfCtrl.dispose();
    _waistCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;

    // SPEC-52: snapshot del IMR central — sin recalcular con defaults locales.
    final imrResult = ref.read(imrProvider);

    final today = DateTime.now();
    final dateKey = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    final double? enteredWaist = _waistCtrl.text.isNotEmpty
        ? double.tryParse(_waistCtrl.text.replaceAll(',', '.'))
        : null;
    final double? manualBodyFat = _bfCtrl.text.isNotEmpty
        ? double.tryParse(_bfCtrl.text.replaceAll(',', '.'))
        : null;

    // FIX composición corporal (2026-06-10): el % de grasa se RECALCULA con
    // la cintura que el usuario acaba de ingresar (fórmula US Navy:
    // cintura + cuello + altura del perfil). Antes se guardaba el valor
    // manual pre-rellenado del perfil, así que la serie de Análisis no se
    // movía aunque cambiaran las medidas → se veía "hardcodeada". El intent
    // documentado es "el usuario NUNCA ingresa % grasa, siempre se calcula"
    // (BodyFatCalculator §1). Fallback al valor manual si no hay cuello/altura.
    double? bodyFat = manualBodyFat;
    final double? neck = user.neckCircumference;
    if (enteredWaist != null &&
        enteredWaist > 0 &&
        neck != null &&
        neck > 0 &&
        user.height > 0) {
      final computed = BodyFatCalculator.calculateBodyFatPercentage(
        waistCm: enteredWaist,
        neckCm: neck,
        heightCm: user.height,
        isMale: user.gender.toUpperCase() == 'M',
      );
      if (computed > 0) bodyFat = computed;
    }

    final checkIn = BiometricCheckIn(
      date: dateKey,
      userId: user.id,
      weight: double.parse(_weightCtrl.text.replaceAll(',', '.')),
      bodyFatPercentage: bodyFat,
      waistCircumference: enteredWaist,
      neckCircumference: neck,
      imrScore: imrResult.totalScore,
      notes: _noteCtrl.text.isNotEmpty ? _noteCtrl.text.trim() : null,
      createdAt: today,
    );

    // SPEC-143: el sheet pasa por el servicio canónico, que garantiza
    // (a) escritura atómica de `users/{uid}` + `biometric_history` vía
    // WriteBatch (se mantiene intacta — solo cambia CUÁNDO se espera el
    // ack, no la atomicidad del batch en sí), y (b) versionado con
    // `source: 'checkin_sheet'` para auditoría. El stream de
    // progressProvider sigue captando el cambio porque escucha el
    // snapshot de biometric_history.
    //
    // FB-03 (auditoría 2026-07-11): antes esta función hacía `await`
    // directo sobre updateFromCheckInSheet + recomputeAndPersist. Si el
    // dispositivo estaba offline, el batch.commit() interno nunca
    // resolvía y el sheet quedaba en `_isSaving = true` indefinidamente
    // (mismo bug raíz que motivó SPEC-206 en Hidratación). El SDK de
    // Firestore ya aplica la mutación a la caché local en cuanto se
    // llama a `batch.commit()`, sin esperar el ack del servidor — por
    // eso es seguro no bloquear la UI en ese ack: el listener de
    // biometric_history (ProgressNotifier) refleja el cambio al toque.
    final longitudinal = ref.read(longitudinalImrProvider);
    final historyService = ref.read(biometricHistoryServiceProvider);
    final snapshotService = ref.read(weeklyImrSnapshotServiceProvider);
    unawaited(
      historyService
          .updateFromCheckInSheet(currentUser: user, checkInData: checkIn)
          .then((_) {
        // SPEC-141 §RF-141-12.A: recompute forzado del IMR longitudinal
        // tras confirmar el check-in — encadenado para no crear una
        // condición de carrera con el snapshot de biometría.
        return snapshotService.recomputeAndPersist(
          userId: user.id,
          longitudinal: longitudinal,
          trigger: WeeklyImrTrigger.biometricCheckin,
        );
      }).catchError((Object e) {
        AppLogger.error('BiometricCheckInSheet._save falló', e);
      }),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medidas registradas ✓'),
          backgroundColor: Color(0xFF1ABC9C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.90,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1ABC9C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(AppIcons.cinturaEstatura,
                          size: 20, color: Color(0xFF1ABC9C)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REGISTRAR MEDIDAS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Snapshot de hoy para tu road map',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Campos
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Peso — obligatorio
                      _FieldLabel('Peso (kg)', required: true),
                      const SizedBox(height: 6),
                      _NumericField(
                        controller: _weightCtrl,
                        hint: 'Ej: 78.5',
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'El peso es obligatorio';
                          }
                          final n = double.tryParse(v.replaceAll(',', '.'));
                          if (n == null || n < 20 || n > 300) {
                            return 'Valor fuera de rango';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // % Grasa — opcional
                      _FieldLabel('% Grasa corporal', required: false),
                      const SizedBox(height: 6),
                      _NumericField(
                        controller: _bfCtrl,
                        hint: 'Ej: 22  (opcional)',
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = double.tryParse(v.replaceAll(',', '.'));
                          if (n == null || n < 3 || n > 60) {
                            return 'Valor fuera de rango';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Cintura — opcional
                      _FieldLabel('Cintura (cm)', required: false),
                      const SizedBox(height: 6),
                      _NumericField(
                        controller: _waistCtrl,
                        hint: 'Ej: 86  (opcional)',
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = double.tryParse(v.replaceAll(',', '.'));
                          if (n == null || n < 40 || n > 200) {
                            return 'Valor fuera de rango';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Nota — opcional
                      _FieldLabel('Nota (opcional)', required: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDecoration('¿Cómo te sentiste hoy?'),
                      ),

                      const SizedBox(height: 28),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1ABC9C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Guardar medidas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers de UI ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.required});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF1ABC9C),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.hint,
    this.validator,
  });
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration(hint),
      validator: validator,
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1ABC9C), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
