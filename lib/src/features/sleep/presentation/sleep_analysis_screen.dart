import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/sleep_controller.dart';
import '../../../shared/domain/models/user_model.dart';
import '../../../features/profile/application/user_controller.dart';
import '../../sleep/application/circadian_controller.dart';
import '../../../core/theme/app_theme.dart';

class SleepAnalysisScreen extends ConsumerWidget {
  const SleepAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final sleepStatus = ref.watch(sleepStatusProvider).valueOrNull ??
        (isResting: false, lastSleepScore: 0.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: userAsync.when(
        data: (user) => user == null
            ? const Center(child: Text('Usuario no encontrado'))
            : _buildContent(context, ref, user, sleepStatus),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UserModel user,
      ({bool isResting, double lastSleepScore}) status) {
    final lastMealAsync = ref.watch(lastMealProvider);
    final lastMealTime = lastMealAsync.valueOrNull;
    final bool isDigesting = lastMealTime != null &&
        DateTime.now().difference(lastMealTime).inHours < 3;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDigesting && !status.isResting) _buildDigestionWarning(),
                const SizedBox(height: 10),
                _buildScoreHeader(status.lastSleepScore),
                const SizedBox(height: 30),
                _buildCircadianStatus(user),
                const SizedBox(height: 30),
                _buildActionCard(ref, user, status.isResting, context),
                const SizedBox(height: 30),
                _buildScientificInsights(),
                const SizedBox(height: 100), // Space for fab/overlap
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.black,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'ANÁLISIS CIRCADIANO',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        background: Opacity(
          opacity: 0.1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.indigoAccent.withValues(alpha: 0.15),
                  Colors.deepPurple.withValues(alpha: 0.1),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildScoreHeader(double score) {
    final color = score > 80
        ? AppTheme.primary
        : (score > 60 ? Colors.orange : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCORE DE REPARACIÓN',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusMessage(score),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                score.toInt().toString(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String statusMessage(double score) {
    if (score == 0) return 'PENDIENTE';
    if (score > 85) return 'RESTAURACIÓN TOTAL';
    if (score > 70) return 'RECUPERACIÓN ÓPTIMA';
    if (score > 50) return 'RECUPERACIÓN PARCIAL';
    return 'ESTRÉS METABÓLICO';
  }

  Widget _buildCircadianStatus(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ESTADO CIRCADIANO',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.indigoAccent,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildMetricRow('META DE DESCANSO', user.bedTime ?? '--:--',
            Icons.dark_mode_outlined, Colors.indigoAccent),
        const SizedBox(height: 12),
        _buildMetricRow('VENTANA METABÓLICA', '10:00 PM - 02:00 AM', Icons.bolt,
            Colors.amber),
        const SizedBox(height: 12),
        _buildMetricRow('INERCIA DEL SUEÑO', '90 MIN CYCLES', Icons.refresh,
            Colors.cyanAccent),
        const SizedBox(height: 12),
        _buildMetricRow('LATENCIA ESTIMADA', '20 MIN', Icons.hourglass_bottom,
            Colors.blueAccent),
      ],
    );
  }

  Widget _buildMetricRow(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      WidgetRef ref, UserModel user, bool isResting, BuildContext context) {
    final color = isResting ? Colors.cyanAccent : AppTheme.primary;

    return GestureDetector(
      onTap: () async {
        if (isResting) {
          // Trigger wakeup interaction logic
          await ref
              .read(sleepControllerProvider.notifier)
              .checkWakeInteraction(user, isResting, context);
        } else {
          // Start sleep protocol
          await ref
              .read(sleepControllerProvider.notifier)
              .startSleepProtocol(user.uid);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(
              isResting ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              color: color,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              isResting
                  ? 'ESTOY DESPIERTO'
                  : (ref.watch(circadianStatusProvider).isCriticalWindow
                      ? 'CONFIRMAR APAGADO BIOLÓGICO'
                      : 'INICIAR PROTOCOLO SUEÑO'),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isResting
                  ? 'FINALIZAR REGISTRO DE DESCANSO'
                  : 'ACTIVAR MODO REPARACIÓN',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScientificInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FUNDAMENTOS CIENTÍFICOS',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildInsightItem('Reparación Celular',
            'El sueño entre 10PM y 2AM maximiza la hormona de crecimiento y la regeneración mitocondrial.'),
        const SizedBox(height: 16),
        _buildInsightItem('Control Glucémico',
            'La deprivación de sueño aumenta la resistencia a la insulina en un 30% al día siguiente.'),
      ],
    );
  }

  Widget _buildInsightItem(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigestionWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INTERFERENCIA DIGESTIVA DETECTADA',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Digestión activa detectada. Tu temperatura central no bajará lo suficiente para el sueño profundo.',
                  style:
                      GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
