import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/blueprint_grid.dart';
import '../../../core/widgets/elena_header.dart';
import '../../profile/application/user_controller.dart';
import '../application/hydration_controller.dart';
import '../../../domain/logic/elena_brain.dart';
import '../../../core/providers/metabolic_hub_provider.dart';

class HydrationScreen extends ConsumerWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final metabolicHub = ref.watch(metabolicHubProvider);
    final healthPlan = ElenaBrain.generateHealthPlan(user);

    final hydrationGoal = healthPlan.hydrationGoal; // en vasos (250ml)
    final currentGlasses = metabolicHub.hydrationLevel;
    final currentLiters = currentGlasses * 0.25;
    final goalLiters = hydrationGoal * 0.25;
    final progress = (currentGlasses / hydrationGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlueprintGrid(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElenaHeader(title: 'Hydration Control', user: user),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'REGISTRO DE HIDRATACIÓN',
                      style: GoogleFonts.publicSans(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Mantén tu pulso metabólico al máximo.',
                      style: GoogleFonts.publicSans(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Main Circular Progress Card
                    _CircularProgressCard(
                      current: currentLiters,
                      goal: goalLiters,
                      progress: progress,
                    ),

                    const SizedBox(height: 24),

                    // Quick Register
                    _QuickRegisterGrid(
                      onAdd: (amountMl) {
                        int glasses = (amountMl / 250).round();
                        ref
                            .read(hydrationControllerProvider.notifier)
                            .addWater(glasses);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Metabolic Tip
                    const _MetabolicTipCard(),

                    const SizedBox(height: 24),

                    // Hydra-Reminder Protocol
                    const _HydraReminderCard(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HydraReminderCard extends ConsumerWidget {
  const _HydraReminderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(hydraReminderProtocolProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.blueAccent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: isActive
                      ? Colors.blueAccent
                      : Colors.white.withValues(alpha: 0.4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROTOCOLO HYDRA-REMINDER',
                      style: GoogleFonts.robotoMono(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? 'Recordatorio activo cada 30 min.'
                          : 'Recordatorio dinámico desactivado.',
                      style: GoogleFonts.publicSans(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (val) {
                  ref
                      .read(hydrationControllerProvider.notifier)
                      .toggleHydraReminder(val);
                },
                activeThumbColor: Colors.blueAccent,
                activeTrackColor: Colors.blueAccent.withValues(alpha: 0.2),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.blueAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El sistema insistirá cada 5 min si no has tomado agua.',
                      style: GoogleFonts.publicSans(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircularProgressCard extends StatelessWidget {
  final double current;
  final double goal;
  final double progress;

  const _CircularProgressCard({
    required this.current,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        current.toStringAsFixed(1),
                        style: GoogleFonts.robotoMono(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'L',
                        style: GoogleFonts.robotoMono(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'META: ${goal.toStringAsFixed(1)}L',
                    style: GoogleFonts.robotoMono(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  label: 'RESTANTE',
                  value: '${(goal - current).clamp(0, 99).toStringAsFixed(1)}L',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _SmallStat(
                  label: 'PROGRESO',
                  value: '${(progress * 100).toInt()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;

  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.robotoMono(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuickRegisterGrid extends StatelessWidget {
  final Function(int) onAdd;

  const _QuickRegisterGrid({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REGISTRO RÁPIDO',
          style: GoogleFonts.robotoMono(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _QuickButton(
                    icon: Icons.local_drink_rounded,
                    label: '250ml',
                    onTap: () => onAdd(250))),
            const SizedBox(width: 12),
            Expanded(
                child: _QuickButton(
                    icon: Icons.water_drop_rounded,
                    label: '500ml',
                    onTap: () => onAdd(500))),
            const SizedBox(width: 12),
            Expanded(
                child: _QuickButton(
                    icon: Icons.opacity_rounded,
                    label: '1L',
                    onTap: () => onAdd(1000))),
          ],
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2128),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetabolicTipCard extends StatelessWidget {
  const _MetabolicTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1712),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dato Metabólico',
                  style: GoogleFonts.publicSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mantenerte hidratado incrementa tu tasa metabólica basal en reposo hasta un 30% durante la siguiente hora.',
                  style: GoogleFonts.publicSans(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
