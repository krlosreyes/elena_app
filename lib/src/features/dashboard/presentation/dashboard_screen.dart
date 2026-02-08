import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../onboarding/logic/elena_brain.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateChangesProvider).value;
    
    // Si no hay usuario autenticado, main o router deberían manejarlo, 
    // pero mostramos loading por seguridad.
    if (authUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userAsync = ref.watch(userStreamProvider(authUser.uid));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'ElenaApp',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                authUser.displayName != null && authUser.displayName!.isNotEmpty
                    ? authUser.displayName![0].toUpperCase()
                    : 'U',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Perfil no encontrado.'));
          }
          
          final plan = ElenaBrain.generatePlan(user);

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
                Text(
                  'Tu plan para hoy (${plan.recommendedFastingProtocol})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                // 2. Anillo de Ayuno (Visualización Principal)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1), // Teal suave
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ventana de Alimentación',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${plan.recommendedEatingWindowStart} - ${plan.recommendedEatingWindowEnd}',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Descanso digestivo el resto del día',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Grilla de Métricas
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    // Card 1: Hidratación
                    _MetricCard(
                      icon: Icons.water_drop,
                      color: Colors.blueAccent,
                      value: '${plan.dailyWaterIntakeLitres} L',
                      label: 'Hidratación',
                      subtext: 'Aprox. ${(plan.dailyWaterIntakeLitres * 4).round()} vasos',
                    ),
                    // Card 2: Zona 2
                    _MetricCard(
                      icon: Icons.favorite,
                      color: Colors.redAccent,
                      value: '< ${plan.exerciseZoneHeartRate} ppm',
                      label: 'Zona 2 (MAF)',
                      subtext: 'Quema Grasa',
                    ),
                    // Card 3: Sueño / Cena
                    _MetricCard(
                      icon: Icons.bedtime,
                      color: Colors.indigoAccent,
                      value: plan.recommendedEatingWindowEnd,
                      label: 'Cena Límite',
                      subtext: '3h antes de dormir',
                    ),
                    // Card 4: Condicional (Glucosa o Peso Ideal)
                    if (plan.requiresGlucometer)
                      _MetricCard(
                        icon: Icons.bloodtype,
                        color: Colors.purpleAccent,
                        value: '< 100',
                        label: 'Glucosa Ayunas',
                        subtext: 'mg/dL Meta',
                      )
                    else
                         _MetricCard(
                        icon: Icons.directions_run,
                        color: Colors.green,
                        value: '45 min',
                        label: 'Movimiento',
                        subtext: 'Diario',
                      ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error cargando perfil: $e')),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? subtext;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.subtext,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtext != null) ...[
              const SizedBox(height: 2),
              Text(
                subtext!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
