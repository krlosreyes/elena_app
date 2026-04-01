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
import 'package:elena_app/src/shared/domain/models/meal_log.dart';
import '../application/meal_controller.dart';

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

class _RegistroNutricionScreenState extends ConsumerState<RegistroNutricionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMilestoneIndex = 0;
  late AnimationController _donutController;
  late Animation<double> _donutAnimation;

  _MacroTotals _prevTotals = const _MacroTotals();

  @override
  void initState() {
    super.initState();
    _donutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _donutAnimation = CurvedAnimation(
      parent: _donutController,
      curve: Curves.easeOutBack,
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
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final metabolicState = ref.watch(metabolicHubProvider);
    final todayLogAsync = uid != null
        ? ref.watch(todayLogProvider(uid))
        : const AsyncValue<dynamic>.data(null);

    final activeMilestone = metabolicState.mealMilestones.isNotEmpty
        ? metabolicState.mealMilestones[_selectedMilestoneIndex.clamp(
            0, metabolicState.mealMilestones.length - 1)]
        : null;

    final categoryKey = activeMilestone?.label.contains('RUPTURA') == true
        ? 'Ruptura'
        : activeMilestone?.label.contains('SNACK') == true
            ? 'Snack'
            : 'Principal';

    final suggestionsAsync =
        ref.watch(categorySuggestionsProvider(categoryKey));
    final todayLog = todayLogAsync.valueOrNull;

    // ── Aggregate macros from mealEntries stream ─────────────────
    int totalCal = todayLog?.calories ?? 0;
    int totalProt = todayLog?.proteinGrams ?? 0;
    int totalCarb = todayLog?.carbsGrams ?? 0;
    int totalFat = todayLog?.fatGrams ?? 0;

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

    return Scaffold(
      backgroundColor: _bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          
          // PHASE 1: FEEDING TIMELINE (Interactive Dashboard Hub)
          SliverToBoxAdapter(
            child: _FeedingTimeline(
              milestones: metabolicState.mealMilestones,
              selectedIndex: _selectedMilestoneIndex,
              onSelect: (index) => setState(() => _selectedMilestoneIndex = index),
            ),
          ),

          // PHASE 2: DAILY PROGRESS (Macro Donut - Refined)
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _donutAnimation,
              builder: (context, child) {
                return _MacroDonut(
                  totals: totals,
                  animValue: _donutAnimation.value,
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // PHASE 3: DYNAMIC SUGGESTIONS & LOGGING
          _buildActionSection(metabolicState, uid, suggestionsAsync),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: _bgDark,
      expandedHeight: 80,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: _accentNeon,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'NUTRICIÓN METABÓLICA',
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(
    MetabolicState state,
    String? uid,
    AsyncValue<List<FoodSuggestion>> suggestionsAsync,
  ) {
    if (state.mealMilestones.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final currentMilestone = state.mealMilestones[
        _selectedMilestoneIndex.clamp(0, state.mealMilestones.length - 1)];
    
    return SliverMainAxisGroup(
      slivers: [
        // PHASE 3: SUGGESTED MEALS (Suggested-First / Adaptive)
        SliverToBoxAdapter(
          child: _buildSuggestionsSection(context, ref, suggestionsAsync),
        ),

        // PHASE 4: QUICK FAVORITES (One-Touch Registration)
        SliverToBoxAdapter(
          child: _buildQuickFavorites(context, ref, suggestionsAsync),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Text(
                  'SUGERENCIAS PARA ${currentMilestone.label.toUpperCase()}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.auto_awesome, color: _accentNeon, size: 14),
              ],
            ),
          ),
        ),

        suggestionsAsync.when(
          loading: () => SliverToBoxAdapter(child: _buildEmptySuggestions()),
          error: (_, __) => SliverToBoxAdapter(child: _buildEmptySuggestions()),
          data: (suggestions) {
            // Filter suggestions by current milestone category
            final filtered = suggestions.where((s) {
              final cat = s.category.label.toLowerCase();
              final label = currentMilestone.label.toLowerCase();
              if (label.contains('ruptura')) return cat == 'ruptura';
              if (label.contains('comida') || label.contains('principal')) return cat == 'principal';
              return cat == 'snack';
            }).toList();

            if (filtered.isEmpty) return SliverToBoxAdapter(child: _buildEmptySuggestions());

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sugg = suggestions[index];
                  return _FoodSuggestionCard(
                    suggestion: sugg,
                    onAdd: () async {
                      // Fast confirm logic
                    },
                  );
                },
                childCount: suggestions.length,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptySuggestions() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, color: Colors.white.withValues(alpha: 0.1), size: 48),
          const SizedBox(height: 16),
          Text(
            'Sincronizando con tu metabolismo...',
            style: GoogleFonts.publicSans(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🕒 FEEDING TIMELINE (DASHBOARD HUB)
// ─────────────────────────────────────────────────────────────
class _FeedingTimeline extends StatelessWidget {
  final List<MetabolicMilestone> milestones;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _FeedingTimeline({
    required this.milestones,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: milestones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final m = milestones[index];
          final isActive = index == selectedIndex;
          final isCompleted = m.isReached;

          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? _accentNeon.withValues(alpha: 0.1) : _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive 
                      ? _accentNeon.withValues(alpha: 0.3) 
                      : Colors.white.withValues(alpha: 0.05),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isCompleted ? _accentNeon : Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.timer_outlined,
                          size: 10,
                          color: isCompleted ? Colors.black : Colors.white30,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        m.label.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(m.absoluteHour),
                    style: GoogleFonts.publicSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isActive ? _accentNeon : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.isReached ? 'REGISTRADO' : 'PENDIENTE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      color: Colors.white24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(double absHour) {
    final hour = absHour.floor();
    final min = ((absHour - hour) * 60).round();
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
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
        color: _cardColor,
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        borderRadius: BorderRadius.circular(16),
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

// ─────────────────────────────────────────────────────────────
// 🍽 FOOD SUGGESTION CARD (DESIGN INVISIBLE)
// ─────────────────────────────────────────────────────────────
class _FoodSuggestionCard extends StatefulWidget {
  final FoodSuggestion suggestion;
  final Future<void> Function(double multiplier)? onAdd;

  const _FoodSuggestionCard({
    required this.suggestion,
    this.onAdd,
  });

  @override
  State<_FoodSuggestionCard> createState() => _FoodSuggestionCardState();
}

class _FoodSuggestionCardState extends State<_FoodSuggestionCard> {
  bool _loading = false;
  int _selectedPortionIndex = 1; // 0: Ligera, 1: Normal, 2: Generosa

  double get _multiplier => switch (_selectedPortionIndex) {
    0 => 0.7,
    1 => 1.0,
    2 => 1.3,
    _ => 1.0,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TagBadge(widget.suggestion.category.label, _accentNeon),
                          const SizedBox(width: 8),
                          if (widget.suggestion.preferencesMatch)
                            const Icon(Icons.verified, color: _accentNeon, size: 12),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.suggestion.name,
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _SmallMacro('${(widget.suggestion.macros.kcal * _multiplier).round()}kcal', Colors.white38),
                          const SizedBox(width: 12),
                          _SmallMacro('${(widget.suggestion.macros.protein * _multiplier).round()}g P', _colorProtein),
                          const SizedBox(width: 12),
                          _SmallMacro('${(widget.suggestion.macros.carbs * _multiplier).round()}g C', _colorCarbs),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _handleAdd(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _accentNeon,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: _accentNeon.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 1),
                      ],
                    ),
                    child: _loading 
                       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                       : const Icon(Icons.add, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          
          // FAST-TRACK PORTION SELECTOR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'PORCIÓN',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _SegmentedPicker(
                  options: const ['LIGERA', 'NORMAL', 'GENEROSA'],
                  selectedIndex: _selectedPortionIndex,
                  onChanged: (val) => setState(() => _selectedPortionIndex = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAdd() async {
    if (_loading || widget.onAdd == null) return;
    setState(() => _loading = true);
    try {
      await widget.onAdd!(_multiplier);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TagBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _SmallMacro extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallMacro(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedPicker({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final active = i == selectedIndex;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: active ? _accentNeon : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              options[i],
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: active ? Colors.black : Colors.white30,
              ),
            ),
          ),
        );
      }),
    );
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

// ─────────────────────────────────────────────────────────────
// 🚀 QUICK FAVORITES & PRIORITY BUTTONS
// ─────────────────────────────────────────────────────────────

extension _RegistroNutricionHelpers on _RegistroNutricionScreenState {
  Widget _buildQuickFavorites(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<FoodSuggestion>> suggestionsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            'REGISTRO RÁPIDO (FAVORITOS)',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white24,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _QuickPreferenceButton(
                icon: '🥩',
                label: 'POLLO',
                onTap: () => _handleQuickRegisterByName(ref, 'Pollo'),
              ),
              const SizedBox(width: 12),
              _QuickPreferenceButton(
                icon: '🍳',
                label: 'HUEVOS',
                onTap: () => _handleQuickRegisterByName(ref, 'Huevos'),
              ),
              const SizedBox(width: 12),
              _QuickPreferenceButton(
                icon: '🥑',
                label: 'AGUACATE',
                onTap: () => _handleQuickRegisterByName(ref, 'Aguacate'),
              ),
              const SizedBox(width: 12),
              _QuickPreferenceButton(
                icon: '🐟',
                label: 'SALMÓN',
                onTap: () => _handleQuickRegisterByName(ref, 'Salmón'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleQuickRegisterByName(WidgetRef ref, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registrando $name...'),
        backgroundColor: _accentNeon,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _QuickPreferenceButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _QuickPreferenceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
