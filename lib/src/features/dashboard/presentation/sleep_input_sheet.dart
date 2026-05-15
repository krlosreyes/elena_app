// SPEC-71.1: SleepInputSheet con metadata multidimensional SPEC-69.
//
// Antes: solo capturaba bedtime + wakeTime. SleepLog soporta desde
// SPEC-69 latencia, despertares y percepción subjetiva, pero la UI
// nunca se actualizó — el usuario no podía alimentar esos campos.
//
// Ahora: el bloque básico (bedtime + wakeTime) sigue arriba, igual de
// rápido para quien solo quiere meter horas. Debajo, un toggle
// "Más detalle" expande controles para los 3 campos opcionales. Si
// el usuario no los toca, se persisten como null y el
// SleepQualityCalculator degrada graciosamente — mismo comportamiento
// que antes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';

class SleepInputSheet extends ConsumerStatefulWidget {
  /// SPEC-106: si se pasa `initial`, el sheet precarga todos los
  /// campos desde ese log existente — el usuario está editando, no
  /// creando. Si es null, defaults razonables.
  final SleepLog? initial;

  const SleepInputSheet({super.key, this.initial});

  @override
  ConsumerState<SleepInputSheet> createState() => _SleepInputSheetState();
}

class _SleepInputSheetState extends ConsumerState<SleepInputSheet> {
  static const _accentColor = Color(0xFF818CF8);

  late TimeOfDay _bedtime;
  late TimeOfDay _wakeTime;

  // SPEC-71.1: estado de la sección de detalle.
  // SPEC-106: si hay `initial` con algún campo opcional, abrimos
  // automáticamente el detalle para que el usuario vea sus valores.
  late bool _showDetail;
  // null = "no medido". Distinto de 0 (que sí mide).
  double? _latencyMinutes;
  int? _awakenings;
  int? _subjectiveQuality;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _bedtime = TimeOfDay.fromDateTime(initial.fellAsleep);
      _wakeTime = TimeOfDay.fromDateTime(initial.wokeUp);
      _latencyMinutes = initial.sleepLatencyMinutes?.toDouble();
      _awakenings = initial.nightAwakenings;
      _subjectiveQuality = initial.subjectiveQuality;
      _showDetail = _latencyMinutes != null ||
          _awakenings != null ||
          _subjectiveQuality != null;
    } else {
      _bedtime = const TimeOfDay(hour: 22, minute: 30);
      _wakeTime = const TimeOfDay(hour: 7, minute: 0);
      _showDetail = false;
    }
  }

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      builder: (context, child) => _pickerTheme(child!),
    );
    if (picked != null) setState(() => _bedtime = picked);
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      builder: (context, child) => _pickerTheme(child!),
    );
    if (picked != null) setState(() => _wakeTime = picked);
  }

  Widget _pickerTheme(Widget child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _accentColor),
          dialogBackgroundColor: AppColors.surfaceDark,
        ),
        child: child,
      );

  void _submit() {
    ref.read(sleepProvider.notifier).saveManualSleep(
      bedtime: _bedtime,
      wakeTime: _wakeTime,
      sleepLatencyMinutes: _latencyMinutes?.round(),
      nightAwakenings: _awakenings,
      subjectiveQuality: _subjectiveQuality,
    ).then((_) {
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
    final state = ref.watch(sleepProvider);

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
              "REGISTRAR SUEÑO",
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ── Sección básica: horas ─────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "ME ACOSTÉ AYER A LAS",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              subtitle: Text(
                _bedtime.format(context),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.access_time, color: _accentColor),
              onTap: _pickBedtime,
            ),
            const Divider(color: Colors.white10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "ME DESPERTÉ HOY A LAS",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              subtitle: Text(
                _wakeTime.format(context),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              trailing:
                  const Icon(Icons.wb_sunny_outlined, color: _accentColor),
              onTap: _pickWakeTime,
            ),

            // ── Sección detalle (SPEC-69) ─────────────────────────────
            const SizedBox(height: 20),
            _DetailToggle(
              isExpanded: _showDetail,
              onToggle: () => setState(() => _showDetail = !_showDetail),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              child: _showDetail
                  ? _buildDetailSection()
                  : const SizedBox.shrink(),
            ),

            // ── CTA ───────────────────────────────────────────────────
            const SizedBox(height: 32),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: state.isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: state.isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "GUARDAR REGISTRO",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14),
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
          // Latencia ─────────────────────────────────────────────────
          _DetailHeader(
            label: 'LATENCIA',
            hint: 'Minutos en quedarte dormido',
            valueText: _latencyMinutes == null
                ? 'No medido'
                : '${_latencyMinutes!.round()} min',
            onClear: _latencyMinutes == null
                ? null
                : () => setState(() => _latencyMinutes = null),
          ),
          Slider(
            value: _latencyMinutes ?? 0,
            min: 0,
            max: 90,
            divisions: 18,
            activeColor: _accentColor,
            inactiveColor: Colors.white.withValues(alpha: 0.10),
            label: _latencyMinutes == null
                ? '—'
                : '${_latencyMinutes!.round()} min',
            onChanged: (v) => setState(() => _latencyMinutes = v),
          ),
          const SizedBox(height: 8),

          // Despertares ──────────────────────────────────────────────
          _DetailHeader(
            label: 'DESPERTARES',
            hint: 'Veces que te despertaste',
            valueText: _awakenings == null ? 'No medido' : '$_awakenings',
            onClear: _awakenings == null
                ? null
                : () => setState(() => _awakenings = null),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) {
                final selected = _awakenings == i;
                return _Chip(
                  label: i == 5 ? '5+' : '$i',
                  selected: selected,
                  onTap: () => setState(() => _awakenings = i),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Calidad subjetiva ────────────────────────────────────────
          _DetailHeader(
            label: 'CALIDAD PERCIBIDA',
            hint: '¿Cómo te sentiste al despertar?',
            valueText: _subjectiveQuality == null
                ? 'No medido'
                : '${_subjectiveQuality!} / 5',
            onClear: _subjectiveQuality == null
                ? null
                : () => setState(() => _subjectiveQuality = null),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final rating = i + 1;
                final selected = (_subjectiveQuality ?? 0) >= rating;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _subjectiveQuality = rating),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      selected ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 32,
                      color: selected
                          ? _accentColor
                          : Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF818CF8).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF818CF8)
                : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: selected
                ? const Color(0xFF818CF8)
                : Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
