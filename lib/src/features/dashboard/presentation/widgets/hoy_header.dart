// Rediseño Hoy (2026-10-30): encabezado "Hola, Carlos" + fecha + racha.
// Reemplaza a ElenaHeader en la pantalla Hoy (título "Hoy" + avatar).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/widgets/page_hero.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class HoyHeader extends ConsumerWidget {
  const HoyHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final streak = ref.watch(streakProvider.select((s) => s.currentStreak));
    final firstName = (user?.name ?? '').trim().split(RegExp(r'\s+')).first;
    final title = firstName.isEmpty ? 'Hola' : 'Hola, $firstName';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: PageHero(title: title, subtitle: heroTodayLabel()),
        ),
        if (streak > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  'Racha $streak ${streak == 1 ? 'día' : 'días'}',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
