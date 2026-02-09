import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../authentication/data/auth_repository.dart';
import '../../coaching/domain/weekly_plan.dart';
import '../../progress/domain/measurement_log.dart';
import '../../progress/data/progress_service.dart';
import '../../profile/presentation/widgets/bio_gauge_card.dart';
import '../../profile/data/user_repository.dart';
import '../../profile/domain/user_model.dart';
import '../../progress/presentation/widgets/measurement_bottom_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final progressService = ref.watch(progressServiceProvider);
    
    // We need user model for height/gender to calculate things if needed
    final userModelAsync = user != null ? ref.watch(userStreamProvider(user.uid)) : const AsyncValue<UserModel?>.loading();

    // Theme colors
    final backgroundColor = Colors.grey[50];
    final titleColor = Colors.black;
    final subtitleColor = Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: userModelAsync.when(
        data: (userModel) {
          if (userModel == null) return const Center(child: Text("Perfil no encontrado", style: TextStyle(color: Colors.black)));
          
          return SingleChildScrollView(
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
                          color: titleColor,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.outfit(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Metabolic Gauges Grid
                Text(
                  'Biocontrol (Tiempo Real)',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 16),
                _BioGaugeGrid(progressService: progressService, userModel: userModel),
                const SizedBox(height: 32),

                // 3. Body Measurements (Editable)
                _BodyMeasurementsSection(userModel: userModel, progressService: progressService),
                const SizedBox(height: 32),

                // 4. Active Plan
                Text(
                  'Tu Plan Actual',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 16),
                _ActivePlanCard(uid: user?.uid),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.black))),
      ),
    );
  }
}

class _BioGaugeGrid extends StatelessWidget {
  final ProgressService progressService;
  final UserModel userModel;

  const _BioGaugeGrid({required this.progressService, required this.userModel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MeasurementLog>>(
      stream: progressService.getHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final history = snapshot.data ?? [];
        final log = history.isNotEmpty ? history.last : null;

        if (log == null) {
          return const Center(child: Text("Sin datos registrados", style: TextStyle(color: Colors.grey)));
        }

        // Calculate metrics
        final bmi = log.calculateBmi(userModel.heightCm / 100);
        final weight = log.weight; // Not currently used in gauges but available
        
        // Use estimated visceral fat if null
        final visceral = log.visceralFat ?? MeasurementLog.estimateVisceralFat(
          waistCm: log.waistCircumference ?? 0, 
          isMale: userModel.gender == Gender.male
        );
        final bodyFat = log.bodyFatPercentage ?? 0;
        final muscle = log.muscleMassPercentage ?? 0;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            // 1. BMI Gauge
            BioGaugeCard(
              title: 'IMC',
              value: bmi,
              min: 10,
              max: 40,
              statusText: _getBmiStatus(bmi),
              statusColor: _getBmiColor(bmi),
              gradientColors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
              unit: '',
            ),
            // 2. Body Fat Gauge
            BioGaugeCard(
              title: '% Grasa',
              value: bodyFat,
              min: 5,
              max: 50,
              statusText: _getBodyFatStatus(bodyFat, userModel.gender),
              statusColor: _getBodyFatColor(bodyFat, userModel.gender),
              gradientColors: [Colors.green, Colors.yellow, Colors.orange, Colors.red],
              unit: '%',
            ),
            // 3. Muscle Gauge
            BioGaugeCard(
              title: '% Músculo',
              value: muscle,
              min: 20,
              max: 60,
              statusText: muscle > 30 ? 'Bueno' : 'Bajo',
              statusColor: muscle > 30 ? Colors.green : Colors.orange,
              gradientColors: [Colors.red, Colors.orange, Colors.yellow, Colors.green],
              unit: '%',
            ),
            // 4. Visceral Fat Gauge
            BioGaugeCard(
              title: 'Grasa Visceral',
              value: visceral ?? 0,
              min: 0,
              max: 20, 
              statusText: (visceral ?? 0) < 10 ? 'Saludable' : 'Alto',
              statusColor: (visceral ?? 0) < 10 ? Colors.green : Colors.red,
              gradientColors: [Colors.green, Colors.yellow, Colors.orange, Colors.red],
              unit: '',
            ),
          ],
        );
      },
    );
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) return 'Bajo Peso';
    if (bmi < 24.9) return 'Normal';
    if (bmi < 29.9) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24.9) return Colors.green;
    if (bmi < 29.9) return Colors.orange;
    return Colors.red;
  }

  String _getBodyFatStatus(double fat, Gender gender) {
    final isMale = gender == Gender.male;
    final healthyMax = isMale ? 20.0 : 28.0;
    if (fat == 0) return '--';
    if (fat < healthyMax) return 'Excelente';
    if (fat < healthyMax + 5) return 'Normal';
    return 'Alto';
  }

  Color _getBodyFatColor(double fat, Gender gender) {
    final isMale = gender == Gender.male;
    final healthyMax = isMale ? 20.0 : 28.0;
    if (fat == 0) return Colors.grey;
    if (fat < healthyMax) return Colors.green;
    if (fat < healthyMax + 5) return Colors.yellow;
    return Colors.red;
  }
}

class _BodyMeasurementsSection extends StatefulWidget {
  final UserModel userModel;
  final ProgressService progressService;

  const _BodyMeasurementsSection({required this.userModel, required this.progressService});

  @override
  State<_BodyMeasurementsSection> createState() => _BodyMeasurementsSectionState();
}

class _BodyMeasurementsSectionState extends State<_BodyMeasurementsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Medidas Corporales (Editable)',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showEditModal(context),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Editar'),
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTile('Cintura', '${widget.userModel.waistCircumferenceCm} cm'),
              Divider(color: Colors.grey[200], height: 1),
              _buildTile('Cuello', '${widget.userModel.neckCircumferenceCm} cm'),
              Divider(color: Colors.grey[200], height: 1),
               _buildTile('Cadera', '${widget.userModel.hipCircumferenceCm ?? '-'} cm'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(String label, String value) {
    return ListTile(
      title: Text(label, style: GoogleFonts.outfit(color: Colors.grey[600])),
      trailing: Text(value, style: GoogleFonts.outfit(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
      dense: true,
    );
  }

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MeasurementBottomSheet(
        user: widget.userModel,
        initialWeight: widget.userModel.currentWeightKg,
        initialWaist: widget.userModel.waistCircumferenceCm,
        initialNeck: widget.userModel.neckCircumferenceCm,
        initialHip: widget.userModel.hipCircumferenceCm,
      ),
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
        if (snapshot.hasError) return const Text('Error cargando plan', style: TextStyle(color: Colors.red));
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
           return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blueAccent),
                const SizedBox(width: 12),
                const Expanded(child: Text("Tu plan semanal se generará tras tu primer check-in.", style: TextStyle(color: Colors.black87))),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final protocol = data['protocol'] as String? ?? '16/8';
        final message = data['coachMessage'] as String? ?? 'Sin mensaje';
        final status = data['status'] as String? ?? 'initial';

        Color statusColor = Colors.teal;
        
        if (status == 'regression') {
          statusColor = Colors.orange;
        } else if (status == 'stagnation') {
           statusColor = Colors.blue; 
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.05),
                blurRadius: 10,
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
                        color: statusColor,
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
