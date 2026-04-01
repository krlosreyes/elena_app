import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/exceptions/exceptions.dart';
import '../../authentication/application/auth_controller.dart';
import '../../nutrition/application/food_provider.dart';
import '../application/biometric_provider.dart';
import '../application/user_controller.dart';
import '../data/user_repository.dart';

import '../domain/biometric_calculator.dart';
import 'widgets/profile_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORS & CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _neonGreen = Color(0xFF39FF14);
const Color _darkBg = Color(0xFF020205);
const Color _riskRed = Color(0xFFFF4444);
const Color _riskYellow = Color(0xFFFFD700);

// ─────────────────────────────────────────────────────────────────────────────
// BIOMETRIC PROFILE SCREEN — Main UI for Body Measurements & Analysis
// ─────────────────────────────────────────────────────────────────────────────

class BiometricProfileScreen extends ConsumerWidget {
  static const String routeName = '/profile/biometric';

  const BiometricProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAsync = ref.watch(biometricResultProvider);
    final currentUserAsync = ref.watch(currentUserStreamProvider);

    return biometricAsync.when(
      data: (biometricResult) {
        return currentUserAsync.when(
          data: (user) {
            if (user == null) {
              return const _ErrorScreen(message: 'Usuario no encontrado');
            }
            return _BiometricContent(
              user: user,
              biometricResult: biometricResult,
            );
          },
          loading: () => const _LoadingScreen(),
          error: (error, stack) => _ErrorScreen(message: 'Error: $error'),
        );
      },
      loading: () => const _LoadingScreen(),
      error: (error, stack) => _ErrorScreen(message: 'Error: $error'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _BiometricContent extends ConsumerWidget {
  final UserModel user;
  final BiometricResult biometricResult;

  const _BiometricContent({
    required this.user,
    required this.biometricResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─────────────────────────────────────────────────────────
              // HEADER: Title
              // ─────────────────────────────────────────────────────────
              _buildHeader(context),
              const SizedBox(height: 24),

              // ─────────────────────────────────────────────────────────
              // 1. AVATAR WITH HOTSPOTS (Top-Left positioning hint)
              // ─────────────────────────────────────────────────────────
              SizedBox(
                width: 270,
                height: 540,
                child: Stack(
                  children: [
                    // Profile Avatar with Interactive Hotspots
                    ProfileAvatar(
                      user: user,
                      biometricResult: biometricResult,
                      scale: 1.35,
                      onHotspotTap: (hotspotType) {
                        _handleHotspotTap(
                          context,
                          hotspotType,
                          user,
                        );
                      },
                    ),

                    // Metabolic Radar Indicator in Top-Left corner
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildMetabolicRadarIndicator(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ─────────────────────────────────────────────────────────
              // 2. WEIGHT & COMPOSITION CARD
              // ─────────────────────────────────────────────────────────
              _buildCompositionCard(),
              const SizedBox(height: 20),

              // ─────────────────────────────────────────────────────────
              // 3. BIOMETRIC METRICS TABLE
              // ─────────────────────────────────────────────────────────
              _buildMetricsTable(),
              const SizedBox(height: 20),

              // ─────────────────────────────────────────────────────────
              // 4. RISK ASSESSMENT CARD
              // ─────────────────────────────────────────────────────────
              _buildRiskCard(),
              const SizedBox(height: 30),

              // ─────────────────────────────────────────────────────────
              // 🧪 DIAGNOSTIC HUD: DATABASE VERIFICATION
              // ─────────────────────────────────────────────────────────
              _buildDiagnosticHUD(context, ref),
              const SizedBox(height: 30),

              // ─────────────────────────────────────────────────────────
              // 5. ACTION BUTTONS (Logout & Delete)
              // ─────────────────────────────────────────────────────────
              _buildSecurityButtons(context, ref),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Build screen header
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          'Perfil Biométrico',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ) ??
              const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Análisis corporal personalizado',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build minimal metabolic radar indicator for Top-Left
  Widget _buildMetabolicRadarIndicator() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _neonGreen,
          width: 2,
        ),
        color: _neonGreen.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          biometricResult.bmi.toStringAsFixed(1),
          style: const TextStyle(
            color: _neonGreen,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Build composition card (Weight, LBM, Body Fat %)
  Widget _buildCompositionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _neonGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Composición Corporal',
            style: TextStyle(
              color: _neonGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricColumn(
                label: 'Peso',
                value: '${user.currentWeightKg.toStringAsFixed(1)} kg',
              ),
              _MetricColumn(
                label: 'Masa Magra',
                value:
                    '${biometricResult.leanBodyMassKg.toStringAsFixed(1)} kg',
              ),
              _MetricColumn(
                label: 'Grasa Corporal',
                value:
                    '${biometricResult.bodyFatPercentage.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build metrics table (BMI, Waist-to-Height, Measurements)
  Widget _buildMetricsTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _neonGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perímetros',
            style: TextStyle(
              color: _neonGreen,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _TableHeader('Cuello'),
                  _TableHeader('Cintura'),
                  _TableHeader('Cadera'),
                ],
              ),
              TableRow(
                children: [
                  _TableCell(
                    '${user.neckCircumferenceCm?.toStringAsFixed(1) ?? "N/A"} cm',
                  ),
                  _TableCell(
                    '${user.waistCircumferenceCm?.toStringAsFixed(1) ?? "N/A"} cm',
                  ),
                  _TableCell(
                    '${user.hipCircumferenceCm?.toStringAsFixed(1) ?? "N/A"} cm',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build risk assessment card
  Widget _buildRiskCard() {
    final riskColor = biometricResult.imrRiskLevel == IMRRiskLevel.red
        ? _riskRed
        : biometricResult.imrRiskLevel == IMRRiskLevel.yellow
            ? _riskYellow
            : _neonGreen;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: riskColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Evaluación de Riesgo Metabólico',
                style: TextStyle(
                  color: _neonGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            biometricResult.riskDescription,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Ratio Cintura/Altura: ${biometricResult.waistToHeightRatio.toStringAsFixed(3)}',
              style: TextStyle(
                color: riskColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Diagnostic HUD for Database Verification
  Widget _buildDiagnosticHUD(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(masterFoodCountProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _neonGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: _neonGreen, size: 18),
              const SizedBox(width: 10),
              Text(
                'SYSTEM DIAGNOSTIC HUD',
                style: GoogleFonts.outfit(
                  color: _neonGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MASTER FOOD DB',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    countAsync.when(
                      data: (count) => Text(
                        '$count ITEMS DETECTED',
                        style: GoogleFonts.jetBrainsMono(
                          color: count > 0 ? _neonGreen : _riskRed,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => const Text('ERROR'),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(foodRepositoryProvider)
                        .seedInitialNutritionData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🟢 DATABASE SEEDED: 11 items created in Firestore',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Color(0xFF1B5E20),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error Seeding: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.storage, size: 16),
                label: const Text('RUN SEEDER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neonGreen.withValues(alpha: 0.1),
                  foregroundColor: _neonGreen,
                  side: const BorderSide(color: _neonGreen),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build security buttons (Logout & Delete Account)
  Widget _buildSecurityButtons(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _HUDSecurityButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              label: 'CERRAR SESIÓN',
              icon: Icons.logout_rounded,
              color: Colors.amber[700]!,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _HUDSecurityButton(
              onPressed: () => _showDeleteConfirmation(context, ref),
              label: 'ELIMINAR',
              icon: Icons.delete_forever_rounded,
              color: Colors.red[700]!,
              isUrgent: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.3), width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              'ELIMINAR CUENTA',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Text(
          'Esta acción es irreversible. Se borrarán permanentemente todos tus datos metabólicos, historial de ayuno y configuración de perfil. ¿Confirmas la desconexión total?',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white70,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ABORTAR',
              style: GoogleFonts.outfit(
                color: Colors.white24,
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (context.mounted) {
                final state = ref.read(authControllerProvider);
                if (state.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.error is AppException
                            ? (state.error as AppException).message
                            : state.error.toString(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('CONFIRMAR BORRADO'),
          ),
        ],
      ),
    );
  }

  /// Handle hotspot tap
  void _handleHotspotTap(
    BuildContext context,
    HotspotType hotspotType,
    UserModel user,
  ) {
    final measure = hotspotType == HotspotType.neck
        ? user.neckCircumferenceCm
        : hotspotType == HotspotType.waist
            ? user.waistCircumferenceCm
            : user.hipCircumferenceCm;

    final target = hotspotType == HotspotType.neck
        ? 35.0 // Example target
        : hotspotType == HotspotType.waist
            ? 80.0
            : 90.0;

    showHotspotBanner(
      context,
      type: hotspotType,
      currentMeasure: measure,
      targetMeasure: target,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: const Center(
        child: CircularProgressIndicator(
          color: _neonGreen,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: _neonGreen,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: _neonGreen,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;

  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _HUDSecurityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isUrgent;

  const _HUDSecurityButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isUrgent
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
