import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/widgets/elena_header.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/circadian_clock.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final fastingState = ref.watch(fastingProvider);
    final sleepState = ref.watch(sleepProvider);
    final hydrationState = ref.watch(hydrationProvider);
    final engine = ref.watch(scoreEngineProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Fallo de Hardware: $err'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(sleepProvider.notifier).updateSleepConsciousness();
        });

        final double realFastingHours = fastingState.isActive ? fastingState.duration.inSeconds / 3600 : 0;
        
        final result = engine.calculateIMR(
          user,
          fastingHours: realFastingHours, 
          weeklyAdherence: 0.85, 
          exerciseMin: 45, 
          sleepHours: sleepState.lastLog?.duration.inHours.toDouble() ?? 7.0,
          lastMealTime: fastingState.startTime ?? user.profile.lastMealGoal ?? DateTime.now(),
        );

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  const ElenaHeader(title: "Metamorfosis Real"),
                  const SizedBox(height: 15), 
                  
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.78, 
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: CircadianClock(
                              user: user,
                              fastingState: fastingState,
                              score: result.totalScore.toDouble(),
                              zone: result.zone,
                            ),
                          ),
                        ),
                      ),
                      if (sleepState.isWaitingForWakeUp)
                        _buildWakeUpOverlay(context, ref),
                    ],
                  ),
                  
                  const SizedBox(height: 25), 

                  if (fastingState.metabolicAlert != null) ...[
                    _buildMetabolicAlertBanner(fastingState.metabolicAlert!),
                    const SizedBox(height: 16),
                  ],

                  fastingState.startTime == null 
                      ? _buildFirstTimerWelcome(context, ref, fastingState.fastingProtocol)
                      : _buildMetabolicControlConsole(context, ref, fastingState),
                  
                  const SizedBox(height: 35),
                  _buildSectionLabel("ESTADO DE PILARES"),
                  const SizedBox(height: 16),
                  
                  _buildMetricsGrid(context, ref, sleepState, hydrationState),
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

  // --- COMPONENTES PRIVADOS ---

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3), 
          fontSize: 11, 
          letterSpacing: 2.0, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, WidgetRef ref, SleepState sleep, HydrationState hydration) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16, 
      mainAxisSpacing: 16,
      childAspectRatio: 1.55,
      children: [
        _buildSleepCard(context, ref, sleep),
        _buildHydrationCard(context, ref, hydration),
        _buildStatCard(context, "EJERCICIO", "45 min", Icons.fitness_center, Colors.teal, "+6 IMR"),
        _buildStatCard(context, "NUTRICIÓN", "1,420 kcal", Icons.restaurant_menu, Colors.orange, "+7 IMR"),
      ],
    );
  }

  Widget _buildSleepCard(BuildContext context, WidgetRef ref, SleepState state) {
    final log = state.lastLog;
    if (log == null) return const SizedBox();
    final gap = log.metabolicGap.inHours;
    final color = gap >= 3 ? AppColors.metabolicGreen : (gap >= 2 ? Colors.orangeAccent : Colors.redAccent);
    final imrTag = log.duration.inHours >= 7 ? "+8 IMR" : "+4 IMR";

    return GestureDetector(
      onTap: () {
        debugPrint("🌙 Trigger Manual: Despertar");
        ref.read(sleepProvider.notifier).confirmManualWakeUp();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.4), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.nightlight_round, color: color, size: 20),
                Text(imrTag, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Text("SUEÑO", style: TextStyle(fontSize: 9, color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text("${log.duration.inHours}h ${log.duration.inMinutes.remainder(60)}m", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text("BRECHA: ${gap}h", style: TextStyle(fontSize: 8, color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationCard(BuildContext context, WidgetRef ref, HydrationState state) {
    final bool isReached = state.isGoalReached;
    final color = isReached ? AppColors.metabolicGreen : Colors.blueAccent;
    final pct = "${(state.progressPercentage * 100).toStringAsFixed(0)}%";

    return GestureDetector(
      onTap: () => ref.read(hydrationProvider.notifier).addWater(0.250),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(isReached ? 0.6 : 0.2), width: isReached ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.water_drop, color: color, size: 20),
                if (state.isSaving) const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2))
                else Text(pct, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Text("HIDRATACIÓN", style: TextStyle(fontSize: 9, color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: "${state.currentFormatted}L"),
                  TextSpan(text: " / ${state.goalFormatted}L", style: TextStyle(fontSize: 11, color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, String imrTag) {
    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(imrTag, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.w800)), 
          const SizedBox(height: 2), 
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildWakeUpOverlay(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.98),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.metabolicGreen, width: 2),
        boxShadow: [BoxShadow(color: AppColors.metabolicGreen.withOpacity(0.2), blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.orangeAccent, size: 32),
          const SizedBox(height: 12),
          const Text("¿YA DESPERTASTE?", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () => ref.read(sleepProvider.notifier).confirmManualWakeUp(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.metabolicGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("SÍ, DESPERTÉ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetabolicAlertBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildMetabolicControlConsole(BuildContext context, WidgetRef ref, FastingState state) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final displayTime = state.isActive ? state.duration : state.timeRemainingForNextMilestone;
    final color = state.isActive ? AppColors.metabolicGreen : (state.nearSleepWarning ? Colors.redAccent : Colors.orangeAccent);
    
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24), 
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(28)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(state.isActive ? "OBJETIVO: ${state.fastingProtocol}" : "VENTANA NUTRICIONAL", style: TextStyle(color: color.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w900)),
          Text(state.isActive ? state.metabolicMilestone.toUpperCase() : "ABSORCIÓN", style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        Text("${twoDigits(displayTime.inHours)}:${twoDigits(displayTime.inMinutes.remainder(60))}:${twoDigits(displayTime.inSeconds.remainder(60))}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 44, fontFamily: 'monospace')),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(
          onPressed: () => state.isActive ? ref.read(fastingProvider.notifier).stopFasting() : ref.read(fastingProvider.notifier).startFasting(),
          style: ElevatedButton.styleFrom(backgroundColor: state.isActive ? Colors.redAccent : AppColors.metabolicGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          icon: Icon(state.isActive ? Icons.stop_circle : Icons.play_arrow, color: Colors.white),
          label: Text(state.isActive ? "FINALIZAR AYUNO" : "INICIAR AYUNO", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )),
      ]),
    );
  }

  Widget _buildFirstTimerWelcome(BuildContext context, WidgetRef ref, String protocol) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(28)),
      child: Column(children: [
        const Icon(Icons.auto_awesome, color: AppColors.metabolicGreen, size: 24),
        const SizedBox(height: 12),
        const Text("LISTO PARA TU METAMORFOSIS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
          onPressed: () => ref.read(fastingProvider.notifier).startFasting(),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.metabolicGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text("INICIAR PRIMER AYUNO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )),
      ]),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    
    int currentIndex = 0;
    if (location.startsWith('/analysis')) currentIndex = 1;
    if (location.startsWith('/profile')) currentIndex = 2;

    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: AppColors.metabolicGreen,
      unselectedItemColor: Colors.grey.withOpacity(0.5),
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) context.go('/dashboard');
        if (index == 1) context.go('/analysis');
        if (index == 2) context.go('/profile');
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: "Análisis"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
      ],
    );
  }
}