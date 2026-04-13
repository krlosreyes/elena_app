import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/core/widgets/elena_header.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/circadian_clock.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart'; // IMPORTANTE
import '../domain/fasting_status.dart';

// --- PROVIDER CORREGIDO: DINÁMICO Y REACTIVO ---
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  // Escuchamos el authState para obtener el UID real del usuario logueado
  final authState = ref.watch(authStateProvider);
  
  final uid = authState.value?.id;
  
  if (uid == null) {
    return Stream.value(null);
  }
  
  return repository.watchUser(uid);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastingState = ref.watch(fastingProvider);
    final userAsync = ref.watch(currentUserStreamProvider);
    final engine = ref.watch(scoreEngineProvider);
    
    const double verticalSymmGap = 20.0; 

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error de Hardware: $err'))),
      data: (user) {
        // Si el usuario es null, significa que el Stream aún no encuentra el doc en Firestore
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.metabolicGreen),
                  SizedBox(height: 16),
                  Text("Sincronizando identidad...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final result = engine.calculateIMR(
          user,
          fastingHours: fastingState.isActive ? fastingState.duration.inSeconds / 3600 : 0, 
          weeklyAdherence: 0.85, 
          exerciseMin: 45, 
          sleepHours: 7.7,
          lastMealTime: user.profile.lastMealGoal ?? DateTime.now(),
        );

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const ElenaHeader(title: "Metamorfosis Real"),
                  
                  const SizedBox(height: verticalSymmGap),
                  
                  CircadianClock(
                    user: user,
                    fastingState: fastingState,
                    score: result.totalScore.toDouble(),
                    zone: result.zone,
                  ),
                  
                  const SizedBox(height: verticalSymmGap), 
                  
                  _buildMetabolicControlConsole(context, ref, fastingState),
                  
                  const SizedBox(height: 32),
                  _buildMetricsGrid(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildMetabolicControlConsole(BuildContext context, WidgetRef ref, FastingState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final remaining = state.timeRemainingForNextMilestone;
    
    final hours = twoDigits(remaining.inHours);
    final minutes = twoDigits(remaining.inMinutes.remainder(60));
    final seconds = twoDigits(remaining.inSeconds.remainder(60));
    
    final bool isActive = state.isActive;
    final color = isActive ? AppColors.metabolicGreen : Colors.orangeAccent;
    final actionColor = isActive ? Colors.redAccent : AppColors.metabolicGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(isDark ? 0.1 : 1.0)),
      ),
      child: Column(
        children: [
          Text(
            state.nextMilestoneLabel.toUpperCase(),
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$hours:$minutes:$seconds",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.border.withOpacity(0.05)),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isActive) {
                  ref.read(fastingProvider.notifier).stopFasting();
                } else {
                  ref.read(fastingProvider.notifier).startFasting();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(isActive ? Icons.stop_circle_outlined : Icons.play_circle_fill_rounded, size: 24),
              label: Text(
                isActive ? "FINALIZAR AYUNO" : "INICIAR AYUNO",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location == '/analysis') currentIndex = 1;
    if (location == '/profile') currentIndex = 2;

    return BottomNavigationBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.metabolicGreen,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0: context.go('/dashboard'); break;
          case 1: /* context.go('/analysis'); */ break; 
          case 2: context.go('/profile'); break; 
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: "Análisis"),
        BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined), label: "Perfil"),
      ],
    );
  }
}