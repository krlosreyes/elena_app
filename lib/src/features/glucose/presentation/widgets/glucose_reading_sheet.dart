// Módulo "Tu Glucosa" — sheet de registro de una lectura (propuesta
// §6.3/§7.2). Mismo lenguaje visual que rest_day_prompt_sheet.dart /
// glucose_consent_sheet.dart.
//
// R9 (regla de negocio): valores fuera del rango fisiológico plausible
// piden confirmación explícita antes de guardar; valores <70 o >250
// muestran una nota (sin alarmismo) de considerar contactar a un
// profesional — nunca bloquea el guardado, solo informa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';
import 'package:elena_app/src/features/glucose/data/glucose_repository_impl.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_classification.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';

/// [initialContext] permite abrir el sheet ya preseleccionado — la
/// ventana matutina abre siempre en `ayunas` (R3); el acceso opcional
/// tras registrar una comida (§6.2) abre en `postprandial1h`.
Future<void> showGlucoseReadingSheet(
  BuildContext context, {
  GlucoseReadingContext initialContext = GlucoseReadingContext.ayunas,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => _GlucoseReadingSheet(initialContext: initialContext),
  );
}

class _GlucoseReadingSheet extends ConsumerStatefulWidget {
  const _GlucoseReadingSheet({required this.initialContext});
  final GlucoseReadingContext initialContext;

  @override
  ConsumerState<_GlucoseReadingSheet> createState() =>
      _GlucoseReadingSheetState();
}

class _GlucoseReadingSheetState extends ConsumerState<_GlucoseReadingSheet> {
  late GlucoseReadingContext _context = widget.initialContext;
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  final Set<GlucoseSymptom> _symptoms = {};
  bool _saving = false;
  bool _confirmedOutOfRange = false;
  String? _error;

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _parsedValue => int.tryParse(_valueController.text.trim());

  Future<void> _save() async {
    final value = _parsedValue;
    if (value == null) {
      setState(() => _error = 'Ingresá un número válido.');
      return;
    }

    // R9: fuera del rango fisiológico plausible — pedir confirmación
    // explícita antes de la primera vez que se intenta guardar.
    if (GlucoseClassifier.isOutsidePlausibleRange(value) &&
        !_confirmedOutOfRange) {
      setState(() {
        _error = null;
        _confirmedOutOfRange = true; // el botón cambia a "Confirmar"
      });
      return;
    }

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final symptoms = _symptoms.isEmpty
          ? const [GlucoseSymptom.ninguno]
          : _symptoms.toList();
      final reading = buildGlucoseReadingSnapshot(
        ref,
        userId: uid,
        valueMgDl: value,
        context: _context,
        symptoms: symptoms,
        note: _noteController.text.trim(),
      );
      await ref.read(glucoseRepositoryProvider).saveReading(uid, reading);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'No se pudo guardar. Probá de nuevo.';
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _parsedValue;
    final showMedicalNote =
        value != null && GlucoseClassifier.warrantsMedicalAdviceNote(value);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          children: [
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
            const SizedBox(height: 20),
            const Text(
              'Registrar glucosa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                suffixText: 'mg/dL',
                suffixStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {
                _error = null;
                _confirmedOutOfRange = false;
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Un glucómetro doméstico tiene un margen de error de hasta '
              '±15-20% — tratá este valor como una referencia.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '¿EN QUÉ MOMENTO?',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 10.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GlucoseReadingContext.values.map((c) {
                final selected = c == _context;
                return ChoiceChip(
                  label: Text(c.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _context = c),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  selectedColor: AppColors.metabolicGreen,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              '¿SENTISTE ALGO? (OPCIONAL)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 10.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GlucoseSymptom.mareo,
                GlucoseSymptom.temblor,
                GlucoseSymptom.sudoracion,
                GlucoseSymptom.palpitaciones,
              ].map((s) {
                final selected = _symptoms.contains(s);
                return FilterChip(
                  label: Text(s.label),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _symptoms.add(s);
                    } else {
                      _symptoms.remove(s);
                    }
                  }),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  selectedColor: const Color(0xFFF59E0B),
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Nota opcional (ej. "dormí mal", "mucho estrés")',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (showMedicalNote) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value! < 70
                      ? 'Este valor es bajo. Si sentís síntomas, considerá '
                          'tratarlo según lo que te haya indicado tu médico '
                          'y, si persiste, contactalo.'
                      : 'Este valor es alto. No es un diagnóstico, pero si '
                          'se repite vale la pena comentarlo con tu médico.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (_confirmedOutOfRange) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Este valor está fuera de lo habitual. ¿Confirmás que tu '
                  'glucosa fue $value mg/dL?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.metabolicGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text(
                        _confirmedOutOfRange ? 'Confirmar y guardar' : 'Guardar',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
