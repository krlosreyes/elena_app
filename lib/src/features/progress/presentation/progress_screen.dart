

import 'package:elena_app/src/features/profile/application/user_controller.dart';
import 'package:elena_app/src/features/profile/domain/user_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../progress/application/progress_controller.dart';
import '../../progress/domain/measurement_log.dart';
import '../../authentication/application/auth_controller.dart';
import '../../glucose/presentation/widgets/glucose_chart_widget.dart';
import 'widgets/fasting_chart_card.dart';
import 'widgets/measurement_bottom_sheet.dart';
import 'package:elena_app/src/features/progress/presentation/widgets/weight_input_sheet.dart';
import 'widgets/week_calendar.dart';
import '../../dashboard/presentation/widgets/dashboard_header.dart';
import '../../../shared/presentation/widgets/responsive_centered_view.dart';


class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  int _selectedIndex = 0;

  static const _pillars = [
    _Pillar(code: 'B', name: 'Composición', weight: '40%', color: Color(0xFF26C6DA), icon: Icons.accessibility_new),
    _Pillar(code: 'M', name: 'Metabólico',  weight: '30%', color: Color(0xFF00FFB2), icon: Icons.local_fire_department),
    _Pillar(code: 'H', name: 'Hábitos',     weight: '30%', color: Color(0xFFAB47BC), icon: Icons.spa_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final historyAsync = ref.watch(userMeasurementsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) return const Center(child: Text("Perfil no cargado"));

            return historyAsync.when(
              data: (history) => _buildBody(context, user, history),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text("Error cargando perfil: $e")),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserModel user, List<MeasurementLog> history) {
    final pillar = _pillars[_selectedIndex];

    return ResponsiveCenteredView(
      maxWidth: 800,
      child: Column(
        children: [
          // ── FIXED HEADER (does not scroll) ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardHeader(),
                const SizedBox(height: 16),
                WeekCalendar(
                  checkInDay: user.checkInDay ?? 1,
                  onCheckInTap: () {},
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── TAB BAR ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 95,
              child: TabBar(
                controller: _tabController,
                indicator: const BoxDecoration(),
                dividerColor: Colors.transparent,
                tabs: _pillars.asMap().entries.map((e) {
                  final selected = _selectedIndex == e.key;
                  return _PillarTab(pillar: e.value, selected: selected);
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // ── TAB CONTENT ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PillarBTab(user: user, history: history),
                _PillarMTab(user: user),
                _PillarHTab(user: user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMeasurementModal(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MeasurementBottomSheet(user: user),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASS
// ─────────────────────────────────────────────────────────────────────────────
class _Pillar {
  final String code;
  final String name;
  final String weight;
  final Color color;
  final IconData icon;

  const _Pillar({
    required this.code,
    required this.name,
    required this.weight,
    required this.color,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PILLAR TAB WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _PillarTab extends StatelessWidget {
  final _Pillar pillar;
  final bool selected;

  const _PillarTab({required this.pillar, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: selected ? pillar.color.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? pillar.color.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pillar.code,
            style: GoogleFonts.firaCode(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: selected ? pillar.color : Colors.white38,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pillar.name,
            style: GoogleFonts.outfit(
              fontSize: 9,
              color: selected ? pillar.color.withOpacity(0.85) : Colors.white30,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pillar.weight,
            style: GoogleFonts.robotoMono(
              fontSize: 8,
              color: selected ? pillar.color : Colors.white24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STICKY HEADER DELEGATE
// ─────────────────────────────────────────────────────────────────────────────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final PreferredSizeWidget tabBar;
  final Color backgroundColor;

  const _StickyTabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height + 12;
  @override
  double get maxExtent => tabBar.preferredSize.height + 12;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// PILAR B — COMPOSICIÓN CORPORAL
// ─────────────────────────────────────────────────────────────────────────────
class _PillarBTab extends ConsumerWidget {
  final UserModel user;
  final List<MeasurementLog> history;

  const _PillarBTab({required this.user, required this.history});

  static const _color = Color(0xFF26C6DA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = history.isNotEmpty ? history.last : null;
    final previous = history.length > 1 ? history[history.length - 2] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _PillarSectionHeader(
            title: 'Composición Corporal',
            subtitle: 'Cintura · Altura · Cadera · Cuello',
            color: _color,
            action: TextButton.icon(
              onPressed: () => _showMeasurementModal(context, user),
              icon: const Icon(Icons.add_circle_outline, size: 15),
              label: const Text('Registrar'),
              style: TextButton.styleFrom(
                foregroundColor: _color,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (latest != null) ...[
            _BodyStatsRow(latest: latest, previous: previous, heightCm: user.heightCm ?? 170),
            const SizedBox(height: 20),
          ] else
            _EmptyState(
              message: 'Registra tus medidas corporales para activar el Pilar B',
              color: _color,
              onTap: () => _showMeasurementModal(context, user),
            ),

          // Weight trend
          if (history.length > 1) ...[
            _SubHeader(
              title: 'Tendencia de Peso (12 semanas)',
              color: _color,
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: _cardDeco(context, _color),
              child: _WeightChart(history: history),
            ),
            const SizedBox(height: 20),
          ],

          // History table
          if (history.isNotEmpty) ...[
            _SubHeader(title: 'Historial detallado', color: _color),
            const SizedBox(height: 8),
            _HistoryTable(history: history),
          ],
        ],
      ),
    );
  }

  void _showMeasurementModal(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => MeasurementBottomSheet(user: user),
    );
  }

  BoxDecoration _cardDeco(BuildContext context, Color accent) => BoxDecoration(
    color: Theme.of(context).cardTheme.color,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: accent.withOpacity(0.2)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PILAR M — COMPORTAMIENTO METABÓLICO
// ─────────────────────────────────────────────────────────────────────────────
class _PillarMTab extends ConsumerWidget {
  final UserModel user;

  const _PillarMTab({required this.user});

  static const _color = Color(0xFF00FFB2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PillarSectionHeader(
            title: 'Comportamiento Metabólico',
            subtitle: 'Ayuno · Consistencia · Curva logística',
            color: _color,
          ),
          const SizedBox(height: 16),

          // Fasting consistency chart
          const FastingChartCard(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PILAR H — HÁBITOS
// ─────────────────────────────────────────────────────────────────────────────
class _PillarHTab extends ConsumerWidget {
  final UserModel user;

  const _PillarHTab({required this.user});

  static const _color = Color(0xFFAB47BC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PillarSectionHeader(
            title: 'Hábitos de Estilo de Vida',
            subtitle: 'Sueño · Nutrición · Ejercicio',
            color: _color,
          ),
          const SizedBox(height: 20),

          // ── SUEÑO ────────────────────────────────────────────────────────
          _SleepCard(user: user),
          const SizedBox(height: 14),

          // ── NUTRICIÓN ─────────────────────────────────────────────────────
          _NutritionCard(user: user),
          const SizedBox(height: 14),

          // ── EJERCICIO ─────────────────────────────────────────────────────
          _ExerciseCard(user: user),
          const SizedBox(height: 20),

          if (user.shouldTrackGlucose) ...[
            const GlucoseChartWidget(),
            const SizedBox(height: 20),
          ],

          // IMX contribution note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: _color, size: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Estos hábitos alimentan el Pilar H de tu IMX. Mejorarlos mueve directamente tu Índice de Metamorfosis.',
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, height: 1.4),
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

// ── Sleep Card ──────────────────────────────────────────────────────────────
class _SleepCard extends StatelessWidget {
  final UserModel user;
  const _SleepCard({required this.user});

  double _parseHour(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return 0;
    return double.parse(parts[0]) + double.parse(parts[1]) / 60;
  }

  double get _sleepHours {
    if (user.averageSleepHours != null) return user.averageSleepHours!;
    final bed = _parseHour(user.bedTime);
    final wake = _parseHour(user.wakeUpTime);
    final diff = wake - bed;
    return diff < 0 ? diff + 24 : diff;
  }

  @override
  Widget build(BuildContext context) {
    final hours = _sleepHours;
    final pct = (hours / 9.0).clamp(0.0, 1.0);

    Color quality;
    String label;
    if (hours >= 7) {
      quality = const Color(0xFF00FFB2);
      label = 'Óptimo';
    } else if (hours >= 6) {
      quality = const Color(0xFFFFB300);
      label = 'Deficiente';
    } else {
      quality = Colors.redAccent;
      label = 'Crítico';
    }

    // Fasting window overnight
    final bedH = _parseHour(user.bedTime);
    final firstMealH = _parseHour(user.usualFirstMealTime);
    final nightFast = ((firstMealH - bedH) + 24) % 24;

    return _HabitCard(
      icon: Icons.bedtime_outlined,
      title: 'Sueño',
      color: quality,
      children: [
        Row(
          children: [
            Text(
              '${hours.toStringAsFixed(1)}h',
              style: GoogleFonts.robotoMono(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: quality.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label, style: GoogleFonts.outfit(fontSize: 11, color: quality, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProgressBar(value: pct, color: quality),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Duermes: ${user.bedTime} – ${user.wakeUpTime}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
            ),
            const SizedBox(width: 8),
            Text('Ayuno: ${nightFast.toStringAsFixed(1)}h', // Acortado para ganar espacio
                style: GoogleFonts.outfit(fontSize: 11, color: quality.withOpacity(0.6))),
          ],
        ),
      ],
    );
  }
}

// ── Nutrition Card ─────────────────────────────────────────────────────────
class _NutritionCard extends StatelessWidget {
  final UserModel user;
  const _NutritionCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final dietMap = {
      DietaryPreference.omnivore: ('🥩 Omnívoro', Colors.white60),
      DietaryPreference.keto: ('🥑 Keto', const Color(0xFF00FFB2)),
      DietaryPreference.vegan: ('🌱 Vegano', Colors.greenAccent),
      DietaryPreference.low_carb: ('🥦 Bajo en Carbs', Colors.cyanAccent),
    };

    final snackMap = {
      SnackingHabit.never: ('Sin snacks', const Color(0xFF00FFB2)),
      SnackingHabit.sometimes: ('Snacking ocasional', const Color(0xFFFFB300)),
      SnackingHabit.frequent: ('Snacking frecuente', Colors.redAccent),
    };

    final (dietLabel, dietColor) = dietMap[user.dietaryPreference] ?? ('Omnívoro', Colors.white60);
    final (snackLabel, snackColor) = snackMap[user.snackingHabit] ?? ('--', Colors.white38);

    // Eating window
    final firstMeal = user.usualFirstMealTime;
    final lastMeal = user.usualLastMealTime;

    return _HabitCard(
      icon: Icons.restaurant_outlined,
      title: 'Nutrición',
      color: dietColor,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preferencia',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(dietLabel,
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Snacking',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: snackColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: snackColor.withOpacity(0.3)),
                    ),
                    child: Text(snackLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 11, color: snackColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 12, color: Colors.white38),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Ventana: $firstMeal – $lastMeal', // Acortado
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.robotoMono(fontSize: 11, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Exercise Card ──────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final UserModel user;
  const _ExerciseCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final levelMap = {
      ActivityLevel.sedentary: ('Sedentario', Colors.redAccent, 0.15),
      ActivityLevel.light: ('Ligero', const Color(0xFFFFB300), 0.4),
      ActivityLevel.moderate: ('Moderado', const Color(0xFF00FFB2), 0.7),
      ActivityLevel.heavy: ('Muy Activo', Colors.cyanAccent, 1.0),
    };
    final goalMap = {
      HealthGoal.fat_loss: ('Pérdida de grasa', Icons.trending_down),
      HealthGoal.muscle_gain: ('Ganancia muscular', Icons.fitness_center),
      HealthGoal.metabolic_health: ('Salud metabólica', Icons.monitor_heart_outlined),
    };

    final (levelLabel, levelColor, levelPct) =
        levelMap[user.activityLevel] ?? ('Sedentario', Colors.redAccent, 0.1);
    final goal = user.healthGoal != null ? goalMap[user.healthGoal] : null;

    const dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return _HabitCard(
      icon: Icons.directions_run_outlined,
      title: 'Ejercicio',
      color: levelColor,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nivel de Actividad',
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(levelLabel,
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            if (goal != null) ...[
              Icon(goal.$2, size: 14, color: levelColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(goal.$1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 11, color: levelColor.withOpacity(0.8))),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _ProgressBar(value: levelPct, color: levelColor),
        const SizedBox(height: 14),
        // Workout days row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final dayNum = i + 1;
            final active = user.workoutDays.contains(dayNum);
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active ? levelColor.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active ? levelColor.withOpacity(0.5) : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  dayNames[i],
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    color: active ? levelColor : Colors.white24,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(user.hasDumbbells ? Icons.fitness_center : Icons.self_improvement,
                size: 12, color: Colors.white38),
            const SizedBox(width: 6),
            Text(
              user.hasDumbbells ? 'Con mancuernas en casa' : 'Sin equipamiento',
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Shared Habit Card shell ─────────────────────────────────────────────────
class _HabitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _HabitCard({required this.icon, required this.title, required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ── Progress Bar ────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _PillarSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Widget? action;

  const _PillarSectionHeader({
    required this.title,
    required this.subtitle,
    required this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(fontSize: 11, color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String title;
  final Color color;
  final Widget? trailing;

  const _SubHeader({required this.title, required this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w600)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final Color color;
  final VoidCallback? onTap;

  const _EmptyState({required this.message, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.add_chart, color: color.withOpacity(0.4), size: 28),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BODY STATS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _BodyStatsRow extends StatelessWidget {
  final MeasurementLog latest;
  final MeasurementLog? previous;
  final double heightCm;

  const _BodyStatsRow({required this.latest, this.previous, required this.heightCm});

  @override
  Widget build(BuildContext context) {
    final weightChange = previous != null ? latest.weight - previous!.weight : null;
    final bmi = latest.calculateBmi(heightCm / 100);

    // ICC = cintura / cadera
    final waist = latest.waistCircumference;
    final hip = latest.hipCircumference;
    final icc = (waist != null && hip != null && hip > 0) ? waist / hip : null;

    String? iccBadge;
    Color iccColor = const Color(0xFF26C6DA);
    if (icc != null) {
      // WHO thresholds (simplified, same for both sexes as approximation)
      if (icc < 0.85) {
        iccBadge = 'Bajo riesgo';
        iccColor = const Color(0xFF26C6DA);
      } else if (icc < 1.0) {
        iccBadge = 'Riesgo moderado';
        iccColor = Colors.orange;
      } else {
        iccBadge = 'Riesgo alto';
        iccColor = Colors.redAccent;
      }
    }

    return Row(
      children: [
        _StatBox(label: 'PESO', value: latest.weight.toStringAsFixed(1), unit: 'kg', change: weightChange, color: const Color(0xFF26C6DA)),
        const SizedBox(width: 10),
        _StatBox(
          label: 'ICC',
          value: icc != null ? icc.toStringAsFixed(2) : '--',
          unit: '',
          color: iccColor,
          badge: iccBadge,
        ),
        const SizedBox(width: 10),
        _StatBox(label: 'IMC', value: bmi.toStringAsFixed(1), unit: '', color: _bmiColor(bmi), badge: _bmiLabel(bmi)),
      ],
    );
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Bajo';
    if (bmi < 24.9) return 'Normal';
    if (bmi < 29.9) return 'Sobrepeso';
    return 'Obesidad';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blueAccent;
    if (bmi < 24.9) return const Color(0xFF26C6DA);
    if (bmi < 29.9) return Colors.orange;
    return Colors.redAccent;
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final double? change;
  final String? badge;

  const _StatBox({required this.label, required this.value, required this.unit, required this.color, this.change, this.badge});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.firaCode(fontSize: 8, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: GoogleFonts.robotoMono(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (unit.isNotEmpty) ...[const SizedBox(width: 3), Text(unit, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54))],
                ],
              ),
            ),
            if (change != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(change! < 0 ? Icons.trending_down : Icons.trending_up, size: 12, color: change! < 0 ? const Color(0xFF00FFB2) : Colors.redAccent),
                  const SizedBox(width: 3),
                  Text(
                    '${change!.abs().toStringAsFixed(1)} kg',
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: change! < 0 ? const Color(0xFF00FFB2) : Colors.redAccent),
                  ),
                ],
              ),
            ],
            if (badge != null) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(badge!, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEIGHT CHART
// ─────────────────────────────────────────────────────────────────────────────
class _WeightChart extends StatelessWidget {
  final List<MeasurementLog> history;
  const _WeightChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final data = history.length > 12 ? history.sublist(history.length - 12) : history;
    if (data.isEmpty) return const SizedBox.shrink();

    final points = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight)).toList();
    final weights = data.map((e) => e.weight).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = maxW - minW;

    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: range > 0 ? range / 3 : 1,
        getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final i = value.toInt();
              if (i < 0 || i >= data.length) return const SizedBox.shrink();
              if (data.length > 6 && i % 2 != 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(DateFormat('d/M').format(data[i].date), style: const TextStyle(fontSize: 9, color: Colors.white38)),
              );
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: (minW - range * 0.2).clamp(0, double.infinity),
      lineBarsData: [
        LineChartBarData(
          spots: points,
          isCurved: true,
          color: const Color(0xFF26C6DA),
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: const Color(0xFF26C6DA), strokeWidth: 1.5, strokeColor: Colors.white),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [const Color(0xFF26C6DA).withOpacity(0.25), const Color(0xFF26C6DA).withOpacity(0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY TABLE
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTable extends ConsumerWidget {
  final List<MeasurementLog> history;
  const _HistoryTable({required this.history});

  static const _color = Color(0xFF26C6DA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = history.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: ['Fecha', 'Peso', 'Cintura', '% Grasa'].asMap().entries.map((e) =>
                Expanded(
                  flex: e.key == 0 ? 2 : 1,
                  child: Text(e.value, style: GoogleFonts.firaCode(fontSize: 9, fontWeight: FontWeight.bold, color: _color, letterSpacing: 0.8)),
                ),
              ).toList(),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length > 10 ? 10 : list.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.05)),
            itemBuilder: (context, index) {
              final item = list[index];
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.withOpacity(0.1),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
                confirmDismiss: (_) async => showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                    content: const Text('¿Eliminar este registro?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.redAccent), child: const Text('Eliminar')),
                    ],
                  ),
                ),
                onDismissed: (_) {
                  final authUser = ref.read(authControllerProvider.notifier).currentUser;
                  if (authUser != null) {
                    ref.read(progressControllerProvider.notifier).deleteMeasurement(authUser.uid, item.id);
                  }
                },
                child: InkWell(
                  onTap: () {
                    final authUser = ref.read(authControllerProvider.notifier).currentUser;
                    if (authUser != null) {
                      final u = ref.read(currentUserStreamProvider).asData?.value;
                      if (u != null) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => MeasurementBottomSheet(user: u, existingLog: item),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(DateFormat('dd MMM').format(item.date), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60))),
                        Expanded(child: Text('${item.weight}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                        Expanded(child: Text(item.waistCircumference != null ? '${item.waistCircumference}' : '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13))),
                        Expanded(child: Text(item.bodyFatPercentage != null ? '${item.bodyFatPercentage?.toStringAsFixed(1)}%' : '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12))),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
