import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/metabolic_hub_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../authentication/data/auth_repository.dart';
import '../../health/data/health_repository.dart';
import '../../../shared/domain/models/metabolic_milestone.dart';
import '../data/repositories/food_suggestions_repository.dart';
import '../domain/entities/food_suggestion.dart';
// import 'widgets/meal_registration_modal.dart'; // Unused

// ─────────────────────────────────────────────────────────────
// 🎨 PALETTE
// ─────────────────────────────────────────────────────────────
const _colorProtein = Color(0xFF00FF90);
const _colorCarbs = Color(0xFF00E5FF);
const _colorFat = Color(0xFFFFAA00);
const _colorPending = Color(0xFF2A2A2A);

// ─────────────────────────────────────────────────────────────
// 🔢 AGGREGATED MACRO MODEL (built from stream)
// ─────────────────────────────────────────────────────────────
class _MacroTotals {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  const _MacroTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  bool get hasMeals => calories > 0;

  int get totalG => proteinG + carbsG + fatG;

  double get proteinPct => totalG > 0 ? proteinG / totalG : 0.40;
  double get carbsPct => totalG > 0 ? carbsG / totalG : 0.30;
  double get fatPct => totalG > 0 ? fatG / totalG : 0.30;
}

// ─────────────────────────────────────────────────────────────
// 🖥 MAIN SCREEN (Stateful for animation)
// ─────────────────────────────────────────────────────────────
class RegistroNutricionScreen extends ConsumerStatefulWidget {
  const RegistroNutricionScreen({super.key});

  @override
  ConsumerState<RegistroNutricionScreen> createState() =>
      _RegistroNutricionScreenState();
}

class _RegistroNutricionScreenState
    extends ConsumerState<RegistroNutricionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _donutController;
  late Animation<double> _donutAnimation;

  _MacroTotals _prevTotals = const _MacroTotals();

  @override
  void initState() {
    super.initState();
    _donutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _donutAnimation = CurvedAnimation(
      parent: _donutController,
      curve: Curves.easeOutCubic,
    );
    _donutController.forward();
  }

  @override
  void dispose() {
    _donutController.dispose();
    super.dispose();
  }

  /// Trigger donut animation when a new meal arrives
  void _onNewMeal(_MacroTotals next) {
    if (next.calories != _prevTotals.calories) {
      _donutController.forward(from: 0);
      _prevTotals = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Suggested meals from Firestore (rotated) ─────────────────
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final suggestionsAsync = ref.watch(dailySuggestionsProvider);
    final repo = ref.watch(foodSuggestionsRepositoryProvider);
    final hub = ref.watch(metabolicHubProvider);
    final todayLogAsync = uid != null
        ? ref.watch(todayLogProvider(uid))
        : const AsyncValue<dynamic>.data(null);
    final todayLog = todayLogAsync.valueOrNull;

    // ── Aggregate macros from mealEntries stream ─────────────────
    // NOTE: the key is 'fats' (plural) as written by MealController
    int totalCal = todayLog?.calories ?? 0;
    int totalProt = todayLog?.proteinGrams ?? 0;
    int totalCarb = todayLog?.carbsGrams ?? 0;
    int totalFat = todayLog?.fatGrams ?? 0;

    // Fallback: sum from entries if aggregate fields are zero
    if (totalCal == 0) {
      for (final e in todayLog?.mealEntries ?? []) {
        totalCal += (e['calories'] as num? ?? 0).toInt();
        totalProt += (e['protein'] as num? ?? 0).toInt();
        totalCarb += (e['carbs'] as num? ?? 0).toInt();
        totalFat += ((e['fats'] ?? e['fat']) as num? ?? 0).toInt();
      }
    }

    final totals = _MacroTotals(
      calories: totalCal,
      proteinG: totalProt,
      carbsG: totalCarb,
      fatG: totalFat,
    );
    _onNewMeal(totals);

    // ── Build real timeline from meal entry timestamps ────────────
    final mealEntries = todayLog?.mealEntries ?? [];
    final milestones = hub.mealMilestones;
    final startHour = hub.startHour;

    return Scaffold(
      backgroundColor: const Color(0xFF060608),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ── FEEDING TIMELINE ─────────────────────────────────
            SliverToBoxAdapter(
              child: _FeedingTimeline(
                milestones: milestones,
                mealEntries: mealEntries,
                startHour: startHour,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── ANIMATED DONUT ───────────────────────────────────
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _donutAnimation,
                builder: (_, __) => _MacroDonut(
                  totals: totals,
                  animValue: _donutAnimation.value,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ── SECTION TITLE ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(width: 3, height: 16, color: _colorProtein),
                    const SizedBox(width: 10),
                    Text(
                      'COMIDAS SUGERIDAS',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── MEAL CARDS (rotated from Firestore) ───────────────
            suggestionsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: _colorProtein,
                      ),
                    ),
                  ),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: SizedBox.shrink(),
              ),
              data: (suggestions) {
                final nextMealIndex = hub.actualMeals;
                final bool isNextMealLocked = nextMealIndex > 0 &&
                    nextMealIndex < hub.mealMilestones.length &&
                    !hub.mealMilestones[nextMealIndex].isReached;

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _FoodSuggestionCard(
                      suggestion: suggestions[i],
                      locked: isNextMealLocked,
                      timeUntilNext: isNextMealLocked
                          ? _formatRealTime(
                              hub.mealMilestones[nextMealIndex].absoluteHour)
                          : null,
                      onAdd: (uid == null || isNextMealLocked)
                          ? null
                          : () async {
                              await repo.addToDaily(
                                uid: uid,
                                suggestion: suggestions[i],
                              );
                            },
                    ),
                    childCount: suggestions.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12), width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REGISTRO DE NUTRICIÓN',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                DateFormat('EEEE, dd MMM', 'es')
                    .format(DateTime.now())
                    .toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: _colorProtein.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.restaurant_outlined,
              color: _colorProtein.withValues(alpha: 0.6), size: 22),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ⏱ FEEDING TIMELINE
// ─────────────────────────────────────────────────────────────

class _TimelineItem {
  final String scheduledTime; // planned clock time from milestone geometry
  final String? loggedTime; // actual timestamp from Firestore (nullable)
  final String label;
  final bool isCompleted;

  const _TimelineItem({
    required this.scheduledTime,
    required this.label,
    required this.isCompleted,
    this.loggedTime,
  });

  /// Display time: prefer real logged time, fallback to scheduled
  String get displayTime => loggedTime ?? scheduledTime;
}

class _FeedingTimeline extends StatelessWidget {
  final List<MetabolicMilestone> milestones;
  final List<Map<String, dynamic>> mealEntries;
  final double startHour;

  const _FeedingTimeline({
    required this.milestones,
    required this.mealEntries,
    required this.startHour,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D10),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Row(
            children: [
              Container(width: 3, height: 14, color: _colorCarbs),
              const SizedBox(width: 8),
              Text(
                'VENTANA DE ALIMENTACIÓN',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              // Live badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _colorProtein.withValues(alpha: 0.08),
                  border: Border.all(
                      color: _colorProtein.withValues(alpha: 0.25), width: 1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: _colorProtein,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('LIVE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          color: _colorProtein,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dots row
          Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _TimelineDotWidget(item: items[i]),
                if (i < items.length - 1)
                  Expanded(
                    child: _Connector(
                      isCompleted: items[i].isCompleted,
                      nextCompleted: items[i + 1].isCompleted,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Labels row
          Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                SizedBox(
                  width: 70,
                  child: Column(
                    crossAxisAlignment: i == 0
                        ? CrossAxisAlignment.start
                        : (i == items.length - 1
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.center),
                    children: [
                      Text(
                        items[i].displayTime,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: items[i].isCompleted
                              ? _colorProtein
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      // Show "programado" tag if showing scheduled time
                      if (!items[i].isCompleted)
                        Text(
                          'PROGRAMADO',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 7,
                            color: Colors.white.withValues(alpha: 0.15),
                            letterSpacing: 0.5,
                          ),
                        ),
                      Text(
                        items[i].label,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          color: items[i].isCompleted
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.2),
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1) const Spacer(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<_TimelineItem> _buildItems() {
    final today = DateTime.now();
    final fmt = DateFormat('hh:mm a');

    // Fallback when no milestones loaded yet
    if (milestones.isEmpty) {
      return [
        const _TimelineItem(
            scheduledTime: '10:00 AM',
            label: 'ROMPER AYUNO',
            isCompleted: false),
        const _TimelineItem(
            scheduledTime: '02:00 PM', label: 'COMIDA 2', isCompleted: false),
        const _TimelineItem(
            scheduledTime: '07:00 PM', label: 'COMIDA 3', isCompleted: false),
      ];
    }

    return milestones.asMap().entries.map<_TimelineItem>((e) {
      final i = e.key;
      final m = e.value;

      // Planned clock time from geometry (PRECOMPUTED IN HUB)
      final absoluteHour = m.absoluteHour;
      final planned = DateTime(
        today.year,
        today.month,
        today.day,
        absoluteHour.floor(),
        ((absoluteHour - absoluteHour.floor()) * 60).round(),
      );
      final scheduledStr = fmt.format(planned);

      // Real timestamp from Firestore mealEntries[i] if exists
      String? loggedStr;
      if (i < mealEntries.length) {
        final entry = mealEntries[i];
        final tsRaw = entry['timestamp'];
        if (tsRaw != null) {
          try {
            // Check if it's a FireStore Timestamp or a String
            final DateTime logged;
            if (tsRaw is String) {
               logged = DateTime.parse(tsRaw).toLocal();
            } else if (tsRaw.runtimeType.toString().contains('Timestamp')) {
               // This is a dynamic check for non-imported Timestamp
               logged = (tsRaw as dynamic).toDate().toLocal();
            } else {
               logged = today; // Fallback
            }
            loggedStr = fmt.format(logged);
          } catch (_) {}
        }
      }

      return _TimelineItem(
        scheduledTime: scheduledStr,
        loggedTime: loggedStr,
        label: m.label.toUpperCase(),
        isCompleted: i < mealEntries.length,
      );
    }).toList();
  }
}

class _TimelineDotWidget extends StatelessWidget {
  final _TimelineItem item;
  const _TimelineDotWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final completed = item.isCompleted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed
            ? _colorProtein.withValues(alpha: 0.15)
            : const Color(0xFF1A1A1A),
        border: Border.all(
            color: completed ? _colorProtein : _colorPending,
            width: completed ? 2 : 1),
        boxShadow: completed
            ? [
                BoxShadow(
                  color: _colorProtein.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          completed ? Icons.check_rounded : Icons.restaurant_outlined,
          size: 14,
          color:
              completed ? _colorProtein : Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool isCompleted;
  final bool nextCompleted;
  const _Connector({required this.isCompleted, required this.nextCompleted});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 2,
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(colors: [
                _colorProtein,
                nextCompleted ? _colorProtein : _colorPending,
              ])
            : null,
        color: isCompleted ? null : _colorPending,
        boxShadow: isCompleted
            ? [
                BoxShadow(
                    color: _colorProtein.withValues(alpha: 0.35), blurRadius: 5)
              ]
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🍩 MACRO DONUT (animated)
// ─────────────────────────────────────────────────────────────
class _MacroDonut extends StatelessWidget {
  final _MacroTotals totals;
  final double animValue; // 0→1 drives the sweep angles

  const _MacroDonut({required this.totals, required this.animValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D10),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, color: _colorFat),
              const SizedBox(width: 8),
              Text(
                'COMPOSICIÓN CALÓRICA',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              if (!totals.hasMeals)
                Text(
                  'SIN REGISTROS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.2),
                    letterSpacing: 1.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Donut
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(150, 150),
                      painter: _DonutPainter(
                        proteinPct: totals.proteinPct * animValue,
                        carbsPct: totals.carbsPct * animValue,
                        fatPct: totals.fatPct * animValue,
                        hasMeals: totals.hasMeals,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          totals.hasMeals ? totals.calories.toString() : '---',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text('KCAL',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.4),
                              letterSpacing: 2,
                            )),
                        Text('100%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.2),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              // Legend
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MacroLegendItem(
                    icon: '🥩',
                    label: 'PROTEÍNA',
                    color: _colorProtein,
                    percent: (totals.proteinPct * 100).round(),
                    grams: totals.proteinG,
                  ),
                  const SizedBox(height: 16),
                  _MacroLegendItem(
                    icon: '🍚',
                    label: 'CARBOHIDRATOS',
                    color: _colorCarbs,
                    percent: (totals.carbsPct * 100).round(),
                    grams: totals.carbsG,
                  ),
                  const SizedBox(height: 16),
                  _MacroLegendItem(
                    icon: '🥑',
                    label: 'GRASAS',
                    color: _colorFat,
                    percent: (totals.fatPct * 100).round(),
                    grams: totals.fatG,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroLegendItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final int percent;
  final int grams;

  const _MacroLegendItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.percent,
    required this.grams,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$icon $label',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$percent%',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 18,
                        color: color,
                        fontWeight: FontWeight.w900),
                  ),
                  TextSpan(
                    text: '  ${grams}g',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🎨 DONUT PAINTER
// ─────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double proteinPct;
  final double carbsPct;
  final double fatPct;
  final bool hasMeals;

  const _DonutPainter({
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
    required this.hasMeals,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeW = 18.0;
    const gap = 0.04;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1A1A1E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    if (!hasMeals) return;

    final segments = [
      (proteinPct, _colorProtein),
      (carbsPct, _colorCarbs),
      (fatPct, _colorFat),
    ];

    double startAngle = -math.pi / 2;
    for (final (pct, color) in segments) {
      final sweep = (2 * math.pi * pct) - gap;
      if (sweep <= 0) continue;

      final rect = Rect.fromCircle(center: center, radius: radius);

      // Glow
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Solid arc
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );

      startAngle += 2 * math.pi * pct;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.proteinPct != proteinPct ||
      old.carbsPct != carbsPct ||
      old.fatPct != fatPct;
}

  String _formatRealTime(double absoluteHour) {
    final hour = absoluteHour.floor();
    final minute = ((absoluteHour - hour) * 60).round();
    final today = DateTime.now();
    final time = DateTime(today.year, today.month, today.day, hour, minute);
    return DateFormat('hh:mm a').format(time);
  }

// ─────────────────────────────────────────────────────────────
// 🍽 FOOD SUGGESTION CARD (from Firestore)
// ─────────────────────────────────────────────────────────────
class _FoodSuggestionCard extends StatefulWidget {
  final FoodSuggestion suggestion;
  final Future<void> Function()? onAdd;
  final bool locked;
  final String? timeUntilNext;

  const _FoodSuggestionCard({
    required this.suggestion,
    this.onAdd,
    this.locked = false,
    this.timeUntilNext,
  });

  @override
  State<_FoodSuggestionCard> createState() => _FoodSuggestionCardState();
}

class _FoodSuggestionCardState extends State<_FoodSuggestionCard> {
  bool _loading = false;
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: widget.locked ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D10),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: widget.locked
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              widget.suggestion.category.label.toUpperCase(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.locked)
                            const Icon(Icons.lock_clock,
                                color: Colors.white24, size: 12),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.suggestion.name,
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _MacroBadge('${widget.suggestion.macros.kcal} KCAL',
                              Colors.white70),
                          const SizedBox(width: 6),
                          _MacroBadge('${widget.suggestion.macros.protein} P',
                              _colorProtein),
                          const SizedBox(width: 6),
                          _MacroBadge(
                              '${widget.suggestion.macros.carbs} C', _colorCarbs),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.locked)
                      Text(
                        widget.timeUntilNext ?? 'BLOQUEADO',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          color: Colors.white24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    _AddButton(
                      loading: _loading,
                      added: _added,
                      onTap: _handleAdd,
                      locked: widget.locked,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAdd() async {
    if (_loading || _added || widget.onAdd == null || widget.locked) return;
    setState(() => _loading = true);
    try {
      await widget.onAdd!();
      if (mounted) {
        setState(() {
          _loading = false;
          _added = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('❌ Error adding suggestion to daily: $e');
    }
  }
}

class _AddButton extends StatelessWidget {
  final bool loading;
  final bool added;
  final bool locked;
  final VoidCallback onTap;

  const _AddButton({
    required this.loading,
    required this.added,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked 
        ? Colors.white12
        : (added ? Colors.white.withValues(alpha: 0.3) : _colorProtein);

    return GestureDetector(
      onTap: (loading || added || locked) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: loading
            ? SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: _colorProtein),
              )
            : Text(
                added ? '✓ LISTO' : 'AÑADIR',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🏷 MACRO BADGE
// ─────────────────────────────────────────────────────────────
class _MacroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
