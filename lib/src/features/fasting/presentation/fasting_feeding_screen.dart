import 'dart:async';
import 'dart:ui';

import 'package:elena_app/src/shared/presentation/widgets/circadian_wheel_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/circadian_phase_provider.dart';
import '../../../core/providers/metabolic_hub_provider.dart';
import '../../../core/science/metabolic_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/blueprint_grid.dart';
import '../../../core/widgets/elena_header.dart';
import '../../../domain/logic/elena_brain.dart';
import '../../authentication/application/auth_controller.dart'
    show authControllerProvider;
import '../../health/data/health_repository.dart';
import '../../nutrition/presentation/widgets/meal_review_sheet.dart';
import '../../profile/application/user_controller.dart';
import '../application/fasting_controller.dart';
import '../domain/fasting_stage.dart';
import 'widgets/fasting_end_dialog.dart';
import 'widgets/sos_button_widget.dart';

class FastingFeedingScreen extends ConsumerStatefulWidget {
  const FastingFeedingScreen({super.key});

  @override
  ConsumerState<FastingFeedingScreen> createState() =>
      _FastingFeedingScreenState();
}

class _FastingFeedingScreenState extends ConsumerState<FastingFeedingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final fastingStateAsync = ref.watch(fastingControllerProvider);
    final userAsync = ref.watch(currentUserStreamProvider);
    final elenaUser = userAsync.value;
    final recommendedPlan = elenaUser != null
        ? ElenaBrain.generateHealthPlan(elenaUser)
        : null;

    // Trigger Meal Registration Modal if flag is set (Global Trigger)
    ref.listen(mealModalTriggerProvider, (previous, next) {
      if (next == true) {
        final hub = ref.read(metabolicHubProvider);
        final mealsLogged = hub.actualMeals;

        // Validar si es tiempo de la siguiente comida (Solo si ya hubo una ruptura)
        if (mealsLogged > 0 && mealsLogged < hub.mealMilestones.length) {
          final nextMeal = hub.mealMilestones[mealsLogged];
          if (!nextMeal.isReached) {
            final timeStr = _formatRealTime(nextMeal.absoluteHour);
            ref.read(nextMealTimeWarningProvider.notifier).state =
                "PROTOCOLO ACTIVADO: TU ${nextMeal.label} ESTÁ PREVISTA A LAS $timeStr. MANTÉN EL AYUNO INTER-COMIDAS.";

            // Reset del trigger para evitar re-apertura automática
            Future.delayed(Duration.zero, () {
              ref.read(mealModalTriggerProvider.notifier).state = false;
            });
            return;
          }
        }

        // Navegar a la pantalla de Nutrición Metabólica
        ref.read(mealModalTriggerProvider.notifier).state = false;
        context.go('/nutrition_log');
      }
    });

    // Trigger Meal Review Sheet
    ref.listen(mealReviewTriggerProvider, (previous, next) {
      if (next == true) {
        _showMealReviewSheet(context, ref);
        ref.read(mealReviewTriggerProvider.notifier).state = false;
      }
    });

    // Listen to feeding window expiration (Changes during session)
    ref.listen<AsyncValue<FastingState>>(fastingControllerProvider, (
      previous,
      next,
    ) {
      final state = next.value;
      if (state != null && state.isFeeding && !state.hasFeedingEndDialogShown) {
        final feedingHours = 24 - state.plannedHours;
        final totalFeedingDuration = Duration(hours: feedingHours);
        if (state.elapsed >= totalFeedingDuration) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) FastingEndDialog.show(context, ref, state);
          });
        }
      }
    });

    // Handle initial expiration on app launch
    final currentState = fastingStateAsync.value;
    if (currentState != null &&
        currentState.isFeeding &&
        !currentState.hasFeedingEndDialogShown) {
      final feedingHours = 24 - currentState.plannedHours;
      final totalFeedingDuration = Duration(hours: feedingHours);
      if (currentState.elapsed >= totalFeedingDuration) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) FastingEndDialog.show(context, ref, currentState);
        });
      }
    }

    // Listen to next meal time warning and show a snackbar
    ref.listen<String?>(nextMealTimeWarningProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
        // Reset immediately so it can be shown again if triggered
        Future.delayed(Duration.zero, () {
          if (mounted) {
            ref.read(nextMealTimeWarningProvider.notifier).state = null;
          }
        });
      }
    });

    ref.listen<AsyncValue<FastingState>>(fastingControllerProvider, (
      previous,
      next,
    ) async {
      if (next.hasValue && next.value != null) {
        final state = next.value!;

        // Smart Default Initialization
        if (recommendedPlan != null) {
          final recParts = recommendedPlan.protocol.split(':');
          final recHours = int.tryParse(recParts[0]) ?? 16;

          if (state.plannedHours == 16 && recHours != 16) {
            ref.read(fastingControllerProvider.notifier).setProtocol(recHours);
          }
        }

        // 🏁 TRANSICIÓN A ALIMENTACIÓN: Reactiva y Atómica
        if (previous?.value?.isFasting == true && state.isFeeding) {
          debugPrint(
            "⚡ [FastingScreen] Transición a FEEDING detectada (Reactive).",
          );

          final uid = ref
              .read(authControllerProvider.notifier)
              .currentUser
              ?.uid;
          if (uid != null) {
            try {
              // 1. Telemetría Pura: Validar si hay comida previa hoy
              // Await direct future to decide UI path
              final log = await ref.read(todayLogProvider(uid).future);

              if (!mounted) return;

              if (log != null && log.mealEntries.isNotEmpty) {
                debugPrint(
                  "🥗 [ReactiveTransition] Ruido detectado. Review Sheet.",
                );
                if (context.mounted) _showMealReviewSheet(context, ref);
              } else {
                debugPrint(
                  "🥗 [ReactiveTransition] Telemetría limpia. Nutrición Metabólica.",
                );
                if (context.mounted) context.go('/nutrition_log');
              }
            } catch (e) {
              debugPrint("⚠️ Error en Transición Reactiva: $e");
              if (context.mounted) context.go('/nutrition_log');
            }
          }
        }
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B0B0B),
      body: fastingStateAsync.when(
        data: (state) {
          return Stack(
            children: [
              BlueprintGrid(
                child: state.isFasting
                    ? _FastingView(
                        state: state,
                        recommendedProtocol: recommendedPlan?.protocol,
                      )
                    : _FeedingView(
                        state: state,
                        recommendedProtocol: recommendedPlan?.protocol,
                      ),
              ),
              // Reactive Overlay: Reemplaza showDialog
              if (state.isFasting &&
                  state.elapsed >= Duration(hours: state.plannedHours) &&
                  !state.hasCompletedConfirmationShown &&
                  !state.isContinuingPastGoal)
                GoalReachedOverlay(state: state),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Error cargando estado de ayuno',
                style: TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: () {
                  ref.invalidate(fastingControllerProvider);
                },
                child: const Text(
                  'REINTENTAR',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMealReviewSheet(BuildContext context, WidgetRef ref) {
    if (!mounted) return;

    final user = ref.read(authControllerProvider.notifier).currentUser;
    if (user != null) {
      MealReviewSheet.show(context, user.uid);
    }
  }
}

class _FastingView extends ConsumerWidget {
  final FastingState state;
  final String? recommendedProtocol;

  const _FastingView({required this.state, this.recommendedProtocol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    final hub = ref.watch(metabolicHubProvider);

    final isProgrammed = state.startTime == null;
    final plannedDuration = Duration(hours: state.plannedHours);

    // 1. Obtener la duración EN VIVO desde el estado
    final liveDuration = isProgrammed ? Duration.zero : state.elapsed;

    // 2. Calcular el estado basado en la duración EN VIVO
    final currentStage = FastingStage.getStageForDuration(liveDuration);
    final currentZone = MetabolicEngine.calculateZone(liveDuration);
    final zoneColor = currentZone.color;

    String displayStr;
    String statusLabel;

    if (state.isContinuingPastGoal) {
      displayStr = _formatDuration(liveDuration);
      statusLabel = 'LLEVAS:';
    } else {
      final remaining = plannedDuration - liveDuration;
      final displayDuration = remaining.isNegative ? Duration.zero : remaining;
      displayStr = _formatDuration(
        isProgrammed ? plannedDuration : displayDuration,
      );
      statusLabel = isProgrammed ? 'PROGRAMADO' : 'QUEDAN:';
    }
    final circadianLabel = ref.watch(circadianWindowLabelProvider);
    final subLabel = isProgrammed
        ? 'POR INICIAR'
        : '${currentStage.name} · $circadianLabel';

    // 3. Progreso en vivo para el círculo

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            children: [
              if (user != null) ElenaHeader(title: 'AYUNO', user: user),
              const SizedBox(height: 64),
              Center(
                child: CircadianWheelWidget(
                  context: hub,
                  durationStr: displayStr,
                  statusLabel: statusLabel,
                  subLabel: subLabel,
                  zoneColor: zoneColor,
                ),
              ),
              const SizedBox(height: 48),
              _buildFastingCard(currentStage, hub, liveDuration),
              const SizedBox(height: 32),
              _ProtocolSelector(
                currentProtocol:
                    "${state.plannedHours}:${24 - state.plannedHours}",
                recommendedProtocol: recommendedProtocol,
              ),
              const SizedBox(height: 32),
              _buildActions(context, ref),
              SosButtonWidget(fastingElapsed: state.elapsed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFastingCard(
    FastingStage stage,
    MetabolicContext hub,
    Duration elapsed,
  ) {
    final estimatedGlucose = hub.estimatedGlucose;
    final estimatedKetones = hub.estimatedKetones;
    final currentZone = MetabolicEngine.calculateZone(elapsed);
    final zoneColor = currentZone.color;
    final nextThreshold = currentZone.nextZoneThresholdHours;

    // Countdown to next zone
    String? countdownLabel;
    if (nextThreshold != null) {
      final elapsedHours = elapsed.inMinutes / 60.0;
      final remainingHours = nextThreshold - elapsedHours;
      if (remainingHours > 0) {
        final h = remainingHours.floor();
        final m = ((remainingHours - h) * 60).round();
        countdownLabel =
            'PRÓXIMA FASE EN ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} HS';
      }
    }

    // survivalMode: mostrar banner de advertencia en lugar de card normal
    if (currentZone.isCritical) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: zoneColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: zoneColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: zoneColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MODO SUPERVIVENCIA',
                    style: GoogleFonts.robotoMono(
                      color: zoneColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Llevas más de 72 horas en ayuno. Esto es estrés metabólico extremo. Consulta a tu médico antes de continuar.',
                    style: GoogleFonts.publicSans(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: zoneColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: zoneColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bolt, color: zoneColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.name.toUpperCase(),
                      style: GoogleFonts.robotoMono(
                        color: zoneColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stage.description,
                      style: GoogleFonts.publicSans(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (countdownLabel != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: zoneColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                countdownLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  color: zoneColor.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'GLUCOSA (Est)',
                  '${estimatedGlucose.toStringAsFixed(0)} mg/dL',
                  Icons.bloodtype,
                  Colors.redAccent,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              Expanded(
                child: _buildMetric(
                  'CETONAS (Est)',
                  '${estimatedKetones.toStringAsFixed(1)} mmol/L',
                  Icons.fireplace,
                  Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.robotoMono(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    final isProgrammed = state.startTime == null;

    if (isProgrammed) {
      return ElevatedButton(
        // Fix: must pass 'hours' parameter to startFast()
        onPressed: () => ref
            .read(fastingControllerProvider.notifier)
            .startFast(hours: state.plannedHours),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'INICIAR AYUNO',
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final bool? confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.surface,
                title: Text(
                  '¿VAS A TERMINAR TU AYUNO?',
                  style: GoogleFonts.robotoMono(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('NO'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'SÍ, TERMINAR',
                      style: TextStyle(color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              ref.read(mealModalTriggerProvider.notifier).state = false;
              await ref.read(fastingControllerProvider.notifier).endFasting();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.white10),
            ),
          ),
          child: Text(
            'TERMINAR AYUNO',
            style: GoogleFonts.robotoMono(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _handleEditStartTime(context, ref),
          icon: const Icon(
            Icons.edit_calendar_outlined,
            size: 18,
            color: Colors.white38,
          ),
          label: Text(
            'EDITAR INICIO',
            style: GoogleFonts.robotoMono(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEditStartTime(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final initialDateTime = state.startTime ?? now;

    // 1. Seleccionar Fecha
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: now.subtract(
        const Duration(days: 7),
      ), // Permitir hasta una semana atrás
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.black,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !context.mounted) return;

    // 2. Seleccionar Hora
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.black,
              surface: AppTheme.surface,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!context.mounted) return;

    if (pickedTime != null) {
      final newStartTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Validamos que no sea en el futuro absoluto (por segundos de diferencia)
      if (newStartTime.isAfter(now)) {
        // Si el usuario accidentalmente pone una hora futura por pocos segundos/minutos,
        // lo aceptamos pero lo limitamos a "now" para evitar duraciones negativas.
        await ref.read(fastingControllerProvider.notifier).updateStartTime(now);
      } else {
        await ref
            .read(fastingControllerProvider.notifier)
            .updateStartTime(newStartTime);
      }
    }
  }
}

class GoalReachedOverlay extends ConsumerWidget {
  final FastingState state;

  const GoalReachedOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.8),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars,
                  color: AppTheme.primary,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '¡META COMPLETADA!',
                style: GoogleFonts.robotoMono(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Completaste tu meta de ${state.plannedHours} horas con éxito. ¿Deseas seguir ayunando o abrir tu ventana de alimentación?',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  ref.read(fastingControllerProvider.notifier).endFasting();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'TERMINAR Y COMER',
                  style: GoogleFonts.robotoMono(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref
                      .read(fastingControllerProvider.notifier)
                      .setContinuingPastGoal(true);
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  'EXTENDER AYUNO',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedingView extends ConsumerWidget {
  final FastingState state;
  final String? recommendedProtocol;

  const _FeedingView({required this.state, this.recommendedProtocol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    final hub = ref.watch(metabolicHubProvider);
    final circadianLabel = ref.watch(circadianWindowLabelProvider);

    final feedingHours = 24 - state.plannedHours;
    final totalFeedingDuration = Duration(hours: feedingHours);
    final feedingElapsed = state.elapsed;
    final remaining = totalFeedingDuration - feedingElapsed;
    final displayDuration = remaining.isNegative ? Duration.zero : remaining;

    // Live progress for feeding window (normalized to 24h for the circle)

    final log = user != null
        ? ref.watch(todayLogProvider(user.uid)).valueOrNull
        : null;
    final hasMeals =
        state.hasInitialMealBeenLogged ||
        (log?.mealEntries.isNotEmpty ?? false);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            children: [
              if (user != null)
                ElenaHeader(title: 'VENTANA DE ALIMENTACIÓN', user: user),
              const SizedBox(height: 32),
              Center(
                child: CircadianWheelWidget(
                  context: hub,
                  durationStr: _formatDuration(displayDuration),
                  statusLabel: 'VENTANA DE',
                  subLabel: circadianLabel,
                  isRestingWarning: state.isRestingWarning,
                ),
              ),
              const SizedBox(height: 48),
              _ProtocolSelector(
                currentProtocol:
                    "${state.plannedHours}:${24 - state.plannedHours}",
                recommendedProtocol: recommendedProtocol,
                readOnly:
                    true, // No cambiar protocolo durante alimentación activa
              ),
              const SizedBox(height: 16),
              _buildSequenceCard(),
              const SizedBox(height: 48),
              if (hasMeals) ...[
                Builder(
                  builder: (context) {
                    final nextMealIndex = hub.actualMeals;
                    final bool isNextMealLocked =
                        nextMealIndex > 0 &&
                        nextMealIndex < hub.mealMilestones.length &&
                        !hub.mealMilestones[nextMealIndex].isReached;

                    final bool isMaxMeals =
                        nextMealIndex >= hub.mealMilestones.length;
                    if (isMaxMeals) return const SizedBox.shrink();

                    final nextMealLabel = isNextMealLocked
                        ? 'PRÓXIMA: ${_formatRealTime(hub.mealMilestones[nextMealIndex].absoluteHour)}'
                        : 'REGISTRAR OTRA COMIDA';

                    return ElevatedButton.icon(
                      onPressed: isNextMealLocked
                          ? null
                          : () {
                              ref
                                      .read(mealModalTriggerProvider.notifier)
                                      .state =
                                  false;
                              context.go('/nutrition_log');
                            },
                      icon: Icon(
                        isNextMealLocked ? Icons.lock_clock : Icons.add,
                        size: 20,
                        color: isNextMealLocked
                            ? Colors.white24
                            : AppTheme.primary,
                      ),
                      label: Text(
                        nextMealLabel,
                        style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.bold,
                          color: isNextMealLocked
                              ? Colors.white24
                              : AppTheme.primary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isNextMealLocked
                            ? Colors.white.withValues(alpha: 0.02)
                            : Colors.white10,
                        foregroundColor: AppTheme.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isNextMealLocked
                                ? Colors.white12
                                : AppTheme.primary,
                            width: 0.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
              _buildActions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              '¿VAS A INICIAR TU AYUNO?',
              style: GoogleFonts.robotoMono(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Text(
              'Esto cerrará tu ventana de alimentación actual y comenzará un nuevo ciclo de ${state.plannedHours} horas.',
              style: GoogleFonts.publicSans(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCELAR'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'SÍ, INICIAR',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          await ref
              .read(fastingControllerProvider.notifier)
              .startFast(hours: state.plannedHours);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        'INICIAR AYUNO',
        style: GoogleFonts.robotoMono(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSequenceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTRATEGIA DE INGESTA',
            style: GoogleFonts.robotoMono(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white38, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mantén un espacio de 3.5 a 4 horas entre ingestas para optimizar la sensibilidad a la insulina.',
                  style: GoogleFonts.publicSans(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProtocolSelector extends ConsumerWidget {
  final String currentProtocol;
  final String? recommendedProtocol;
  final bool readOnly;

  const _ProtocolSelector({
    required this.currentProtocol,
    this.recommendedProtocol,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (readOnly) {
      return Opacity(
        opacity: 0.6,
        child: _buildSelector(context, ref, isEditable: false),
      );
    }
    return _buildSelector(context, ref, isEditable: true);
  }

  Widget _buildSelector(
    BuildContext context,
    WidgetRef ref, {
    required bool isEditable,
  }) {
    final state = ref.watch(fastingControllerProvider).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final protocols = [
      {'val': '12:12', 'note': 'Ritmo Circadiano Base'},
      {'val': '14:10', 'note': 'Mantenimiento Metabólico'},
      {'val': '16:8', 'note': 'Optimización de Autofagia'},
      {'val': '18:6', 'note': 'Flexibilidad Metabólica Avanzada'},
      {'val': '20:4', 'note': 'Reseteo Hormonal Profundo'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROTOCOLO METABÓLICO',
                style: GoogleFonts.robotoMono(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (recommendedProtocol != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'RECOMENDADO: $recommendedProtocol',
                    style: GoogleFonts.robotoMono(
                      color: AppTheme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: protocols.length,
            itemBuilder: (context, index) {
              final p = protocols[index];
              final bool isSelected = currentProtocol == p['val'];
              final bool isRecommended = recommendedProtocol == p['val'];

              return GestureDetector(
                onTap: !isEditable
                    ? null
                    : () {
                        final int newHours = int.parse(p['val']!.split(':')[0]);
                        final currentHours = int.parse(
                          currentProtocol.split(':')[0],
                        );

                        // Solo permitimos avanzar o mantener si estamos extendiendo
                        if (state.isContinuingPastGoal &&
                            newHours < currentHours) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selecciona un objetivo mayor para continuar extendiendo tu ayuno.',
                              ),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                          return;
                        }

                        ref
                            .read(fastingControllerProvider.notifier)
                            .setProtocol(newHours);
                      },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : AppTheme.surface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : (isRecommended
                                ? AppTheme.primary.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p['val']!,
                        style: GoogleFonts.robotoMono(
                          color: isSelected ? AppTheme.primary : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['note']!,
                        style: GoogleFonts.publicSans(
                          color: isSelected ? Colors.white70 : Colors.white38,
                          fontSize: 10,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
}

String _formatRealTime(double decimalHour) {
  double h = decimalHour % 24.0;
  int hour = h.floor();
  int min = ((h - hour) * 60).round();
  if (min == 60) {
    hour = (hour + 1) % 24;
    min = 0;
  }
  return "${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} HS";
}
