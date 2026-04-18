import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

class ElenaHeader extends ConsumerWidget {
  final String title;

  const ElenaHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final streakState = ref.watch(streakProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : "U";

        return Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.metabolicGreen.withOpacity(0.1),
              child: Text(initial, style: const TextStyle(color: AppColors.metabolicGreen, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: AppColors.metabolicGreen, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            _buildStreakBadge(streakState.currentStreak.toString()),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStreakBadge(String days) {
    final int count = int.tryParse(days) ?? 0;
    final String label = count == 1 ? "DÍA" : "DÍAS";
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$count $label", style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 12),
        ],
      ),
    );
  }
}