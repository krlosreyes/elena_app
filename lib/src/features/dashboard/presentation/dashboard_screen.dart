import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/metabolic_hub_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../shared/domain/models/user_model.dart';
import '../../fasting/application/fasting_controller.dart';
import '../../fasting/presentation/widgets/fasting_end_dialog.dart';
import '../../nutrition/presentation/widgets/meal_registration_modal.dart';
import '../../profile/application/user_controller.dart';
import '../../sleep/application/circadian_controller.dart';
import '../../sleep/application/sleep_controller.dart';
import '../../tour/application/interactive_tour_service.dart';
import '../../tour/application/tour_controller.dart';
import '../application/dashboard_providers.dart';
import 'widgets/dynamic_header_widget.dart';
import 'widgets/elena_diagnosis_card.dart';
import 'widgets/metabolic_pentagon_grid.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  final GlobalKey _ayunoKey = GlobalKey();
  final GlobalKey _ejercicioKey = GlobalKey();
  final GlobalKey _nutricionKey = GlobalKey();
  final GlobalKey _hidratacionKey = GlobalKey();
  final GlobalKey _suenoKey = GlobalKey();

  bool _tourIsShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSleepTriggers();
    }
  }

  void _checkSleepTriggers() {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    final sleepStatus = ref.read(sleepStatusProvider).valueOrNull;
    final isResting = sleepStatus?.isResting ?? false;

    if (user != null) {
      ref
          .read(sleepControllerProvider.notifier)
          .checkWakeInteraction(user, isResting, context);
    }
  }

  void _triggerTourIfNeeded(UserModel? user) {
    if (user == null || !mounted || _tourIsShowing) return;

    final tourNotifier = ref.read(tourControllerProvider.notifier);
    if (tourNotifier.shouldStartTour(user)) {
      _tourIsShowing = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        tourNotifier.startTour();
        _startInteractiveTour(user);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.valueOrNull;
    final metabolicHub = ref.watch(metabolicHubProvider);
    final sleepStatus = ref.watch(sleepStatusProvider).valueOrNull;
    final isNightMode = sleepStatus?.isResting ?? false;

    ref.listen(metabolicHubProvider, (previous, current) {
      if (!current.isFeeding) return;

      final lastPromptedIndex = ref.read(lastAutomatedMealIndexProvider);

      for (int i = 0; i < current.mealMilestones.length; i++) {
        final milestone = current.mealMilestones[i];
        if (milestone.isReached &&
            current.actualMeals == i &&
            lastPromptedIndex < i) {
          ref.read(lastAutomatedMealIndexProvider.notifier).state = i;

          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            MealRegistrationModal.show(context, ref);
          });
          break;
        }
      }
    });

    ref.listen(mealModalTriggerProvider, (previous, next) {
      if (next == true && mounted) {
        // Reiniciamos el trigger inmediatamente
        ref.read(mealModalTriggerProvider.notifier).state = false;

        final hub = ref.read(metabolicHubProvider);
        final mealCount = hub.actualMeals;

        // Si ya registró todas las comidas esperadas, permitimos abrir por si quiere editar/ver
        // Pero si aún le faltan comidas de protocolo, validamos el tiempo del hito
        if (mealCount < hub.mealMilestones.length) {
          final nextMilestone = hub.mealMilestones[mealCount];
          if (!nextMilestone.isReached) {
            // No es hora aún. Mostramos advertencia y bloqueamos.
            final formattedTime = _formatRealTime(nextMilestone.absoluteHour);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'PROTOCOLO BLOQUEADO: PRÓXIMA COMIDA PROGRAMADA A LAS $formattedTime',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        }

        MealRegistrationModal.show(context, ref);
      }
    });

    // Listen to feeding window expiration
    ref.listen<AsyncValue<FastingState>>(fastingControllerProvider,
        (previous, next) {
      final state = next.value;
      if (state != null && state.isFeeding && !state.hasFeedingEndDialogShown) {
        final feedingHours = 24 - state.plannedHours;
        final totalFeedingDuration = Duration(hours: feedingHours);
        if (state.elapsed >= totalFeedingDuration) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) FastingEndDialog.show(context, ref, state);
          });
        }
      }
    });

    if (user != null) {
      _triggerTourIfNeeded(user);
      _checkPrepSleepWindow(user, isNightMode);
    }

    final circadianStatus = ref.watch(circadianStatusProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ColorFiltered(
      colorFilter: circadianStatus.isPrepPhase
          ? const ColorFilter.matrix([
              1.0,
              0,
              0,
              0,
              0,
              0,
              0.85,
              0,
              0,
              0,
              0,
              0,
              0.5,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ])
          : const ColorFilter.mode(Colors.white, BlendMode.multiply),
      child: Container(
        color: isNightMode ? const Color(0xFF020205) : const Color(0xFF0A0A0A),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (circadianStatus.isPrepPhase)
                          _buildPrepNotification(),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: getRelativeWidth(context, 0.06),
                            vertical: getRelativeHeight(context, 0.02),
                          ),
                          child: DynamicHeaderWidget(user: user),
                        ),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: getRelativeHeight(context, 0.04),
                        left: getRelativeWidth(context, 0.05),
                        right: getRelativeWidth(context, 0.05),
                      ),
                      child: Column(
                        children: [
                          const Spacer(flex: 1),
                          MetabolicPentagonGrid(
                            pilarKeys: {
                              0: _ayunoKey,
                              1: _ejercicioKey,
                              2: _nutricionKey,
                              3: _suenoKey,
                              4: _hidratacionKey,
                            },
                          ),
                          const Spacer(flex: 1),
                          SizedBox(height: getRelativeHeight(context, 0.05)),
                        ],
                      ),
                    ),
                  ),
                  if (metabolicHub.isInsistentMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: getRelativeWidth(context, 0.05)),
                        child: ElenaDiagnosisCard(
                          title: 'DÉFICIT HÍDRICO DETECTADO',
                          message:
                              'Umbral de hidratación crítico. Se requiere corrección inmediata de 250ml para optimizar transporte celular.',
                          onCorrection: () => ref
                              .read(metabolicHubProvider.notifier)
                              .addWater(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startInteractiveTour(UserModel user) {
    final tourService = InteractiveTourService(
      context: context,
      stepKeys: [
        _ayunoKey,
        _ejercicioKey,
        _nutricionKey,
        _hidratacionKey,
        _suenoKey,
      ],
      onComplete: () {
        ref.read(tourControllerProvider.notifier).completeTour();
      },
    );
    tourService.showTour();
  }

  void _checkPrepSleepWindow(UserModel user, bool isResting) {
    if (user.bedTime == null || isResting) return;

    final now = DateTime.now();
    final bedTimeToday = _parseTimeToToday(user.bedTime!);
    final prepWindowStart = bedTimeToday.subtract(const Duration(minutes: 60));

    if (now.isAfter(prepWindowStart) && now.isBefore(bedTimeToday)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPrepSleepBottomSheet(user);
      });
    }
  }

  DateTime _parseTimeToToday(String time) {
    final now = DateTime.now();
    try {
      String normalized = time.toUpperCase().trim();
      if (!normalized.contains(' ')) {
        if (normalized.endsWith('AM')) {
          normalized = normalized.replaceAll('AM', ' AM');
        } else if (normalized.endsWith('PM')) {
          normalized = normalized.replaceAll('PM', ' PM');
        }
      }

      final parsed = DateFormat("h:mm a").parse(normalized);
      return DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);
    } catch (e) {
      try {
        final parsed = DateFormat("HH:mm").parse(time.trim());
        return DateTime(
            now.year, now.month, now.day, parsed.hour, parsed.minute);
      } catch (e2) {
        final digits = time.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
        final hour = int.tryParse(digits[0]) ?? 0;
        final minute = (digits.length > 1) ? (int.tryParse(digits[1]) ?? 0) : 0;

        int finalHour = hour;
        if (time.toUpperCase().contains('PM') && hour < 12) {
          finalHour += 12;
        } else if (time.toUpperCase().contains('AM') && hour == 12) {
          finalHour = 0;
        }

        return DateTime(now.year, now.month, now.day, finalHour, minute);
      }
    }
  }

  void _showPrepSleepBottomSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Color(0xFFFF9D00), width: 1)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nightlight_round,
                color: Color(0xFFFF9D00), size: 40),
            const SizedBox(height: 16),
            Text(
              'PROTOCOLO DE SUEÑO',
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFFF9D00),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Charlie, iniciamos tu modo descanso? Luz tenue y fuera pantallas para optimizar melatonina.',
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(sleepControllerProvider.notifier)
                    .startSleepProtocol(user.uid);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9D00),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: const BeveledRectangleBorder(),
              ),
              child: const Text('ENTRAR EN MODO DESCANSO'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrepNotification() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9D00).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFFF9D00).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.nights_stay, color: Color(0xFFFF9D00), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'INICIANDO FASE DE PREPARACIÓN. ES MOMENTO DE DESCONECTAR PANTALLAS Y BAJAR LA INTENSIDAD LUMÍNICA.',
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFFF9D00),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRealTime(double decimalHour) {
    int hours = decimalHour.toInt() % 24;
    int minutes = ((decimalHour - decimalHour.toInt()) * 60).round();
    if (minutes == 60) {
      hours = (hours + 1) % 24;
      minutes = 0;
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} HS';
  }
}
