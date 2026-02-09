import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../authentication/data/auth_repository.dart';
import '../../../authentication/presentation/bloc/auth_controller.dart';
import '../../../coaching/domain/weekly_plan.dart';
import '../../../progress/domain/measurement_log.dart';
import '../../../progress/data/progress_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final progressService = ref.watch(progressServiceProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tu Perfil',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Usuario',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Metabolic Summary
            Text(
              'Resumen Metabólico',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _MetabolicSummaryCard(progressService: progressService),
            const SizedBox(height: 32),

            // 3. Active Plan
            Text(
              'Tu Plan Actual',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _ActivePlanCard(uid: user?.uid),
            
            const SizedBox(height: 32),
             _buildActionTile(
              context,
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              color: Colors.redAccent,
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionTile(BuildContext context, {
    required IconData icon, 
    required String label, 
    required Color color,
    required VoidCallback onTap
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _MetabolicSummaryCard extends StatelessWidget {
  final ProgressService progressService;

  const _MetabolicSummaryCard({required this.progressService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MeasurementLog?>(
      future: progressService.getLatest(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final log = snapshot.data;
        if (log == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.monitor_weight_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Aún no tienes registros'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pushNamed('progress'), // Go to log
                  child: const Text('Realizar Check-in'),
                ),
              ],
            ),
          );
        }

        // Calculate Body Fat if waist is available (Navy Method Approximation shown here or just simple data)
        // For now, we prefer showing what we have: Weight, Waist. 
        // Logic for BodyFat/Muscle could be complex if not pre-calculated in Log.
        // Assuming we show raw data for now.
        
        return Container(
          padding: const EdgeInsets.all(20),
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
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(context, 'Peso', '${log.weight}kg', Icons.monitor_weight),
              if (log.waistCircumference != null)
                _buildStat(context, 'Cintura', '${log.waistCircumference}cm', Icons.straighten),
              // Placeholder for fat/muscle if implemented in Log
              if (log.energyLevel != null)
                 _buildStat(context, 'Energía', '${log.energyLevel}/10', Icons.bolt),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  final String? uid;

  const _ActivePlanCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('plans')
          .doc('current')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error cargando plan');
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
           return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(child: Text("Tu plan semanal se generará tras tu primer check-in.")),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        // Basic deserialization for display
        final protocol = data['protocol'] as String? ?? '16/8';
        final message = data['coachMessage'] as String? ?? 'Sin mensaje';
        final status = data['status'] as String? ?? 'initial';

        Color statusColor = Colors.teal;
        if (status == 'regression') statusColor = Colors.orange;
        if (status == 'stagnation') statusColor = Colors.blue;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Protocolo Asignado: $protocol',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: statusColor[800],
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mensaje del Coach',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        uppercase: true,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"$message"',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
