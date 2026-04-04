import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/science/metabolic_engine.dart';
import '../../application/fasting_controller.dart';
import '../../domain/diagnostic_matrix.dart';
import '../../domain/fasting_symptom.dart';

class SosButtonWidget extends ConsumerWidget {
  final Duration fastingElapsed;

  const SosButtonWidget({
    super.key,
    required this.fastingElapsed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _showSymptomsSheet(context, ref),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: const Icon(Icons.medical_services_outlined, size: 20),
      label: const Text('SOS'),
    );
  }

  void _showSymptomsSheet(BuildContext context, WidgetRef ref) {
    final zone = MetabolicEngine.calculateZone(fastingElapsed);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Me siento...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Qué síntoma tienes ahora mismo?',
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const SizedBox(height: 8),
              Text(
                'Fase actual: ${_zoneLabel(zone)}',
                style: const TextStyle(fontSize: 12, color: Colors.white38),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: DiagnosticMatrix.interventions.length,
                itemBuilder: (context, index) {
                  final intervention = DiagnosticMatrix.interventions[index];
                  return ListTile(
                    leading: Icon(
                      _iconForSymptom(intervention.symptom),
                      color: Colors.white70,
                    ),
                    title: Text(
                      intervention.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.white38),
                    onTap: () => _showIntervention(context, ref, intervention),
                  );
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Estoy bien, cerrar',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIntervention(
    BuildContext context,
    WidgetRef ref,
    SymptomIntervention intervention,
  ) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  _iconForSymptom(intervention.symptom),
                  size: 48,
                  color: intervention.requiresBreakFast
                      ? Colors.red[400]
                      : Colors.orange[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                intervention.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Por qué ocurre?',
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      intervention.cause,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qué hacer ahora',
                      style: TextStyle(fontSize: 12, color: Colors.white38),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      intervention.intervention,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (intervention.requiresBreakFast)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(fastingControllerProvider.notifier)
                          .endFasting();
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                    ),
                    child: const Text('Terminar Ayuno Ahora'),
                  ),
                ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Entendido, continúo',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForSymptom(FastingSymptom symptom) {
    switch (symptom) {
      case FastingSymptom.intenseFasting:
        return Icons.sentiment_dissatisfied_outlined;
      case FastingSymptom.dizziness:
        return Icons.blur_on_outlined;
      case FastingSymptom.heartburn:
        return Icons.local_fire_department_outlined;
      case FastingSymptom.headache:
        return Icons.psychology_outlined;
      case FastingSymptom.fatigue:
        return Icons.battery_alert_outlined;
      case FastingSymptom.palpitations:
        return Icons.favorite_border;
    }
  }

  String _zoneLabel(MetabolicZone zone) {
    return switch (zone) {
      MetabolicZone.postAbsorption => 'Digestión',
      MetabolicZone.glycogenDepletion => 'Agotamiento de glucógeno',
      MetabolicZone.fatBurning => 'Quema de grasa activa',
      MetabolicZone.deepKetosis => 'Cetosis profunda',
      MetabolicZone.autophagy => 'Autofagia',
      MetabolicZone.survivalMode => 'Ayuno extendido',
    };
  }
}
