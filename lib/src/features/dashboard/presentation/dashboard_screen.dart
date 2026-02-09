import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../profile/domain/user_model.dart';
import '../../onboarding/logic/elena_brain.dart';
import 'widgets/fasting_card.dart';
import 'widgets/protocol_selector.dart'; // Import ProtocolSelector
import '../../fasting/presentation/fasting_controller.dart'; // Import FastingController

import '../../progress/presentation/progress_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../profile/domain/user_model.dart';
import '../../onboarding/logic/elena_brain.dart';
import 'widgets/fasting_card.dart';
import 'widgets/protocol_selector.dart';
import '../../fasting/presentation/fasting_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Obtener Usuario
    final authUser = ref.watch(authRepositoryProvider).currentUser;
    if (authUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final userAsync = ref.watch(userStreamProvider(authUser.uid));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Perfil no encontrado.'));
        }
        
        final recommendation = ElenaBrain.generatePlan(user); // Keep for reference if needed
        final healthPlan = ElenaBrain.generateHealthPlan(user);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Saludo Personalizado
              Text(
                'Hola, ${user.displayName}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Tu plan para hoy: ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Selector de Protocolo
                  Consumer(
                    builder: (context, ref, _) {
                      // Watch the state to get current planned hours
                      final asyncState = ref.watch(fastingControllerProvider);
                      
                      // Default protocol from health plan
                      String protocol = healthPlan.protocol.replaceAll(':', '/');
                      
                      // If we have state and planned hours, override
                      if (asyncState.hasValue) {
                         final state = asyncState.value!;
                         protocol = "${state.plannedHours}/${24 - state.plannedHours}";
                      }

                      return ProtocolSelector(currentProtocol: protocol);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Anillo de Ayuno (Motor de Ayuno)
              const FastingCard(),
              const SizedBox(height: 32),

              // 3. Título de Estrategia
              Text(
                'TU ESTRATEGIA DE METAMORFOSIS',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Tarjetas de Estrategia

              // TARJETA 1: MOVIMIENTO
              _StrategyCard(
                icon: Icons.directions_run,
                color: Colors.orangeAccent,
                title: healthPlan.exerciseStrategy,
                subtitle: healthPlan.exerciseFrequency,
                badge: 'Zona 2: < ${healthPlan.maxHeartRate} ppm',
              ),
              const SizedBox(height: 16),

              // TARJETA 2: NUTRICIÓN
               _StrategyCard(
                icon: Icons.restaurant,
                color: Colors.green,
                title: healthPlan.nutritionStrategy,
                subtitle: 'Romper ayuno: ${healthPlan.breakingFastTip}',
                warning: (user.pathologies.contains('prediabetes') || user.pathologies.contains('diabetes'))
                    ? 'Orden: Fibra > Proteína > Carbohidratos'
                    : null,
              ),
              const SizedBox(height: 16),

              // TARJETA 3: GLUCOSA (Condicional)
              if (healthPlan.glucoseStrategy != null)
                 _StrategyCard(
                  icon: Icons.bloodtype,
                  color: Colors.redAccent,
                  title: 'Control de Glucosa',
                  subtitle: healthPlan.glucoseStrategy!,
                  badge: 'Vital',
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error cargando perfil: $e')),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final String? warning;

  const _StrategyCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badge,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (badge != null)
                  Chip(
                    label: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: color,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
            ),
            if (warning != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
