// Rediseño (2026-10-30): el reloj circadiano salió de la portada de Hoy y
// vive aquí, como detalle opcional al que se entra desde Progreso.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/circadian_clock.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/clock_explainer_sheet.dart';
import 'package:elena_app/src/features/fasting/application/eating_window_provider.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class CircadianClockScreen extends ConsumerWidget {
  const CircadianClockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final fastingState = ref.watch(fastingProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tu reloj circadiano',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.metabolicGreen),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              children: [
                Text(
                  'Cómo se reparte tu día entre vigilia, comida y descanso.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 1,
                  child: CircadianClock(
                    user: user,
                    fastingState: fastingState,
                    eatingWindow: ref.watch(eatingWindowProvider),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: () => showClockExplainerSheet(context),
                    icon: const Icon(Icons.help_outline_rounded, size: 16),
                    label: const Text('¿Qué significan los anillos?'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
