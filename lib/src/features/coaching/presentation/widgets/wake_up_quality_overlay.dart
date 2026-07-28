// SPEC-234 Momento A: overlay "¿Ya despertaste?" con check-in de calidad
// subjetiva del sueño. Reemplaza el overlay simple del dashboard con un
// flujo de 2 pasos:
//   Paso 1: "¿Ya despertaste?" → transición visual al paso 2
//   Paso 2: "¿Cómo dormiste?" → 5 emojis (1-5) → confirmManualWakeUp con quality
//
// Walker 2017: la percepción subjetiva correlaciona con sleep efficiency.
// No penaliza — es coaching, no examen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';

class WakeUpQualityOverlay extends ConsumerStatefulWidget {
  const WakeUpQualityOverlay({super.key});

  @override
  ConsumerState<WakeUpQualityOverlay> createState() =>
      _WakeUpQualityOverlayState();
}

class _WakeUpQualityOverlayState extends ConsumerState<WakeUpQualityOverlay> {
  /// false = paso 1 (confirmar wake-up), true = paso 2 (calidad subjetiva).
  bool _showQualityStep = false;

  static const _qualityOptions = [
    _QualityOption(emoji: '😫', label: 'Muy mal', value: 1),
    _QualityOption(emoji: '😕', label: 'Mal', value: 2),
    _QualityOption(emoji: '😐', label: 'Regular', value: 3),
    _QualityOption(emoji: '😊', label: 'Bien', value: 4),
    _QualityOption(emoji: '🤩', label: 'Increíble', value: 5),
  ];

  void _goToQualityStep() {
    // No llamamos confirmManualWakeUp aún — dejamos isWaitingForWakeUp = true
    // para que el overlay siga visible. Lo llamaremos en paso 2.
    setState(() => _showQualityStep = true);
  }

  void _selectQuality(int quality) {
    // Cerrar el wake-up con calidad subjetiva adjunta.
    ref
        .read(sleepProvider.notifier)
        .confirmManualWakeUp(subjectiveQuality: quality);

    AnalyticsService.logEvent(
      'sleep_quality_checkin',
      params: {
        'quality': quality.toString(),
        'surface': 'wake_up_overlay',
      },
    );
  }

  void _skipQuality() {
    // Cerrar sin calidad — comportamiento original.
    ref.read(sleepProvider.notifier).confirmManualWakeUp();

    AnalyticsService.logEvent(
      'sleep_quality_checkin',
      params: const {
        'quality': 'skipped',
        'surface': 'wake_up_overlay',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showQualityStep) {
      return _buildQualityStep(context);
    }
    return _buildWakeUpStep(context);
  }

  Widget _buildWakeUpStep(BuildContext context) {
    final isSaving = ref.watch(sleepProvider).isSaving;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.orangeAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: 0.2),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_rounded,
              color: Colors.orangeAccent, size: 28),
          const SizedBox(height: 12),
          const Text(
            '¿YA DESPERTASTE?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Elena detecta actividad matutina.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: isSaving ? null : _goToQualityStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SÍ, DESPERTÉ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityStep(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF818CF8), // pillarSueno
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF818CF8).withValues(alpha: 0.2),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bedtime_rounded, color: Color(0xFF818CF8), size: 28),
          const SizedBox(height: 12),
          const Text(
            '¿CÓMO DORMISTE?',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu percepción nos ayuda a personalizar tu coaching.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final opt in _qualityOptions)
                _QualityChip(
                  option: opt,
                  onTap: () => _selectQuality(opt.value),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skipQuality,
            child: Text(
              'Saltar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  final _QualityOption option;
  final VoidCallback onTap;

  const _QualityChip({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(option.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            option.label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityOption {
  final String emoji;
  final String label;
  final int value;
  const _QualityOption({
    required this.emoji,
    required this.label,
    required this.value,
  });
}
