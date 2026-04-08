import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/elena_today_provider.dart';
import '../../../hydration/application/hydration_controller.dart'; 
import '../../../fasting/application/fasting_controller.dart';
import '../../../training/application/training_controller.dart';
import '../../../training/domain/training_enums.dart';
import '../../../sleep/application/sleep_controller.dart';
import '../../../profile/application/user_controller.dart';
// Importación del repositorio para Nutrición
import '../../../health/data/health_repository.dart';

import 'painters/pentagon_painter.dart';
import 'stability_matrix.dart';

class MetabolicPentagonGrid extends ConsumerWidget {
  const MetabolicPentagonGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(elenaTodayProvider);
    final double canvasWidth = MediaQuery.of(context).size.width - 40;
    const double canvasHeight = 380.0;
    final items = _getPentagonItems(state);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapUp: (details) => _handlePentagonTap(details, Size(canvasWidth, canvasHeight), items, context, ref),
          child: SizedBox(
            height: canvasHeight,
            width: canvasWidth,
            child: CustomPaint(
              painter: PentagonDataPainter(items: items),
              child: _IMRCenterLabel(score: state.score.score.toInt()),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const StabilityMatrix(),
      ],
    );
  }

  List<PentagonItem> _getPentagonItems(ElenaTodayState state) {
    Color getColor(double val) => val >= 80 ? const Color(0xFF00E676) : (val >= 50 ? Colors.orangeAccent : Colors.redAccent);
    return [
      PentagonItem(label: 'TREN', value: state.trainingScore, icon: Icons.fitness_center, color: getColor(state.trainingScore)),
      PentagonItem(label: 'SUEÑO', value: state.sleepScore, icon: Icons.bedtime_outlined, color: getColor(state.sleepScore)),
      PentagonItem(label: 'NUTRI', value: state.nutritionScore, icon: Icons.restaurant_menu, color: getColor(state.nutritionScore)),
      PentagonItem(label: 'AGUA', value: state.hydrationScore, icon: Icons.water_drop_outlined, color: getColor(state.hydrationScore)),
      PentagonItem(label: 'AYUNO', value: state.fastingScore, icon: Icons.timer_outlined, color: getColor(state.fastingScore)),
    ];
  }

  void _handlePentagonTap(TapUpDetails details, Size size, List<PentagonItem> items, BuildContext context, WidgetRef ref) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4.0;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final itemPos = Offset(center.dx + (radius + 58) * cos(angle), center.dy + (radius + 58) * sin(angle));
      if ((details.localPosition - itemPos).distance < 45) {
        _showMetricSheet(context, items[i], ref);
        break;
      }
    }
  }

  void _showMetricSheet(BuildContext context, PentagonItem item, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      barrierColor: Colors.black.withOpacity(0.8),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, color: item.color, size: 28),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  "${item.value.toInt()}%",
                  style: GoogleFonts.jetBrainsMono(color: item.color, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "ANÁLISIS DE TELEMETRÍA",
              style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _getTechnicalAdvice(item),
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),

            // MÓDULOS DE ACCIÓN RÁPIDA
            if (item.label == 'AGUA') ...[
              _buildWaterQuickActions(ref, context),
            ] else if (item.label == 'AYUNO') ...[
              _buildFastingQuickActions(ref, context),
            ] else if (item.label == 'TREN') ...[
              _buildTrainingQuickActions(ref, context),
            ] else if (item.label == 'SUEÑO') ...[
              _buildSleepQuickActions(ref, context),
            ] else if (item.label == 'NUTRI') ...[
              _buildNutritionQuickActions(ref, context),
            ] else ...[
              _buildGenericAction(item, context),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- ACCIÓN: NUTRICIÓN ---
  Widget _buildNutritionQuickActions(WidgetRef ref, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676).withOpacity(0.1),
          foregroundColor: const Color(0xFF00E676),
          side: const BorderSide(color: Color(0xFF00E676), width: 1),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          // Aquí se dispararía el modal de registro de macros que definiremos
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Abriendo Registro de Densidad Nutricional...")),
          );
        },
        child: const Text("REGISTRAR INGESTA", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- ACCIÓN: SUEÑO ---
  Widget _buildSleepQuickActions(WidgetRef ref, BuildContext context) {
    final sleepStatusAsync = ref.watch(sleepStatusProvider);
    final user = ref.watch(currentUserStreamProvider).valueOrNull;

    return sleepStatusAsync.when(
      data: (status) {
        if (user == null) return const SizedBox();
        final bool isResting = status.isResting;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isResting ? Colors.indigoAccent.withOpacity(0.1) : Colors.amberAccent.withOpacity(0.1),
              foregroundColor: isResting ? Colors.indigoAccent : Colors.amberAccent,
              side: BorderSide(color: (isResting ? Colors.indigoAccent : Colors.amberAccent).withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final sleepNotifier = ref.read(sleepControllerProvider.notifier);
              if (isResting) {
                Navigator.pop(context);
                await sleepNotifier.checkWakeInteraction(user, true, context);
              } else {
                await sleepNotifier.startSleepProtocol(user.uid);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(isResting ? "DESPERTAR / REGISTRAR HORA" : "INICIAR PROTOCOLO NOCTURNO", 
            style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Text("Error en sensor", style: TextStyle(color: Colors.red, fontSize: 10)),
    );
  }

  // --- ACCIÓN: ENTRENAMIENTO (RPE) ---
  Widget _buildTrainingQuickActions(WidgetRef ref, BuildContext context) {
    final training = ref.watch(trainingControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("REGISTRO DE ESFUERZO (RPE)", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(10, (index) {
              final rpeValue = index + 1;
              final isSelected = training.rpe == rpeValue;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    ref.read(trainingControllerProvider.notifier).updateRpe(rpeValue);
                    if (training.phase != TrainingSessionStep.active) {
                      ref.read(trainingControllerProvider.notifier).startMission();
                    }
                    ref.read(trainingControllerProvider.notifier).finishSession();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 45, height: 45,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orangeAccent : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? Colors.orangeAccent : Colors.white10),
                    ),
                    child: Center(child: Text("$rpeValue", style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold))),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // --- ACCIÓN: AYUNO ---
  Widget _buildFastingQuickActions(WidgetRef ref, BuildContext context) {
    final fastingStateAsync = ref.watch(fastingControllerProvider);
    return fastingStateAsync.when(
      data: (fasting) {
        final isFasting = fasting.isFasting;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFasting ? Colors.redAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1),
              foregroundColor: isFasting ? Colors.redAccent : Colors.greenAccent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              isFasting ? ref.read(fastingControllerProvider.notifier).endFasting() : ref.read(fastingControllerProvider.notifier).startFast(hours: fasting.plannedHours);
              Navigator.pop(context);
            },
            child: Text(isFasting ? "TERMINAR AYUNO" : "INICIAR AYUNO ${fasting.plannedHours}H"),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text("Error sync"),
    );
  }

  // --- ACCIÓN: AGUA ---
  Widget _buildWaterQuickActions(WidgetRef ref, BuildContext context) {
    return Row(
      children: [
        _actionButton(context, "250ml", () => _addWater(ref, 1, context), Colors.blueAccent),
        const SizedBox(width: 12),
        _actionButton(context, "500ml", () => _addWater(ref, 2, context), Colors.blueAccent),
        const SizedBox(width: 12),
        _actionButton(context, "1L", () => _addWater(ref, 4, context), Colors.blueAccent),
      ],
    );
  }

  String _getTechnicalAdvice(PentagonItem item) {
    switch (item.label) {
      case 'NUTRI': return "La crononutrición dicta que tu última ingesta debe ser 3h antes de dormir para no inhibir la melatonina.";
      case 'SUEÑO': return "La reparación celular ocurre entre las 10 PM y las 2 AM. Prioriza este bloque.";
      case 'AYUNO': return item.value >= 80 ? "Autofagia activa." : "Inicia el protocolo para optimizar lípidos.";
      case 'TREN': return item.value >= 70 ? "Señal mecánica muscular enviada." : "Registra tu esfuerzo.";
      default: return "Optimiza esta métrica para elevar tu IMR.";
    }
  }

  Widget _actionButton(BuildContext context, String label, VoidCallback onTap, Color color) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(side: BorderSide(color: color), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGenericAction(PentagonItem item, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: item.color.withOpacity(0.1), foregroundColor: item.color, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: () => Navigator.pop(context),
        child: Text("OPTIMIZAR ${item.label}"),
      ),
    );
  }

  void _addWater(WidgetRef ref, int glasses, BuildContext context) {
    ref.read(hydrationControllerProvider.notifier).addWater(glasses);
    Navigator.pop(context);
  }
}

class _IMRCenterLabel extends StatelessWidget {
  final int score;
  const _IMRCenterLabel({required this.score});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$score", style: GoogleFonts.jetBrainsMono(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text("IMR", style: TextStyle(fontSize: 12, color: Colors.white38, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}