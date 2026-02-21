import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/data/auth_repository.dart';
import '../../progress/domain/measurement_log.dart';
import '../../progress/data/progress_service.dart';
import '../../profile/presentation/widgets/biometric_cards.dart';
import 'widgets/recomposition_progress_card.dart';
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
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                _BioControlSection(userModel: userModel),
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
                
                const SizedBox(height: 30), // Espacio separador
    
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    "Cerrar Sesión",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    // Lógica de cierre de sesión
                    await ref.read(authRepositoryProvider).signOut();
                    // El router se encargará del resto
                  },
                  tileColor: Colors.red.withValues(alpha: 0.05), // Fondo suave rojo
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
    
                const SizedBox(height: 20), // Margen final
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

class _BioControlSection extends ConsumerWidget {
  final UserModel userModel;

  const _BioControlSection({required this.userModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar el provider reactivo
    final historyAsync = ref.watch(userMeasurementsProvider);

    return historyAsync.when(
      data: (history) {
        final log = history.isNotEmpty ? history.last : null;

        if (log == null) {
          return const Center(
              child: Text("Sin datos registrados",
                  style: TextStyle(color: Colors.grey)));
        }

        // --- CALCULATIONS & LOGIC ---

        // 1. Weight & BMI
        final weight = log.weight;
        final bmi = log.calculateBmi(userModel.heightCm / 100);
        final bmiStatus = _getBmiStatus(bmi);
        final bmiColor = _getBmiColor(bmi);

        // 2. Body Fat
        final bodyFat = log.bodyFatPercentage ?? 0;
        final fatKg = (weight * bodyFat / 100);
        final fatStatus = _getBodyFatStatus(bodyFat, userModel.gender);
        final fatColor = _getBodyFatColor(bodyFat, userModel.gender);

        // 3. Muscle Mass
        final muscle = log.muscleMassPercentage ?? 0;
        final muscleKg = (weight * muscle / 100);

        // 4. Visceral Fat (1-20 scale)
        // Use estimated visceral fat if null
        final double visceral = log.visceralFat ??
            MeasurementLog.estimateVisceralFat(
                waistCm: log.waistCircumference ?? 0,
                isMale: userModel.gender == Gender.male) ?? 0.0;
        
        String visceralStatus = 'Normal';
        Color visceralColor = Colors.green;
        if (visceral >= 10) {
          visceralStatus = 'Alto';
          visceralColor = Colors.orange;
        }
        if (visceral >= 15) {
          visceralStatus = 'Peligro';
          visceralColor = Colors.red;
        }

        // 6. Basal Metabolism
        // Harris-Benedict Equation (Revised)
        double bmr = 0;
        if (userModel.gender == Gender.male) {
           bmr = 88.362 + (13.397 * weight) + (4.799 * userModel.heightCm) - (5.677 * userModel.age);
        } else {
           bmr = 447.593 + (9.247 * weight) + (3.098 * userModel.heightCm) - (4.330 * userModel.age);
        }

        // 7. Active Calories Goal (20% surplus of BMR or 500kcal fallback)
        final activeCaloriesGoal = bmr > 0 ? (bmr * 0.20) : 500.0;

        // 8. Ideal Weight (Recomposition - LBM based)
        // LBM = Weight * (1 - BodyFat/100)
        // Ideal Weight = LBM / (1 - TargetFat/100)
        double? idealWeightLbm;
        if (bodyFat > 0) {
           final lbm = weight * (1 - (bodyFat / 100));
           // Target Fat: Male 15%, Female 22%, Default 18%
           double targetFatPercent = 18.0;
           if (userModel.gender == Gender.male) targetFatPercent = 15.0;
           if (userModel.gender == Gender.female) targetFatPercent = 22.0;

           idealWeightLbm = lbm / (1 - (targetFatPercent / 100));
        }

        // Logic for old progress bar (explicit target weight from user model)
        final targetWeight = userModel.targetWeightKg;
        // Keep the old calculation variables just in case we want to support explicit targets too,
        // but user requested LBM method. Let's use IdealWeightProgressCard for LBM method primarily if bodyFat exists.
        
        return Column(
          children: [
            // ROW 1: Weight & BMI
            Row(
              children: [
                Expanded(
                  child: BiometricDetailCard(
                    title: 'PESO ACTUAL',
                    value: weight.toStringAsFixed(1),
                    unit: 'kg',
                    statusText: bmiStatus, // Weight status linked to BMI roughly
                    statusColor: bmiColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BiometricDetailCard(
                    title: 'IMC',
                    value: bmi.toStringAsFixed(1),
                    unit: 'pt',
                    statusText: bmiStatus,
                    statusColor: bmiColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ROW 2: Body Fat & Muscle
            Row(
              children: [
                Expanded(
                  child: BiometricDetailCard(
                    title: 'GRASA CORP.',
                    value: bodyFat.toStringAsFixed(1),
                    unit: '%',
                    subValue: '${fatKg.toStringAsFixed(1)} kg',
                    statusText: fatStatus,
                    statusColor: fatColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BiometricDetailCard(
                    title: 'MASA MAGRA',
                    value: (bodyFat > 0 ? (100 - bodyFat) : (log.muscleMassPercentage ?? 0)).toStringAsFixed(1),
                    unit: '%',
                    subValue: '${(weight * (bodyFat > 0 ? (100 - bodyFat) : (log.muscleMassPercentage ?? 0)) / 100).toStringAsFixed(1)} kg',
                    statusText: (bodyFat > 0 ? (100 - bodyFat) : (log.muscleMassPercentage ?? 0)) > 70 ? 'Bueno' : 'Bajo',
                    statusColor: (bodyFat > 0 ? (100 - bodyFat) : (log.muscleMassPercentage ?? 0)) > 70 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ROW 3: Basal Metabolism & Active Calories
             Row(
              children: [
                Expanded(
                  child: BiometricDetailCard(
                    title: 'METAB. BASAL',
                    value: bmr.toStringAsFixed(0),
                    unit: 'Kcal',
                    statusText: 'Reposo',
                    statusColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BiometricDetailCard(
                    title: 'META EJERCICIO',
                    value: activeCaloriesGoal.toStringAsFixed(0),
                    unit: 'Kcal',
                    statusText: 'Activas',
                    statusColor: Colors.orange,
                  ),
                ),
              ],
            ),
             const SizedBox(height: 12),

             // BARS: Visceral Fat
             BiometricBarCard(
               title: 'GRASA VISCERAL',
               valueLabel: visceral.toStringAsFixed(1), // 1-20
               progress: visceral / 20.0, // Scale to 20 max
               statusText: visceralStatus,
               statusColor: visceralColor,
               barColor: visceralColor,
               notes: 'Nivel saludable: 1 - 9',
             ),
             
             // Recomposition Progress Card
             if (bodyFat > 0) ...[
               const SizedBox(height: 12),
               RecompositionProgressCard(
                 currentWeight: weight,
                 currentFatPercentage: bodyFat,
                 targetFatPercentage: userModel.targetFatPercentage,
                 targetLBM: userModel.targetLBM,
               ),
             ] else if (targetWeight != null) ...[
               const SizedBox(height: 12),
               // Fallback to explicit target if no body fat data for Recomposition calculation
               BiometricBarCard(
                 title: 'PROGRESO PESO (OBJETIVO MANUAL)',
                 valueLabel: '${weight.toStringAsFixed(1)} / ${targetWeight.toStringAsFixed(1)} kg',
                 progress: (userModel.startWeightKg != null && (userModel.startWeightKg! - targetWeight).abs() > 0)
                     ? (userModel.startWeightKg! - weight).abs() / (userModel.startWeightKg! - targetWeight).abs()
                     : 0,
                 statusText: 'Meta Manual',
                 statusColor: Colors.blueAccent,
                 barColor: Colors.blueAccent,
                 notes: 'Calcula tu grasa corporal para una meta más precisa.',
               ),
             ]
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error: $e",
          style: const TextStyle(color: Colors.red))),
    );
  }

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) return 'Bajo Peso';
    if (bmi < 24.9) return 'Normal';
    if (bmi < 29.9) return 'Sobrepeso';
    if (bmi < 34.9) return 'Obesidad I';
    return 'Obesidad II+';
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
                color: Colors.black.withValues(alpha: 0.05),
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
            border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.05),
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
                  color: statusColor.withValues(alpha: 0.1),
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
