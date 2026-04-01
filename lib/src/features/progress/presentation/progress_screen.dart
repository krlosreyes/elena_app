import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import '../../../core/widgets/elena_header.dart';
import '../../health/data/health_repository.dart';
import '../../health/domain/daily_log.dart';
import '../../../domain/logic/elena_brain.dart';
import '../../fasting/data/fasting_repository.dart';
import 'package:elena_app/src/shared/domain/models/fasting_session.dart';
import '../../profile/application/user_controller.dart';
import '../../training/application/movement_controller.dart';
import '../../../core/providers/metabolic_hub_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedTab = 0; // 0: SEMANA, 1: MES, 2: AÑO

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(currentUserStreamProvider);

    return userState.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Error: No user data'));
        }
        return _buildContent(context, user);
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    final historyDays = switch (_selectedTab) {
      0 => 7,
      1 => 30,
      2 => 365,
      _ => 7,
    };
    final logs = ref
            .watch(logsHistoryProvider((uid: user.uid, days: historyDays)))
            .valueOrNull ??
        [];
    final metabolicHub = ref.watch(metabolicHubProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            ElenaHeader(
              title: 'Progreso',
              user: user,
            ),
            const SizedBox(height: 24),
            _buildTabBar(),
            const SizedBox(height: 24),
            // Cards
            _buildMtiCard(user, metabolicHub, logs),
            const SizedBox(height: 12),
            _buildHydrationCard(user, logs),
            const SizedBox(height: 12),
            _buildFastingCard(user, logs),
            const SizedBox(height: 12),
            _buildExerciseCard(user),
            const SizedBox(height: 12),
            _buildNutritionCard(user),
            const SizedBox(height: 12),
            _buildSleepCard(user),
            const SizedBox(height: 24),
            _buildSummaryCard(user, logs),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'SEMANA'),
          _buildTabItem(1, 'MES'),
          _buildTabItem(2, 'AÑO'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoMono(
              color: isSelected ? Colors.black : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(UserModel user, List<DailyLog> logs) {
    final avgMti = logs.isEmpty
        ? 0.0
        : logs.map((l) => l.mtiScore).reduce((a, b) => a + b) / logs.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'RESUMEN BIO-TELEMETRÍA (IED)',
                  style: GoogleFonts.robotoMono(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: GoogleFonts.publicSans(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
              children: [
                const TextSpan(
                    text:
                        'Tu Índice de Ejecución Diaria ha mostrado una estabilidad del '),
                TextSpan(
                  text: '${avgMti.toStringAsFixed(0)}%',
                  style: GoogleFonts.publicSans(
                      color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text:
                      ' durante el ciclo actual. Los niveles de hidratación son el factor crítico a optimizar para mejorar la recuperación post-entrenamiento.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastingCard(UserModel user, List<DailyLog> logs) {
    final historyDays = switch (_selectedTab) {
      0 => 7,
      1 => 30,
      2 => 365,
      _ => 7,
    };
    final historyAsync = ref
        .watch(fastingHistoryRangeProvider((uid: user.uid, days: historyDays)));
    final metabolicHub = ref.watch(metabolicHubProvider);
    final healthPlan = ElenaBrain.generateHealthPlan(user);

    // Get hours from history + current fast if active
    final history = historyAsync.valueOrNull ?? [];
    final fastingState = metabolicHub.fastingStatus;
    final now = DateTime.now();

    // Distribution map for the selected period
    Map<int, double> hoursPerDay = {};
    for (int i = 0; i < historyDays; i++) {
      hoursPerDay[i] = 0.0;
    }

    final periodStart = now.subtract(Duration(days: historyDays - 1));
    final startDate =
        DateTime(periodStart.year, periodStart.month, periodStart.day);

    // Process all sessions pro-rated
    List<FastingSession> allSessions =
        history.where((s) => s.isCompleted).toList();
    if (fastingState != null &&
        fastingState.isFasting &&
        fastingState.startTime != null) {
      allSessions.add(FastingSession(
        uid: 'active',
        startTime: fastingState.startTime!,
        endTime: now,
        isCompleted: false,
        plannedDurationHours: 16,
      ));
    }

    for (var session in allSessions) {
      final start = session.startTime;
      final end = session.endTime ?? now;

      DateTime current = DateTime(start.year, start.month, start.day);
      while (current.isBefore(end)) {
        DateTime nextDay = current.add(const Duration(days: 1));
        DateTime segStart = start.isAfter(current) ? start : current;
        DateTime segEnd = end.isBefore(nextDay) ? end : nextDay;

        if (segEnd.isAfter(segStart)) {
          double segHours = segEnd.difference(segStart).inMinutes / 60.0;
          final diffDays = current.difference(startDate).inDays;
          if (diffDays >= 0 && diffDays < historyDays) {
            hoursPerDay[diffDays] = (hoursPerDay[diffDays] ?? 0.0) + segHours;
          }
        }
        current = nextDay;
      }
    }

    // Cap at 24h and Pro-rate accurately
    hoursPerDay.forEach((k, v) {
      if (v > 24.0) hoursPerDay[k] = 24.0;
    });

    // Aggregation for Annual view (Months)
    Map<int, double> aggregatedData = {};
    int barCount = historyDays;

    if (historyDays > 31) {
      barCount = 12;
      // Group by month
      for (int i = 0; i < 12; i++) {
        DateTime monthDate = DateTime(now.year, now.month - (11 - i), 1);
        double monthSum = 0;
        int daysInMonth = 0;

        hoursPerDay.forEach((dayIdx, val) {
          DateTime d = startDate.add(Duration(days: dayIdx));
          if (d.year == monthDate.year && d.month == monthDate.month) {
            monthSum += val;
            daysInMonth++;
          }
        });
        aggregatedData[i] = daysInMonth > 0 ? monthSum / daysInMonth : 0.0;
      }
    } else {
      aggregatedData = hoursPerDay;
    }

    final avgFasting = hoursPerDay.values.isEmpty
        ? 0.0
        : hoursPerDay.values.reduce((a, b) => a + b) / historyDays;
    final goalHours = int.tryParse(healthPlan.protocol.split(':').first) ?? 16;

    return _MetricExpansionCard(
      title: 'AYUNO',
      mainText: avgFasting.toStringAsFixed(1),
      subText: 'h/día',
      trendText: 'MEDIA',
      trendIcon: Icons.history,
      isPositive: avgFasting >= goalHours,
      initiallyExpanded: false,
      expandedChild: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: _FastingWeeklyChart(
          hoursPerDay: aggregatedData,
          goalHours: goalHours,
          historyDays: historyDays,
          barCount: barCount,
        ),
      ),
    );
  }

  Widget _buildHydrationCard(UserModel user, List<DailyLog> logs) {
    final historyDays = switch (_selectedTab) {
      0 => 7,
      1 => 30,
      2 => 365,
      _ => 7,
    };
    final metabolicHub = ref.watch(metabolicHubProvider);
    final healthPlan = ElenaBrain.generateHealthPlan(user);

    final currentLiters = metabolicHub.hydrationLevel * 0.25;

    // Aggregation for Hydration
    Map<int, double> aggregatedHydration = {};
    int barCount = historyDays;
    final now = DateTime.now();
    final periodStart = now.subtract(Duration(days: historyDays - 1));
    final startDate =
        DateTime(periodStart.year, periodStart.month, periodStart.day);

    if (historyDays > 31) {
      barCount = 12;
      for (int i = 0; i < 12; i++) {
        DateTime monthDate = DateTime(now.year, now.month - (11 - i), 1);
        double monthSum = 0;
        int logsInMonth = 0;
        for (var log in logs) {
          DateTime? d = DateTime.tryParse(log.id);
          if (d != null &&
              d.year == monthDate.year &&
              d.month == monthDate.month) {
            monthSum += log.waterGlasses;
            logsInMonth++;
          }
        }
        aggregatedHydration[i] = logsInMonth > 0 ? monthSum / logsInMonth : 0.0;
      }
    } else {
      for (int i = 0; i < historyDays; i++) {
        final date = startDate.add(Duration(days: i));
        final dateId = DateFormat('yyyy-MM-dd').format(date);
        final log = logs.any((l) => l.id == dateId)
            ? logs.firstWhere((l) => l.id == dateId)
            : null;
        aggregatedHydration[i] = (log?.waterGlasses ?? 0).toDouble();
      }
    }

    return _MetricExpansionCard(
      title: 'HIDRATACIÓN',
      mainText: currentLiters.toStringAsFixed(1),
      subText: 'L',
      trendText: 'ACTUAL',
      trendIcon: Icons.water_drop,
      isPositive: true,
      initiallyExpanded: false,
      expandedChild: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: _WeeklyProgressChart(
          aggregatedData: aggregatedHydration,
          goalGlasses: healthPlan.hydrationGoal,
          historyDays: historyDays,
          barCount: barCount,
        ),
      ),
    );
  }

  Widget _buildMtiCard(
      UserModel user, MetabolicContext hub, List<DailyLog> logs) {
    final historyDays = switch (_selectedTab) {
      0 => 7,
      1 => 30,
      2 => 365,
      _ => 7,
    };

    final List<double> chartData = List.generate(historyDays, (index) {
      final date =
          DateTime.now().subtract(Duration(days: historyDays - 1 - index));
      final dateId = DateFormat('yyyy-MM-dd').format(date);
      final log = logs.any((l) => l.id == dateId)
          ? logs.firstWhere((l) => l.id == dateId)
          : null;
      return log?.mtiScore ?? 0.0;
    });

    return _MetricExpansionCard(
      title: 'IED INDEX',
      mainText: hub.totalIED.toStringAsFixed(0),
      subText: '/100',
      trendText: 'ACTUAL',
      trendIcon: Icons.bolt,
      isPositive: hub.totalIED > 70,
      initiallyExpanded: true,
      hasChart: true,
      chartData: chartData,
      historyDays: historyDays,
    );
  }

  Widget _buildExerciseCard(UserModel user) {
    final exercise = ref.watch(exerciseProvider);

    return _MetricExpansionCard(
      title: 'EJERCICIO',
      mainText: exercise.minutesCurrent.toString(),
      subText: 'min',
      trendText: exercise.minutesCurrent >= 30 ? 'META OK' : 'EN PROGRESO',
      trendIcon: Icons.fitbit,
      isPositive: exercise.minutesCurrent >= 30,
    );
  }

  Widget _buildNutritionCard(UserModel user) {
    final todayLog = ref.watch(todayLogProvider(user.uid)).valueOrNull;
    final calories = todayLog?.calories ?? 0;

    return _MetricExpansionCard(
      title: 'NUTRICIÓN',
      mainText: calories > 0 ? '$calories' : 'PENDIENTE',
      subText: calories > 0 ? 'kcal' : '',
      trendText: calories > 0 ? 'LOGUEADO' : 'SIN DATOS',
      trendIcon: Icons.restaurant,
      isPositive: true,
      isIconOnlyTrend: calories == 0,
    );
  }

  Widget _buildSleepCard(UserModel user) {
    final todayLog = ref.watch(todayLogProvider(user.uid)).valueOrNull;
    final minutes = todayLog?.sleepMinutes ?? 0;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    return _MetricExpansionCard(
      title: 'SUEÑO',
      mainText: hours.toString(),
      subText: 'h ${mins}m',
      trendText: hours >= 7 ? 'ÓPTIMO' : 'PENDIENTE',
      trendIcon: Icons.dark_mode,
      isPositive: hours >= 7,
    );
  }
}

class _FastingWeeklyChart extends StatefulWidget {
  final Map<int, double> hoursPerDay;
  final int goalHours;
  final int historyDays;
  final int barCount;

  const _FastingWeeklyChart({
    required this.hoursPerDay,
    required this.goalHours,
    required this.historyDays,
    required this.barCount,
  });

  @override
  State<_FastingWeeklyChart> createState() => _FastingWeeklyChartState();
}

class _FastingWeeklyChartState extends State<_FastingWeeklyChart> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;

    int barCount = widget.barCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.historyDays <= 7
                  ? 'PROGRESO SEMANAL'
                  : (widget.historyDays <= 31
                      ? 'PROGRESO MENSUAL'
                      : 'PROGRESO ANUAL (MEDIAS)'),
              style: GoogleFonts.robotoMono(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (index) {
              final hours = widget.hoursPerDay[index] ?? 0.0;
              final double progress = (hours / 24.0).clamp(0.01, 1.0);
              final bool isToday =
                  widget.historyDays <= 7 && (index + 1) == todayWeekday;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: widget.historyDays > 31 ? 2.0 : 1.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.historyDays <= 7) ...[
                        const SizedBox(height: 8),
                        Text(
                          ['L', 'M', 'X', 'J', 'V', 'S', 'D'][index],
                          style: GoogleFonts.robotoMono(
                            color: isToday ? AppTheme.primary : Colors.white30,
                            fontSize: 10,
                          ),
                        ),
                      ],
                      if (widget.historyDays > 31) ...[
                        const SizedBox(height: 8),
                        Text(
                          [
                            'E',
                            'F',
                            'M',
                            'A',
                            'M',
                            'J',
                            'J',
                            'A',
                            'S',
                            'O',
                            'N',
                            'D'
                          ][index],
                          style: GoogleFonts.robotoMono(
                            color: Colors.white30,
                            fontSize: 8,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _WeeklyProgressChart extends StatelessWidget {
  final Map<int, double> aggregatedData;
  final int goalGlasses;
  final int historyDays;
  final int barCount;

  const _WeeklyProgressChart({
    required this.aggregatedData,
    required this.goalGlasses,
    required this.historyDays,
    required this.barCount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              historyDays <= 7
                  ? 'PROGRESO SEMANAL'
                  : (historyDays <= 31
                      ? 'PROGRESO MENSUAL'
                      : 'PROGRESO ANUAL (MEDIAS)'),
              style: GoogleFonts.robotoMono(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (index) {
              final double value = aggregatedData[index] ?? 0.0;
              bool isToday = false;

              if (historyDays <= 7) {
                final date =
                    now.subtract(Duration(days: historyDays - 1 - index));
                isToday = date.day == now.day && date.month == now.month;
              }

              final double barProgress = (value / goalGlasses).clamp(0.01, 1.2);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: historyDays > 31 ? 2.0 : 1.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? Colors.blueAccent.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: barProgress.clamp(0.01, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Colors.white
                                    : Colors.blueAccent.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (historyDays <= 7) ...[
                        const SizedBox(height: 8),
                        Text(
                          ['L', 'M', 'X', 'J', 'V', 'S', 'D'][index],
                          style: GoogleFonts.robotoMono(
                            color: isToday ? Colors.blueAccent : Colors.white30,
                            fontSize: 10,
                          ),
                        ),
                      ],
                      if (historyDays > 31) ...[
                        const SizedBox(height: 8),
                        Text(
                          [
                            'E',
                            'F',
                            'M',
                            'A',
                            'M',
                            'J',
                            'J',
                            'A',
                            'S',
                            'O',
                            'N',
                            'D'
                          ][index],
                          style: GoogleFonts.robotoMono(
                            color: Colors.white30,
                            fontSize: 8,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MetricExpansionCard extends StatefulWidget {
  final String title;
  final String mainText;
  final String subText;
  final String trendText;
  final IconData trendIcon;
  final bool isPositive;
  final bool initiallyExpanded;
  final bool hasChart;
  final bool isIconOnlyTrend;
  final Widget? expandedChild;
  final List<double>? chartData;
  final int historyDays;

  const _MetricExpansionCard({
    required this.title,
    required this.mainText,
    required this.subText,
    required this.trendText,
    required this.trendIcon,
    required this.isPositive,
    this.initiallyExpanded = false,
    this.hasChart = false,
    this.isIconOnlyTrend = false,
    this.expandedChild,
    this.chartData,
    this.historyDays = 7,
  });

  @override
  State<_MetricExpansionCard> createState() => _MetricExpansionCardState();
}

class _MetricExpansionCardState extends State<_MetricExpansionCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.robotoMono(
                            color: Colors.white54,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              widget.mainText,
                              style: GoogleFonts.robotoMono(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.subText.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.subText,
                                style: GoogleFonts.robotoMono(
                                    color: Colors.white38,
                                    fontSize: isSmallScreen ? 12 : 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isIconOnlyTrend
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : (widget.isPositive
                                ? AppTheme.primary.withValues(alpha: 0.1)
                                : Colors.redAccent.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.isIconOnlyTrend
                              ? AppTheme.primary.withValues(alpha: 0.2)
                              : (widget.isPositive
                                  ? AppTheme.primary.withValues(alpha: 0.2)
                                  : Colors.redAccent.withValues(alpha: 0.2)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.trendIcon,
                            color: widget.isIconOnlyTrend
                                ? AppTheme.primary
                                : (widget.isPositive
                                    ? AppTheme.primary
                                    : Colors.redAccent),
                            size: 14,
                          ),
                          if (!widget.isIconOnlyTrend) ...[
                            const SizedBox(width: 4),
                            Text(
                              widget.trendText,
                              style: GoogleFonts.robotoMono(
                                color: widget.isPositive
                                    ? AppTheme.primary
                                    : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
            if (_isExpanded && widget.expandedChild != null)
              widget.expandedChild!,
            if (_isExpanded &&
                widget.hasChart &&
                widget.expandedChild == null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ChartPainter(dataValues: widget.chartData),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.historyDays <= 7)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                      .map((day) => Text(
                            day,
                            style: GoogleFonts.robotoMono(
                                color: Colors.white38, fontSize: 10),
                          ))
                      .toList(),
                )
            ]
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double>? dataValues;
  _ChartPainter({this.dataValues});

  @override
  void paint(Canvas canvas, Size size) {
    if (dataValues == null || dataValues!.isEmpty) return;

    final paintLine = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();

    final dataPoints = List.generate(dataValues!.length, (i) {
      final x = (size.width / (dataValues!.length - 1)) * i;
      final val = (dataValues![i] / 100).clamp(0.01, 0.99);
      final y = size.height - (size.height * val);
      return Offset(x, y);
    });

    path.moveTo(dataPoints[0].dx, dataPoints[0].dy);

    for (int i = 0; i < dataPoints.length - 1; i++) {
      final p0 = dataPoints[i];
      final p1 = dataPoints[i + 1];
      final controlPointX = p0.dx + (p1.dx - p0.dx) / 2;
      path.cubicTo(controlPointX, p0.dy, controlPointX, p1.dy, p1.dx, p1.dy);
    }

    canvas.drawPath(path, paintLine);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primary.withValues(alpha: 0.2),
          AppTheme.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, paintFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
