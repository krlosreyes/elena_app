import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/elena_today_provider.dart';
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
          onTapUp: (details) => _handlePentagonTap(details, Size(canvasWidth, canvasHeight), items, context),
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

  // Lógica de ayuda movida a métodos privados para claridad
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

  void _handlePentagonTap(TapUpDetails details, Size size, List<PentagonItem> items, BuildContext context) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4.0;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final itemPos = Offset(center.dx + (radius + 58) * cos(angle), center.dy + (radius + 58) * sin(angle));
      if ((details.localPosition - itemPos).distance < 45) {
        _showMetricSheet(context, items[i]);
        break;
      }
    }
  }

  void _showMetricSheet(BuildContext context, PentagonItem item) {
    // ... tu BottomSheet aquí ...
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
          Text("$score", style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text("IMR", style: TextStyle(fontSize: 12, color: Colors.white38, letterSpacing: 2.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}