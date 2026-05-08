// SPEC-71.2: ExerciseInputSheet con tipado SPEC-68.
//
// Antes: la sheet solo capturaba minutos + activityType (string libre
// "Caminata"/"Cardio"/"Fuerza"/"HIIT"/"Otro"). El motor ExerciseLoadCalculator
// (SPEC-68) opera sobre ExerciseType (enum) e ExerciseIntensity (enum)
// con multiplicadores documentados en IMR_BIBLIOGRAPHY.md §8. La UI
// no exponía esos campos, así que el calculador siempre operaba en
// modo neutral.
//
// Ahora: el bloque básico (minutos + actividad string libre) sigue
// arriba — quien quiera registrar rápido lo hace en 3 toques. Debajo,
// un toggle "Más detalle" expone los 4 campos SPEC-68:
//   - type: ExerciseType (LISS/HIIT/STRENGTH/MOBILITY) como segmented.
//   - intensity: ExerciseIntensity (low/moderate/high) como segmented.
//   - rpe: 1-10 como slider opcional (escala Borg modificada).
//   - heartRateAvg: input numérico opcional.
//
// Si el usuario deja todo en blanco, el log se persiste sin tipado y
// el calculador degrada a la curva minutos/30 — comportamiento previo.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';

class ExerciseInputSheet extends ConsumerStatefulWidget {
  const ExerciseInputSheet({super.key});

  @override
  ConsumerState<ExerciseInputSheet> createState() =>
      _ExerciseInputSheetState();
}

class _ExerciseInputSheetState extends ConsumerState<ExerciseInputSheet> {
  static const _accentColor = AppColors.metabolicGreen;

  int _minutes = 45;
  String _activityType = "Cardio";
  final List<String> _activities = [
    "Caminata",
    "Cardio",
    "Fuerza",
    "HIIT",
    "Otro"
  ];

  // SPEC-71.2: detalle SPEC-68 — todo opcional.
  bool _showDetail = false;
  ExerciseType? _type;
  ExerciseIntensity? _intensity;
  double? _rpe;
  final _heartRateController = TextEditingController();

  @override
  void dispose() {
    _heartRateController.dispose();
    super.dispose();
  }

  void _submit() {
    final hr = _heartRateController.text.trim().isEmpty
        ? null
        : int.tryParse(_heartRateController.text.trim());

    ref
        .read(exerciseProvider.notifier)
        .registerExercise(
          minutes: _minutes,
          activityType: _activityType,
          timestamp: DateTime.now(),
          type: _type,
          intensity: _intensity,
          rpe: _rpe?.round(),
          heartRateAvg: hr,
        )
        .then((_) {
      if (mounted) Navigator.pop(context);
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              "REGISTRAR EJERCICIO",
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ── Duración ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "DURACIÓN (MIN)",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: _accentColor),
                      onPressed: () => setState(
                          () => _minutes = (_minutes - 5).clamp(5, 120)),
                    ),
                    Text(
                      "$_minutes",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: _accentColor),
                      onPressed: () => setState(
                          () => _minutes = (_minutes + 5).clamp(5, 120)),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),

            // ── Tipo de actividad (string libre legacy) ───────────────
            const Text(
              "TIPO DE ACTIVIDAD",
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activities.map((a) {
                final isSelected = _activityType == a;
                return ChoiceChip(
                  label: Text(a),
                  selected: isSelected,
                  selectedColor: _accentColor.withValues(alpha: 0.2),
                  backgroundColor: const Color(0xFF1E293B),
                  side: BorderSide(
                    color: isSelected ? _accentColor : Colors.transparent,
                  ),
                  onSelected: (val) => setState(() => _activityType = a),
                );
              }).toList(),
            ),

            // ── Toggle detalle SPEC-68 ────────────────────────────────
            const SizedBox(height: 20),
            _DetailToggle(
              isExpanded: _showDetail,
              onToggle: () => setState(() => _showDetail = !_showDetail),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              child:
                  _showDetail ? _buildDetailSection() : const SizedBox.shrink(),
            ),

            // ── CTA ───────────────────────────────────────────────────
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: state.isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "GUARDAR REGISTRO",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tipo de ejercicio (ExerciseType enum) ─────────────────────
          _DetailHeader(
            label: 'CATEGORÍA',
            hint: 'Determina el multiplicador metabólico',
            valueText: _type == null ? 'No seleccionada' : _typeLabel(_type!),
            onClear:
                _type == null ? null : () => setState(() => _type = null),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExerciseType.values
                .map((t) => _Chip(
                      label: _typeLabel(t),
                      selected: _type == t,
                      onTap: () => setState(() => _type = t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Intensidad (ExerciseIntensity enum) ──────────────────────
          _DetailHeader(
            label: 'INTENSIDAD',
            hint: 'Esfuerzo subjetivo de la sesión',
            valueText: _intensity == null
                ? 'No seleccionada'
                : _intensityLabel(_intensity!),
            onClear: _intensity == null
                ? null
                : () => setState(() => _intensity = null),
          ),
          const SizedBox(height: 8),
          Row(
            children: ExerciseIntensity.values
                .map(
                  (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _Chip(
                        label: _intensityLabel(i),
                        selected: _intensity == i,
                        onTap: () => setState(() => _intensity = i),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          // RPE 1-10 (escala Borg modificada) ────────────────────────
          _DetailHeader(
            label: 'RPE (1-10)',
            hint: 'Escala de esfuerzo percibido',
            valueText: _rpe == null ? 'No medido' : '${_rpe!.round()} / 10',
            onClear: _rpe == null ? null : () => setState(() => _rpe = null),
          ),
          Slider(
            value: _rpe ?? 1,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: _accentColor,
            inactiveColor: Colors.white.withValues(alpha: 0.10),
            label: _rpe == null ? '—' : '${_rpe!.round()}',
            onChanged: (v) => setState(() => _rpe = v),
          ),
          const SizedBox(height: 8),

          // Frecuencia cardíaca promedio ─────────────────────────────
          _DetailHeader(
            label: 'FC PROMEDIO',
            hint: 'Latidos por minuto durante la sesión',
            valueText: _heartRateController.text.isEmpty
                ? 'No medido'
                : '${_heartRateController.text} bpm',
            onClear: _heartRateController.text.isEmpty
                ? null
                : () => setState(() => _heartRateController.clear()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _heartRateController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Ej: 142',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.30)),
              suffixText: 'bpm',
              suffixStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accentColor, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(ExerciseType t) {
    switch (t) {
      case ExerciseType.liss:
        return 'LISS';
      case ExerciseType.hiit:
        return 'HIIT';
      case ExerciseType.strength:
        return 'Fuerza';
      case ExerciseType.mobility:
        return 'Movilidad';
    }
  }

  String _intensityLabel(ExerciseIntensity i) {
    switch (i) {
      case ExerciseIntensity.low:
        return 'Baja';
      case ExerciseIntensity.moderate:
        return 'Moderada';
      case ExerciseIntensity.high:
        return 'Alta';
    }
  }
}

class _DetailToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DetailToggle({required this.isExpanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              isExpanded ? 'Ocultar detalle' : 'Más detalle (opcional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Text(
              'Mejora tu IMR',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final String label;
  final String hint;
  final String valueText;
  final VoidCallback? onClear;

  const _DetailHeader({
    required this.label,
    required this.hint,
    required this.valueText,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        Text(
          valueText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.metabolicGreen.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.metabolicGreen
                : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected
                ? AppColors.metabolicGreen
                : Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
