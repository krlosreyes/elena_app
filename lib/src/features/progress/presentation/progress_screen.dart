import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_error_screen.dart';
import '../../../core/widgets/elena_header.dart';
import '../../health/data/health_repository.dart';
import '../../health/domain/daily_log.dart';
import '../../profile/application/user_controller.dart';
import '../application/progress_data_provider.dart';

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
          return const AppErrorScreen(
            message: 'No se encontraron datos de usuario.',
          );
        }
        return _buildContent(context, user);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (error, stack) => AppErrorScreen(
        message: 'Error cargando tu perfil. Intenta de nuevo.',
        onRetry: () => ref.invalidate(currentUserStreamProvider),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    final historyDays = switch (_selectedTab) {
      0 => 7,
      1 => 30,
      2 => 365,
      _ => 7,
    };
    final logs =
        ref
            .watch(logsHistoryProvider((uid: user.uid, days: historyDays)))
            .valueOrNull ??
        [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            ElenaHeader(title: 'Progreso', user: user),
            const SizedBox(height: 24),
            _buildTabBar(),
            const SizedBox(height: 24),
            // Cards
            _CircadianRhythmCard(logs: logs),
            const SizedBox(height: 12),
            _buildTrendAndSummary(user),
            const SizedBox(height: 12),
            _buildRecentDaysList(user, logs),
            const SizedBox(height: 12),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // TREND + SUMMARY — 3 métricas + indicador de tendencia
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTrendAndSummary(UserModel user) {
    final progressAsync = ref.watch(progressDataProvider(user.uid));

    return progressAsync.when(
      data: (data) => _TrendSummarySection(data: data),
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT DAYS LIST — últimos 7 días con pilares
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentDaysList(UserModel user, List<DailyLog> logs) {
    final now = DateTime.now();
    final last7 = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final dateId = DateFormat('yyyy-MM-dd').format(date);
      final log = logs.where((l) => l.id == dateId).firstOrNull;
      return (date: date, log: log);
    });

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(
                Icons.calendar_today,
                color: AppTheme.primary,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'ÚLTIMOS 7 DÍAS',
                style: GoogleFonts.robotoMono(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...last7.map(
            (entry) => _RecentDayRow(
              date: entry.date,
              log: entry.log,
              isToday:
                  entry.date.day == now.day &&
                  entry.date.month == now.month &&
                  entry.date.year == now.year,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(UserModel user, List<DailyLog> logs) {
    final avgImr = logs.isEmpty
        ? 0.0
        : logs.map((l) => l.imrScore).reduce((a, b) => a + b) / logs.length;

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
                  'RESUMEN BIO-TELEMETRÍA (IMR)',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
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
                      'Tu Índice de Metamorfosis Real ha mostrado una estabilidad del ',
                ),
                TextSpan(
                  text: '${avgImr.toStringAsFixed(0)}%',
                  style: GoogleFonts.publicSans(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// CIRCADIAN RHYTHM CARD — Grid semanal de pilares (Ayuno/Alimentación/Sueño)
// ═══════════════════════════════════════════════════════════════════════════════

enum _CellStatus { fulfilled, partial, noRecord }

class _CircadianRhythmCard extends StatelessWidget {
  final List<DailyLog> logs;

  const _CircadianRhythmCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Calcular inicio de la semana actual (lunes)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekNumber = _isoWeekNumber(now);

    // 7 días de la semana actual
    final weekDays = List.generate(7, (i) {
      final date = DateTime(monday.year, monday.month, monday.day + i);
      final dateId = DateFormat('yyyy-MM-dd').format(date);
      final log = logs.where((l) => l.id == dateId).firstOrNull;
      final isFuture = date.isAfter(now);
      return (date: date, log: log, isFuture: isFuture);
    });

    // Generar status para cada pilar × día
    final fastingRow = weekDays
        .map((d) => d.isFuture ? _CellStatus.noRecord : _fastingStatus(d.log))
        .toList();
    final nutritionRow = weekDays
        .map((d) => d.isFuture ? _CellStatus.noRecord : _nutritionStatus(d.log))
        .toList();
    final sleepRow = weekDays
        .map((d) => d.isFuture ? _CellStatus.noRecord : _sleepStatus(d.log))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + Semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RITMO CIRCADIANO',
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'SEMANA $weekNumber',
                style: GoogleFonts.robotoMono(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid: 3 filas × 7 columnas
          _buildPillarRow('AYUNO', fastingRow),
          const SizedBox(height: 8),
          _buildPillarRow('ALIMENTACIÓN', nutritionRow),
          const SizedBox(height: 8),
          _buildPillarRow('SUEÑO', sleepRow),

          const SizedBox(height: 16),

          // Leyenda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppTheme.primary, 'CUMPLIDO'),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFFFFAA00), 'PARCIAL'),
              const SizedBox(width: 16),
              _buildLegendDot(Colors.white24, 'SIN REGISTRO'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillarRow(String label, List<_CellStatus> cells) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.robotoMono(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...cells.map(
          (status) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: Container(
                  decoration: BoxDecoration(
                    color: _cellColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.robotoMono(
            color: Colors.white38,
            fontSize: 8,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Color _cellColor(_CellStatus status) {
    switch (status) {
      case _CellStatus.fulfilled:
        return AppTheme.primary; // Verde neón
      case _CellStatus.partial:
        return const Color(0xFFFFAA00); // Naranja
      case _CellStatus.noRecord:
        return Colors.white.withValues(alpha: 0.08); // Gris oscuro
    }
  }

  // ── Lógica de cumplimiento por pilar ────────────────────────────────

  _CellStatus _fastingStatus(DailyLog? log) {
    if (log == null) return _CellStatus.noRecord;
    if (log.fastingStartTime != null && log.fastingEndTime != null) {
      return _CellStatus.fulfilled;
    }
    if (log.fastingStartTime != null) {
      return _CellStatus.partial;
    }
    return _CellStatus.noRecord;
  }

  _CellStatus _nutritionStatus(DailyLog? log) {
    if (log == null) return _CellStatus.noRecord;
    final hasMeals = log.mealEntries.isNotEmpty || log.calories > 0;
    if (!hasMeals) return _CellStatus.noRecord;
    // 3+ comidas o >1200 kcal = cumplido, sino parcial
    if (log.mealEntries.length >= 3 || log.calories >= 1200) {
      return _CellStatus.fulfilled;
    }
    return _CellStatus.partial;
  }

  _CellStatus _sleepStatus(DailyLog? log) {
    if (log == null) return _CellStatus.noRecord;
    if (log.sleepMinutes <= 0) return _CellStatus.noRecord;
    // ≥7h = cumplido, <7h = parcial
    if (log.sleepMinutes >= 420) return _CellStatus.fulfilled;
    return _CellStatus.partial;
  }

  int _isoWeekNumber(DateTime date) {
    // ISO 8601 week number
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) return _isoWeekNumber(DateTime(date.year - 1, 12, 28));
    if (woy > 52) {
      final dec28 = DateTime(date.year, 12, 28);
      if (date.isAfter(dec28)) return 1;
    }
    return woy;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TREND SUMMARY SECTION — Tendencia + 3 métricas en fila
// ═══════════════════════════════════════════════════════════════════════════════

class _TrendSummarySection extends StatelessWidget {
  final ProgressData data;
  const _TrendSummarySection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Indicador de tendencia ──────────────────────────────────────
        _buildTrendIndicator(),
        const SizedBox(height: 12),
        // ── 3 métricas en fila ──────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: 'IMR PROMEDIO',
                value: data.averageImr.toStringAsFixed(1),
                unit: '/100',
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _StreakBadgeMetric(streak: data.currentStreak)),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryMetric(
                label: 'MEJOR AYUNO',
                value: '${data.bestFastingHours}',
                unit: 'hrs',
                color: Colors.cyanAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendIndicator() {
    final trend = data.trendVsLastWeek;

    IconData icon;
    Color color;
    String label;

    if (trend == null) {
      icon = Icons.remove;
      color = Colors.white38;
      label = 'SIN DATOS SUFICIENTES';
    } else if (trend > 2) {
      icon = Icons.trending_up;
      color = AppTheme.primary;
      label = '+${trend.toStringAsFixed(1)} vs semana anterior';
    } else if (trend < -2) {
      icon = Icons.trending_down;
      color = Colors.redAccent;
      label = '${trend.toStringAsFixed(1)} vs semana anterior';
    } else {
      icon = Icons.trending_flat;
      color = Colors.white54;
      label = 'Estable vs semana anterior';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TENDENCIA IMR',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.publicSans(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: GoogleFonts.robotoMono(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STREAK BADGE METRIC — Badge pill de racha (mismo estilo que ElenaHeader)
// ═══════════════════════════════════════════════════════════════════════════════

class _StreakBadgeMetric extends StatelessWidget {
  final int streak;
  const _StreakBadgeMetric({required this.streak});

  @override
  Widget build(BuildContext context) {
    final streakText = streak.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            'RACHA',
            style: GoogleFonts.robotoMono(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  streakText,
                  style: GoogleFonts.robotoMono(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECENT DAY ROW — fila individual del listado de últimos 7 días
// ═══════════════════════════════════════════════════════════════════════════════

class _RecentDayRow extends StatelessWidget {
  final DateTime date;
  final DailyLog? log;
  final bool isToday;

  const _RecentDayRow({
    required this.date,
    required this.log,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final score = log?.imrScore ?? 0.0;
    final progress = (score / 100).clamp(0.0, 1.0);
    final dayName = DateFormat('EEE', 'es').format(date).toUpperCase();
    final dayNum = DateFormat('dd/MM').format(date);

    // Pillar checks
    final hasHydration = (log?.waterGlasses ?? 0) > 0;
    final hasNutrition = (log?.calories ?? 0) > 0;
    final hasFasting = log?.fastingStartTime != null;
    final hasExercise = (log?.exerciseMinutes ?? 0) > 0;
    final hasSleep = (log?.sleepMinutes ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: GoogleFonts.robotoMono(
                    color: isToday ? AppTheme.primary : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dayNum,
                  style: GoogleFonts.robotoMono(
                    color: Colors.white30,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          // IMR score
          SizedBox(
            width: 36,
            child: Text(
              score > 0 ? score.toStringAsFixed(0) : '—',
              style: GoogleFonts.outfit(
                color: score > 70
                    ? AppTheme.primary
                    : (score > 40 ? Colors.orangeAccent : Colors.white38),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Progress bar
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress > 0 ? progress : 0.02,
                child: Container(
                  decoration: BoxDecoration(
                    color: score > 70
                        ? AppTheme.primary
                        : (score > 40 ? Colors.orangeAccent : Colors.white24),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 5 pillar icons
          _PillarDot(
            active: hasHydration,
            icon: Icons.water_drop,
            color: Colors.cyanAccent,
          ),
          _PillarDot(
            active: hasNutrition,
            icon: Icons.restaurant,
            color: Colors.orangeAccent,
          ),
          _PillarDot(
            active: hasFasting,
            icon: Icons.timer,
            color: AppTheme.primary,
          ),
          _PillarDot(
            active: hasExercise,
            icon: Icons.fitness_center,
            color: Colors.redAccent,
          ),
          _PillarDot(
            active: hasSleep,
            icon: Icons.nightlight_round,
            color: Colors.deepPurpleAccent,
          ),
        ],
      ),
    );
  }
}

class _PillarDot extends StatelessWidget {
  final bool active;
  final IconData icon;
  final Color color;

  const _PillarDot({
    required this.active,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(
        icon,
        size: 12,
        color: active ? color : Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}
