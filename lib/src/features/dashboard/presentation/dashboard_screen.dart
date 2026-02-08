import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/science/science.dart'; // Si MetabolicEngine se usa, aunque ElenaBrain es el principal ahora
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../onboarding/logic/elena_brain.dart';
// import '../../onboarding/domain/recommendation_plan.dart'; // Lo usaremos vía ElenaBrain por ahora

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateChangesProvider).value;
    
    // Si no hay usuario autenticado, no deberíamos estar aquí, pero por seguridad:
    if (authUser == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userAsync = ref.watch(userStreamProvider(authUser.uid));

    return Scaffold(
      // backgroundColor: Use default from Theme (gray/white)
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Usuario no encontrado'));
          
          // Generamos el plan al vuelo con los datos frescos
          final plan = ElenaBrain.generatePlan(user);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Personalizado
                  _buildHeader(user.displayName, ref, context),
                  const SizedBox(height: 30),

                  // 2. Estado del Ayuno
                  _buildFastingStatus(plan.recommendedFastingProtocol, context),
                  const SizedBox(height: 30),

                  // 3. Panel de Prescripción
                  Text(
                    'Tu Receta Metabólica de Hoy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildPrescriptionGrid(plan, user, context),
                ],
              ),
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(String name, WidgetRef ref, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $name',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Día 1 de tu Metamorfosis 🦋',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            ref.read(authRepositoryProvider).signOut();
          },
          icon: Icon(Icons.logout, color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }

  Widget _buildFastingStatus(String protocol, BuildContext context) {
    // Lógica simulada de estado
    final now = DateTime.now();
    final isFasting = now.hour < 12;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTADO ACTUAL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isFasting ? 'En Ayuno' : 'Ventana de Alimentación',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isFasting ? const Color(0xFF00E676) : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Protocolo $protocol',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.7, // Valor dummy
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  color: isFasting ? const Color(0xFF00E676) : Colors.orangeAccent,
                ),
              ),
              Icon(Icons.bolt, color: Theme.of(context).primaryColor, size: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionGrid(dynamic plan, dynamic user, BuildContext context) {
    // dynamic plan para no importar el modelo directamente si no es necesario,
    // pero idealmente importar RecommendationPlan.
    // Asumimos que plan tiene los campos.

    final prescriptions = [
      _PrescriptionCard(
        icon: Icons.water_drop,
        color: Colors.blueAccent,
        label: 'Hidratación',
        value: '0/${plan.dailyWaterIntakeLitres} L',
        action: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
          onPressed: () {}, // TODO: Implement logic
        ),
      ),
      _PrescriptionCard(
        icon: Icons.favorite,
        color: Colors.redAccent,
        label: 'Zona 2 (MAF)',
        value: '< ${plan.exerciseZoneHeartRate} ppm',
        subtext: plan.exerciseFrequency,
      ),
      if (plan.requiresGlucometer)
        _PrescriptionCard(
          icon: Icons.bloodtype,
          color: Colors.purpleAccent,
          label: 'Glucosa Ayunas',
          value: plan.glucoseTargetFasting ?? '-',
          subtext: 'Meta',
        ),
       _PrescriptionCard(
        icon: Icons.bedtime,
        color: Colors.indigoAccent,
        label: 'Dormir',
        value: user.bedTime,
        subtext: 'Ritmo Circadiano',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: prescriptions.length,
      itemBuilder: (context, index) => prescriptions[index],
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subtext;
  final Widget? action;

  const _PrescriptionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.subtext,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              if (action != null) SizedBox(height: 24, width: 24, child: action),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (subtext != null) ...[
                const SizedBox(height: 2),
                 Text(
                  subtext!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
