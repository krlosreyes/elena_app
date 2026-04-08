import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/metabolic_history_provider.dart';

class StabilityMatrix extends ConsumerWidget {
  const StabilityMatrix({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(weeklyHistoryStreamProvider);
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) return const Text("INICIA TU TRANSFORMACIÓN HOY", style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold));
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: history.map((data) {
            final score = (data['score'] as num).toInt();
            final isToday = data == history.last;
            return _MatrixItem(score: score, day: data['day'] ?? '?', isToday: isToday);
          }).toList(),
        );
      },
      loading: () => const CircularProgressIndicator(strokeWidth: 2),
      error: (e, s) => const Icon(Icons.error_outline, color: Colors.white10),
    );
  }
}

class _MatrixItem extends StatelessWidget {
  final int score;
  final String day;
  final bool isToday;
  const _MatrixItem({required this.score, required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? const Color(0xFF00E676) : (score >= 50 ? Colors.orangeAccent : Colors.redAccent);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(isToday ? 0.9 : 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isToday ? Colors.white : Colors.white10),
            ),
            child: Center(child: Text("$score", style: TextStyle(fontSize: 15, color: isToday ? Colors.white : Colors.white24))),
          ),
          const SizedBox(height: 8),
          Text(day, style: TextStyle(fontSize: 10, color: isToday ? Colors.white : Colors.white12)),
        ],
      ),
    );
  }
}