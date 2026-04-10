import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';

/// Escucha los cambios del usuario en tiempo real desde Firestore
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.watchUser('carlos_01');
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastingState = ref.watch(fastingProvider);
    final userAsync = ref.watch(currentUserStreamProvider);
    final engine = ScoreEngine();

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error de conexión: $err')),
      ),
      data: (user) {
        final currentUser = user ?? UserModel(
          id: 'carlos_01',
          name: 'Carlos Reyes Ortega',
          age: 48,
          gender: 'M',
          weight: 85,
          height: 180,
          waistCircumference: 96,
          neckCircumference: 38,
          profile: CircadianProfile(
            wakeUpTime: DateTime.now(),
            sleepTime: DateTime.now(),
            firstMealGoal: DateTime.now(),
            lastMealGoal: DateTime.now(),
          ),
        );

        final result = engine.calculateIMR(
          currentUser,
          fastingHours: fastingState.duration.inHours.toDouble(),
          weeklyAdherence: 0.85, 
          exerciseMin: 45, 
          sleepHours: 7.7,
          lastMealTime: fastingState.startTime ?? DateTime.now(),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildMetabolicClock(context, fastingState, result),
                const SizedBox(height: 10),
                _buildCircadianInsight(context, fastingState),
                const SizedBox(height: 32),
                _buildMetricsGrid(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showFastRegistration(context, ref, currentUser),
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: const Icon(Icons.menu, color: AppColors.metabolicGreen),
      title: const Text(
        "METABOLIC PRECISION", 
        style: TextStyle(color: AppColors.metabolicGreen, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Icon(Icons.account_circle_outlined, color: AppColors.metabolicGreen, size: 28),
        ),
      ],
    );
  }

  Widget _buildMetabolicClock(BuildContext context, FastingState fastingState, dynamic result) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 360, width: 360,
          child: CustomPaint(
            painter: CircadianClockPainter(
              fastingProgress: (fastingState.duration.inHours / 24).clamp(0.0, 1.0),
              phaseColor: _getPhaseColor(fastingState.phase),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("IMR SCORE", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
            Text("${result.totalScore}", style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 80, height: 1.1)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: AppColors.metabolicGreen, size: 18),
                Text(result.zone, style: const TextStyle(color: AppColors.metabolicGreen, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
        Positioned(top: 45, child: _buildClockIcon(Icons.wb_sunny, AppColors.circadianAmber)),
        Positioned(bottom: 45, child: _buildClockIcon(Icons.restaurant, AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCircadianInsight(BuildContext context, FastingState state) {
    return Column(
      children: [
        Text("Circadian Rhythm Active", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          "You are currently in the ${state.duration.inHours}th hour of metabolic restoration.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard("SLEEP", "7h 42m", Icons.nightlight_round, Colors.indigo),
        _buildStatCard("HYDRATION", "1.8L / 2.5L", Icons.water_drop, Colors.blue),
        _buildStatCard("EXERCISE", "45 min", Icons.fitness_center, Colors.teal),
        _buildStatCard("NUTRITION", "1,420 kcal", Icons.restaurant_menu, Colors.orange),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: "Analysis"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }

  void _showFastRegistration(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text("REGISTRO METABÓLICO", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 32),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.restaurant, color: AppColors.metabolicGreen)),
              title: const Text("Última Ingesta", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Inicia el cronómetro y sincroniza perfil"),
              onTap: () async {
                ref.read(fastingProvider.notifier).startFasting();
                final userRepo = ref.read(userRepositoryProvider);
                await userRepo.saveUser(user);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.water_drop, color: Colors.blue)),
              title: const Text("Hidratación", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Registrar 250ml de agua"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.white, shape: BoxShape.circle, 
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Color _getPhaseColor(FastingPhase phase) {
    switch (phase) {
      case FastingPhase.postAbsorption: return Colors.lightBlueAccent;
      case FastingPhase.transition: return Colors.orangeAccent;
      case FastingPhase.fatBurning: return AppColors.metabolicGreen;
      case FastingPhase.autophagy: return const Color(0xFF6366F1);
      default: return AppColors.metabolicGreen;
    }
  }
}

class CircadianClockPainter extends CustomPainter {
  final double fastingProgress;
  final Color phaseColor;

  CircadianClockPainter({required this.fastingProgress, required this.phaseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double outerRadius = size.width / 2 - 40;
    final double innerRadius = outerRadius - 25; 

    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    
    final outerBgPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawCircle(center, outerRadius, outerBgPaint);

    final dayNightPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF2D5A47).withOpacity(0.4),
          const Color(0xFFE2E8F0).withOpacity(0.1),
          const Color(0xFFE2E8F0).withOpacity(0.1),
          const Color(0xFF2D5A47).withOpacity(0.4),
        ],
        stops: const [0.0, 0.25, 0.75, 1.0],
      ).createShader(outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawArc(outerRect, -math.pi / 2, math.pi * 2, false, dayNightPaint);

    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    final innerBgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, innerRadius, innerBgPaint);

    if (fastingProgress > 0) {
      final activeFastPaint = Paint()
        ..color = phaseColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12;

      canvas.drawArc(innerRect, -math.pi / 2, math.pi * 2 * fastingProgress, false, activeFastPaint);
    }

    const double labelPadding = 22.0;
    _drawTimeLabel(canvas, center, outerRadius + labelPadding, "00:00", -math.pi / 2);
    _drawTimeLabel(canvas, center, outerRadius + labelPadding, "06:00", 0);
    _drawTimeLabel(canvas, center, outerRadius + labelPadding, "12:00", math.pi / 2);
    _drawTimeLabel(canvas, center, outerRadius + labelPadding, "18:00", math.pi);
  }

  void _drawTimeLabel(Canvas canvas, Offset center, double radius, String text, double angle) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    
    final offset = Offset(
      center.dx + radius * math.cos(angle) - tp.width / 2,
      center.dy + radius * math.sin(angle) - tp.height / 2,
    );
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}