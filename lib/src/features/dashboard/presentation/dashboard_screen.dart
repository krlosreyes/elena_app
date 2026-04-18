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
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/exercise/presentation/exercise_input_sheet.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
import 'package:elena_app/src/features/adaptive/presentation/widgets/adaptive_suggestion_card.dart';
import 'package:elena_app/src/features/adaptive/application/adaptive_engine.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/dashboard/presentation/sleep_input_sheet.dart';
// SPEC-12: Composición Corporal Visible
import 'package:elena_app/src/features/profile/presentation/widgets/body_composition_card.dart';
// SPEC-13: IMR Explicado al Usuario
import 'package:elena_app/src/features/dashboard/presentation/widgets/imr_score_card.dart';
// SPEC-14: Objetivos del Usuario
import 'package:elena_app/src/features/goals/presentation/widgets/goals_dashboard_widget.dart';
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final fastingState = ref.watch(fastingProvider);
    final sleepState = ref.watch(sleepProvider);
    final hydrationState = ref.watch(hydrationProvider);
    final exerciseState = ref.watch(exerciseProvider);
    final nutritionState = ref.watch(nutritionProvider);
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
        
        final streakState = ref.watch(streakProvider);
        final engagement = ref.watch(engagementProvider);

        final result = engine.calculateIMR(
          user,
          fastingHours: realFastingHours, 
          weeklyAdherence: streakState.weeklyAdherence, 
          exerciseMin: exerciseState.todayMinutes.toDouble(), 
          sleepHours: sleepState.lastLog?.duration.inHours.toDouble() ?? 7.0,
          lastMealTime: fastingState.startTime ?? user.profile.lastMealGoal ?? DateTime.now(),
          nutritionScore: nutritionState.nutritionScore,
        );

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const ElenaHeader(title: "Metamorfosis Real"),
                  const SizedBox(height: 10), 

                  // BANNER DE ENGAGEMENT (SPEC-07)
                  if (engagement.level != EngagementLevel.neutro)
                    _buildEngagementBanner(engagement),
                  const SizedBox(height: 16), 

                  // MOTOR ADAPTATIVO (SPEC-08)
                  const AdaptiveSuggestionCard(),
                  const SizedBox(height: 16), 
                  
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
                        _buildWakeUpOverlay(context, ref, sleepState.isSaving),
                      if (fastingState.isWaitingForFastingEnd)
                        _buildFastingEndOverlay(context, ref, fastingState),
                      if (fastingState.isWaitingForFeedingEnd)
                        _buildFeedingEndOverlay(context, ref, fastingState),
                    ],
                  ),
                  
                  const SizedBox(height: 20), 

                  if (fastingState.metabolicAlert != null) ...[
                    _buildMetabolicAlertBanner(fastingState.metabolicAlert!),
                    const SizedBox(height: 12),
                  ],

                  // CONSOLAS COMPACTADAS
                  fastingState.startTime == null 
                      ? _buildFirstTimerWelcome(context, ref, fastingState.fastingProtocol)
                      : _buildMetabolicControlConsole(context, ref, fastingState),
                  
                  const SizedBox(height: 25),
                  // SPEC-13: IMR Score Card con desglose interactivo
                  IMRScoreCard(
                    result: result,
                    fastingHours: realFastingHours,
                    sleepHours: sleepState.lastLog?.duration.inHours.toDouble() ?? 0,
                    exerciseMin: exerciseState.todayMinutes.toDouble(),
                  ),
                  const SizedBox(height: 16),
                  // SPEC-12: Tarjeta de composición corporal
                  const BodyCompositionCard(),
                  const SizedBox(height: 20),

                  _buildSectionLabel("ESTADO DE PILARES"),
                  const SizedBox(height: 12),

                  _buildMetricsGrid(context, ref, sleepState, hydrationState, exerciseState),
                  const SizedBox(height: 20),

                  // SPEC-14: Objetivos del Usuario
                  const GoalsDashboardWidget(),
                  const SizedBox(height: 16),

                  // SPEC-15: Acceso al Road Map
                  _buildProgressCTA(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  // --- COMPONENTES PRIVADOS AJUSTADOS ---

  Widget _buildMetabolicControlConsole(BuildContext context, WidgetRef ref, FastingState state) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final displayTime = state.isActive ? state.duration : state.timeRemainingForNextMilestone;
    final color = state.isActive ? AppColors.metabolicGreen : (state.nearSleepWarning ? Colors.redAccent : Colors.orangeAccent);
    
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Padding reducido
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(state.isActive ? "OBJETIVO: ${state.fastingProtocol}" : "VENTANA NUTRICIONAL", 
            style: TextStyle(color: color.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          Text(state.isActive ? state.metabolicMilestone.toUpperCase() : "ABSORCIÓN", 
            style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 12),
        Text("${twoDigits(displayTime.inHours)}:${twoDigits(displayTime.inMinutes.remainder(60))}:${twoDigits(displayTime.inSeconds.remainder(60))}", 
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 38, fontFamily: 'monospace')), // Fuente un poco más pequeña
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 44, child: ElevatedButton.icon( // Altura reducida a 44
          onPressed: state.isSaving ? null : () => _showManualTimePicker(context, ref, isFeeding: false),
          style: ElevatedButton.styleFrom(
            backgroundColor: state.isActive ? Colors.redAccent : AppColors.metabolicGreen, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: state.isSaving 
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(state.isActive ? Icons.stop_circle_outlined : Icons.play_circle_outline, color: Colors.white, size: 20),
          label: Text(state.isActive ? "FINALIZAR AYUNO" : "INICIAR AYUNO", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        )),
      ]),
    );
  }

  Widget _buildFirstTimerWelcome(BuildContext context, WidgetRef ref, String protocol) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(20), // Compactado
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        const Icon(Icons.auto_awesome, color: AppColors.metabolicGreen, size: 20),
        const SizedBox(height: 8),
        const Text("LISTO PARA TU METAMORFOSIS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 44, child: ElevatedButton( // Altura reducida
          onPressed: () => ref.read(fastingProvider.notifier).startFasting(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.metabolicGreen, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text("INICIAR PRIMER AYUNO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        )),
      ]),
    );
  }

  // --- RESTO DE MÉTODOS (GRID Y NAV MANTIENEN SU DISEÑO) ---

  // SPEC-15: Botón de acceso al Road Map de Avance Personal
  Widget _buildProgressCTA(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/progress'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1ABC9C).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Text('📈', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ver mi Road Map',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Evolución IMR · Composición · Objetivos',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1ABC9C),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF1ABC9C).withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, WidgetRef ref, SleepState sleep, HydrationState hydration, ExerciseState exercise) {
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
        _buildExerciseCard(context, ref, exercise),
        _buildStatCard(context, "NUTRICIÓN", "1,420 kcal", Icons.restaurant_menu, Colors.orange, "+7 IMR"),
      ],
    );
  }

  Widget _buildSleepCard(BuildContext context, WidgetRef ref, SleepState state) {
    final log = state.lastLog;
    final bool hasLog = log != null;
    
    // Si no hay log, usamos valores de pilar 'vacío' pero visible
    final int hours = hasLog ? log.duration.inHours : 0;
    final int minutes = hasLog ? log.duration.inMinutes.remainder(60) : 0;
    final int gap = hasLog ? log.metabolicGap.inHours : 0;
    
    final color = !hasLog 
        ? Colors.indigoAccent.withOpacity(0.5)
        : (gap >= 3 ? AppColors.metabolicGreen : (gap >= 2 ? Colors.orangeAccent : Colors.redAccent));
        
    final imrTag = !hasLog ? "+0 IMR" : (hours >= 7 ? "+8 IMR" : "+4 IMR");

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const SleepInputSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(hasLog ? 0.4 : 0.1), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.nightlight_round, color: color, size: 18),
                if (state.isSaving)
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Text(imrTag, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Text("SUEÑO", style: TextStyle(fontSize: 8, color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.w800)),
            Text(hasLog ? "${hours}h ${minutes}m" : "Sin registro", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hasLog ? Colors.white : Colors.white.withOpacity(0.4))),
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
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(isReached ? 0.6 : 0.2), width: isReached ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.water_drop, color: color, size: 18),
                Text(pct, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Text("HIDRATACIÓN", style: TextStyle(fontSize: 8, color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.w800)),
            Text("${state.currentFormatted}L", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, WidgetRef ref, ExerciseState state) {
    final int minutes = state.todayMinutes;
    final color = minutes > 0 ? AppColors.metabolicGreen : Colors.teal;
    
    final double sExercise = (minutes / 60.0).clamp(0.0, 1.2);
    final double imrPoints = (sExercise * 7.5);
    final String imrTag = "+${imrPoints.toStringAsFixed(1)} IMR";

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const ExerciseInputSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(minutes > 0 ? 0.6 : 0.2), width: minutes > 0 ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.fitness_center, color: color, size: 18),
                if (state.isSaving)
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Text(imrTag, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Text("EJERCICIO", style: TextStyle(fontSize: 8, color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.w800)),
            Text("$minutes min", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              Icon(icon, color: color, size: 18),
              Text(imrTag, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 8, color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.w800)), 
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // --- OVERLAYS Y PICKERS SE MANTIENEN ---

  Widget _buildFastingEndOverlay(BuildContext context, WidgetRef ref, FastingState state) {
    return _buildBaseOverlay(
      context: context, icon: Icons.emoji_events_rounded, iconColor: AppColors.metabolicGreen,
      title: "¡META ALCANZADA!", subtitle: "Has completado tus ${state.targetHours}h de ayuno.",
      buttonLabel: "CONFIRMAR HITO REAL", isSaving: state.isSaving,
      onConfirm: () => _showManualTimePicker(context, ref, isFeeding: false),
    );
  }

  Widget _buildFeedingEndOverlay(BuildContext context, WidgetRef ref, FastingState state) {
    return _buildBaseOverlay(
      context: context, icon: Icons.timer_off_rounded, iconColor: Colors.orangeAccent,
      title: "FIN DE VENTANA", subtitle: "Tu ventana de alimentación ha terminado.",
      buttonLabel: "CONFIRMAR CIERRE", isSaving: state.isSaving,
      onConfirm: () => _showManualTimePicker(context, ref, isFeeding: true),
    );
  }

  Widget _buildWakeUpOverlay(BuildContext context, WidgetRef ref, bool isSaving) {
    return _buildBaseOverlay(
      context: context, icon: Icons.wb_sunny_rounded, iconColor: Colors.orangeAccent,
      title: "¿YA DESPERTASTE?", subtitle: "Elena detecta actividad matutina.",
      buttonLabel: "SÍ, DESPERTÉ", isSaving: isSaving,
      onConfirm: () => ref.read(sleepProvider.notifier).confirmManualWakeUp(),
    );
  }

  Widget _buildBaseOverlay({required BuildContext context, required IconData icon, required Color iconColor, required String title, required String subtitle, required String buttonLabel, required bool isSaving, required VoidCallback onConfirm}) {
    return Container(
      padding: const EdgeInsets.all(20), margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.98), borderRadius: BorderRadius.circular(30), border: Border.all(color: iconColor, width: 2), boxShadow: [BoxShadow(color: iconColor.withOpacity(0.2), blurRadius: 15)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 42, child: ElevatedButton(onPressed: isSaving ? null : onConfirm, style: ElevatedButton.styleFrom(backgroundColor: iconColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)))),
      ]),
    );
  }

  Future<void> _showManualTimePicker(BuildContext context, WidgetRef ref, {required bool isFeeding}) async {
    final DateTime now = DateTime.now();
    final fastingState = ref.read(fastingProvider);
    final Color primaryColor = isFeeding ? Colors.orangeAccent : AppColors.metabolicGreen;
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: now, firstDate: now.subtract(const Duration(days: 7)), lastDate: now.add(const Duration(days: 1)), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: primaryColor), dialogBackgroundColor: const Color(0xFF1E293B)), child: child!));
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: primaryColor), dialogBackgroundColor: const Color(0xFF1E293B)), child: child!));
    if (pickedTime == null) return;
    final DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    if (isFeeding) { ref.read(fastingProvider.notifier).confirmFeedingEnd(finalDateTime); } else { if (fastingState.isActive) { ref.read(fastingProvider.notifier).confirmManualFastingEnd(finalDateTime); } else { ref.read(fastingProvider.notifier).startFastingManual(finalDateTime); } }
  }

  Widget _buildMetabolicAlertBanner(String message) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.2))), child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)))]));
  }

  Widget _buildEngagementBanner(EngagementState engagement) {
    Color statusColor;
    IconData statusIcon;

    switch (engagement.level) {
      case EngagementLevel.excelente:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.stars_rounded;
        break;
      case EngagementLevel.bueno:
        statusColor = const Color(0xFF34D399);
        statusIcon = Icons.check_circle_rounded;
        break;
      case EngagementLevel.regular:
        statusColor = const Color(0xFFFBBF24);
        statusIcon = Icons.info_outline_rounded;
        break;
      case EngagementLevel.critico:
        statusColor = const Color(0xFFF87171);
        statusIcon = Icons.error_outline_rounded;
        break;
      case EngagementLevel.neutro:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPROMISO: ${engagement.status.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  engagement.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/analysis')) currentIndex = 1;
    if (location.startsWith('/profile')) currentIndex = 2;
    return BottomNavigationBar(backgroundColor: const Color(0xFF0F172A), selectedItemColor: AppColors.metabolicGreen, unselectedItemColor: Colors.grey.withOpacity(0.5), currentIndex: currentIndex, type: BottomNavigationBarType.fixed, onTap: (index) { if (index == 0) context.go('/dashboard'); if (index == 1) context.go('/analysis'); if (index == 2) context.go('/profile'); }, items: const [BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"), BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: "Análisis"), BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil")]);
  }
}