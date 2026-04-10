import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/core/widgets/elena_header.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/circadian_clock.dart';
import '../domain/fasting_status.dart';

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
    final engine = ref.watch(scoreEngineProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        final currentUser = user ?? UserModel(
          id: 'carlos_01',
          name: 'Carlos Reyes Ortega',
          age: 48,
          gender: 'M',
          weight: 85,
          height: 180,
          profile: CircadianProfile(
            wakeUpTime: DateTime.now(),
            sleepTime: DateTime.now(),
            firstMealGoal: DateTime.now(),
            lastMealGoal: DateTime.now(),
          ),
        );

        final result = engine.calculateIMR(
          currentUser,
          fastingHours: fastingState.duration.inSeconds / 3600, 
          weeklyAdherence: 0.85, 
          exerciseMin: 45, 
          sleepHours: 7.7,
          lastMealTime: fastingState.startTime ?? DateTime.now(),
        );

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const ElenaHeader(title: "Metamorfosis Real"),
                  const SizedBox(height: 20),
                  
                  CircadianClock(
                    user: currentUser,
                    fastingState: fastingState,
                    score: result.totalScore.toDouble(),
                    zone: result.zone,
                  ),
                  
                  const SizedBox(height: 20),
                  _buildCircadianInsight(context, fastingState),
                  const SizedBox(height: 32),
                  _buildMetricsGrid(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.metabolicGreen,
            onPressed: () => _showFastRegistration(context, ref, currentUser),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildCircadianInsight(BuildContext context, FastingState state) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(state.duration.inHours);
    final minutes = twoDigits(state.duration.inMinutes.remainder(60));
    final seconds = twoDigits(state.duration.inSeconds.remainder(60));

    return Column(
      children: [
        Text(
          state.circadianPhase.toUpperCase(), 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.metabolicGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "RESTAURACIÓN: $hours:$minutes:$seconds",
            style: const TextStyle(
              color: AppColors.metabolicGreen, 
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(context, "SUEÑO", "7h 42m", Icons.nightlight_round, Colors.indigo),
        _buildStatCard(context, "AGUA", "1.8L / 2.5L", Icons.water_drop, Colors.blue),
        _buildStatCard(context, "EJERCICIO", "45 min", Icons.fitness_center, Colors.teal),
        _buildStatCard(context, "NUTRICIÓN", "1,420 kcal", Icons.restaurant_menu, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(isDark ? 0.1 : 1.0)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      elevation: 10,
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: "Análisis"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
      ],
    );
  }

  void _showFastRegistration(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "REGISTRO METABÓLICO", 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.restaurant, color: AppColors.metabolicGreen),
              title: Text("Última Ingesta", style: Theme.of(context).textTheme.bodyLarge),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.of(context).pop(); 
                await ref.read(fastingProvider.notifier).startFasting();
              },
            ),
          ],
        ),
      ),
    );
  }
}