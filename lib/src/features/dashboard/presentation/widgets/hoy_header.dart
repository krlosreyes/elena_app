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
          child: PageHero(
            title: title,
            subtitle: '${heroTodayLabel()} · Día metabólico',
          ),
        ),
        if (streak > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 16, color: Color(0xFFEF9F27)),
                const SizedBox(width: 6),
                Text(
                  '$streak ${streak == 1 ? 'día' : 'días'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
