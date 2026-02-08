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
      backgroundColor: const Color(0xFF121212), // Dark background
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
                  _buildHeader(user.displayName, ref),
                  const SizedBox(height: 30),

                  // 2. Estado del Ayuno
                  _buildFastingStatus(plan.recommendedFastingProtocol),
                  const SizedBox(height: 30),

                  // 3. Panel de Prescripción
                  const Text(
                    'Tu Receta Metabólica de Hoy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPrescriptionGrid(plan, user),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF009688))),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(String name, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $name',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Día 1 de tu Metamorfosis 🦋',
              style: TextStyle(
                color: Color(0xFF009688), // Teal
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            ref.read(authRepositoryProvider).signOut();
          },
          icon: const Icon(Icons.logout, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildFastingStatus(String protocol) {
    // Lógica simulada de estado (podría mejorarse con la hora real vs ventana)
    final now = DateTime.now();
    final isFasting = now.hour < 12; // Ejemplo simplificado: Mañana es ayuno

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
              const Text(
                'ESTADO ACTUAL',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFasting ? 'En Ayuno' : 'Ventana de Alimentación',
                style: TextStyle(
                  color: isFasting ? const Color(0xFF00E676) : Colors.orangeAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Protocolo $protocol',
                style: const TextStyle(color: Colors.white70),
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
                  backgroundColor: Colors.grey[800],
                  color: isFasting ? const Color(0xFF00E676) : Colors.orangeAccent,
                ),
              ),
              const Icon(Icons.bolt, color: Colors.white, size: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionGrid(dynamic plan, dynamic user) {
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
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              if (subtext != null) ...[
                const SizedBox(height: 2),
                 Text(
                  subtext!,
                  style: TextStyle(
                    color: Colors.grey[600],
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
