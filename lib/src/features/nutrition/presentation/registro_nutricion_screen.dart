import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/metabolic_hub_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elena_header.dart';
import '../../../domain/logic/elena_brain.dart';
import '../../../shared/domain/models/meal_log.dart';
import '../../../shared/domain/models/metabolic_milestone.dart';
import '../../../shared/domain/models/user_model.dart';
import '../../fasting/application/fasting_controller.dart';
import '../../health/data/health_repository.dart';
import '../../health/domain/daily_log.dart';
import '../../profile/application/user_controller.dart';
import '../application/meal_controller.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 🎨 DESIGN SYSTEM — Plato de Proporciones Metabólicas
// ═══════════════════════════════════════════════════════════════════════════════

const _bgDark = Color(0xFF09090B);
const _cardColor = Color(0xFF131317);

// Colores de los 3 sectores del plato
const _colorVegetales = Color(0xFF39FF14); // Verde neón — 50%
const _colorProteina = Color(0xFF00D2FF); // Cyan — 25%
const _colorEnergia = Color(0xFFFFAA00); // Ámbar — 25%

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS & MODELS
// ═══════════════════════════════════════════════════════════════════════════════

enum _PlateSection { vegetales, proteina, energia }

enum _GlycemicImpact { bajo, medio, alto }

extension _GlycemicImpactX on _GlycemicImpact {
  String get label => switch (this) {
        _GlycemicImpact.bajo => 'BAJO',
        _GlycemicImpact.medio => 'MEDIO',
        _GlycemicImpact.alto => 'ALTO',
      };
  Color get color => switch (this) {
        _GlycemicImpact.bajo => _colorVegetales,
        _GlycemicImpact.medio => _colorEnergia,
        _GlycemicImpact.alto => Colors.redAccent,
      };
  IconData get icon => switch (this) {
        _GlycemicImpact.bajo => Icons.trending_flat,
        _GlycemicImpact.medio => Icons.trending_up,
        _GlycemicImpact.alto => Icons.warning_amber_rounded,
      };
}

/// Alimento seleccionado para el plato
class _PlateItem {
  final String name;
  final String emoji;
  final _PlateSection section;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  const _PlateItem({
    required this.name,
    required this.emoji,
    required this.section,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// ALIMENTOS FRECUENTES POR SECTOR (Defaults)
// ═══════════════════════════════════════════════════════════════════════════════

const _defaultVegetales = [
  _PlateItem(
    name: 'Ensalada',
    emoji: '🥗',
    section: _PlateSection.vegetales,
    kcal: 45,
    protein: 2,
    carbs: 8,
    fat: 1,
  ),
  _PlateItem(
    name: 'Brócoli',
    emoji: '🥦',
    section: _PlateSection.vegetales,
    kcal: 55,
    protein: 4,
    carbs: 11,
    fat: 1,
  ),
  _PlateItem(
    name: 'Espinacas',
    emoji: '🌿',
    section: _PlateSection.vegetales,
    kcal: 23,
    protein: 3,
    carbs: 4,
    fat: 0,
  ),
  _PlateItem(
    name: 'Tomate',
    emoji: '🍅',
    section: _PlateSection.vegetales,
    kcal: 22,
    protein: 1,
    carbs: 5,
    fat: 0,
  ),
  _PlateItem(
    name: 'Pepino',
    emoji: '🥒',
    section: _PlateSection.vegetales,
    kcal: 16,
    protein: 1,
    carbs: 4,
    fat: 0,
  ),
  _PlateItem(
    name: 'Champiñones',
    emoji: '🍄',
    section: _PlateSection.vegetales,
    kcal: 22,
    protein: 3,
    carbs: 3,
    fat: 0,
  ),
  _PlateItem(
    name: 'Zanahoria',
    emoji: '🥕',
    section: _PlateSection.vegetales,
    kcal: 41,
    protein: 1,
    carbs: 10,
    fat: 0,
  ),
  _PlateItem(
    name: 'Pimiento',
    emoji: '🫑',
    section: _PlateSection.vegetales,
    kcal: 31,
    protein: 1,
    carbs: 6,
    fat: 0,
  ),
];

const _defaultProteina = [
  _PlateItem(
    name: 'Pollo',
    emoji: '🍗',
    section: _PlateSection.proteina,
    kcal: 165,
    protein: 31,
    carbs: 0,
    fat: 4,
  ),
  _PlateItem(
    name: 'Huevos',
    emoji: '🥚',
    section: _PlateSection.proteina,
    kcal: 155,
    protein: 13,
    carbs: 1,
    fat: 11,
  ),
  _PlateItem(
    name: 'Salmón',
    emoji: '🐟',
    section: _PlateSection.proteina,
    kcal: 208,
    protein: 20,
    carbs: 0,
    fat: 13,
  ),
  _PlateItem(
    name: 'Atún',
    emoji: '🐟',
    section: _PlateSection.proteina,
    kcal: 132,
    protein: 28,
    carbs: 0,
    fat: 1,
  ),
  _PlateItem(
    name: 'Carne res',
    emoji: '🥩',
    section: _PlateSection.proteina,
    kcal: 250,
    protein: 26,
    carbs: 0,
    fat: 15,
  ),
  _PlateItem(
    name: 'Yogurt',
    emoji: '🫙',
    section: _PlateSection.proteina,
    kcal: 100,
    protein: 17,
    carbs: 6,
    fat: 1,
  ),
  _PlateItem(
    name: 'Queso',
    emoji: '🧀',
    section: _PlateSection.proteina,
    kcal: 113,
    protein: 7,
    carbs: 0,
    fat: 9,
  ),
  _PlateItem(
    name: 'Camarones',
    emoji: '🦐',
    section: _PlateSection.proteina,
    kcal: 99,
    protein: 24,
    carbs: 0,
    fat: 0,
  ),
];

const _defaultEnergia = [
  _PlateItem(
    name: 'Arroz',
    emoji: '🍚',
    section: _PlateSection.energia,
    kcal: 206,
    protein: 4,
    carbs: 45,
    fat: 0,
  ),
  _PlateItem(
    name: 'Papa',
    emoji: '🥔',
    section: _PlateSection.energia,
    kcal: 161,
    protein: 4,
    carbs: 37,
    fat: 0,
  ),
  _PlateItem(
    name: 'Aguacate',
    emoji: '🥑',
    section: _PlateSection.energia,
    kcal: 160,
    protein: 2,
    carbs: 9,
    fat: 15,
  ),
  _PlateItem(
    name: 'Avena',
    emoji: '🥣',
    section: _PlateSection.energia,
    kcal: 154,
    protein: 5,
    carbs: 27,
    fat: 3,
  ),
  _PlateItem(
    name: 'Pan integral',
    emoji: '🍞',
    section: _PlateSection.energia,
    kcal: 79,
    protein: 4,
    carbs: 14,
    fat: 1,
  ),
  _PlateItem(
    name: 'Aceite oliva',
    emoji: '🫒',
    section: _PlateSection.energia,
    kcal: 119,
    protein: 0,
    carbs: 0,
    fat: 14,
  ),
  _PlateItem(
    name: 'Plátano',
    emoji: '🍌',
    section: _PlateSection.energia,
    kcal: 105,
    protein: 1,
    carbs: 27,
    fat: 0,
  ),
  _PlateItem(
    name: 'Nueces',
    emoji: '🥜',
    section: _PlateSection.energia,
    kcal: 185,
    protein: 4,
    carbs: 4,
    fat: 18,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// 🖥 MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class RegistroNutricionScreen extends ConsumerStatefulWidget {
  const RegistroNutricionScreen({super.key});

  @override
  ConsumerState<RegistroNutricionScreen> createState() =>
      _RegistroNutricionScreenState();
}

class _RegistroNutricionScreenState
    extends ConsumerState<RegistroNutricionScreen> {
  // Estado del plato
  int _selectedMealIndex = 0; // Índice del milestone seleccionado
  final List<_PlateItem> _selectedVegetales = [];
  final List<_PlateItem> _selectedProteinas = [];
  final List<_PlateItem> _selectedEnergias = [];
  _PlateSection? _activeSection;
  bool _showAdviceCard = true; // NEW: Track visibility of the advice card
  bool _isRegistering = false;

  // ── Proporciones del plato ─────────────────────────────────────────────
  bool get _hasVegetal => _selectedVegetales.isNotEmpty;
  bool get _hasProteina => _selectedProteinas.isNotEmpty;
  bool get _hasEnergia => _selectedEnergias.isNotEmpty;
  int get _filledSectors =>
      (_hasVegetal ? 1 : 0) + (_hasProteina ? 1 : 0) + (_hasEnergia ? 1 : 0);
  bool get _plateComplete => _filledSectors == 3;

  /// Equilibrado = 3 sectores llenos + vegetales ≥ energía en items
  /// + proteína aporta al menos 20% de las kcal totales
  bool get _proportionsMet {
    if (!_plateComplete) return false;
    // Los vegetales deben ser ≥ la energía en cantidad de items
    if (_selectedVegetales.length < _selectedEnergias.length) return false;
    // Proteína debe aportar al menos 20% de kcal totales
    final totalKcal = _totalKcal;
    if (totalKcal == 0) return false;
    final protKcal = _selectedProteinas.fold<int>(0, (s, i) => s + i.kcal);
    if (protKcal / totalKcal < 0.18) return false;
    return true;
  }

  /// Ratio carbos/proteína para evaluar impacto glucémico
  _GlycemicImpact get _glycemicImpact {
    final carbs = _totalCarbs;
    final prot = _totalProtein;
    final vegItems = _selectedVegetales.length;
    final eneItems = _selectedEnergias.length;

    // Sin energía → siempre bajo
    if (!_hasEnergia) return _GlycemicImpact.bajo;

    // Ratio carbos:proteína
    final ratio = prot > 0 ? carbs / prot : 99.0;

    // Exceso de carbos sin suficiente fibra/proteína
    if (ratio > 4.0 || (eneItems > 3 && vegItems < 2)) {
      return _GlycemicImpact.alto;
    }
    if (ratio > 2.5 || eneItems > vegItems) {
      return _GlycemicImpact.medio;
    }
    return _GlycemicImpact.bajo;
  }

  String get _plateVerdict {
    if (_filledSectors == 0) return 'Toca un sector del plato para empezar';

    // Alertas de exceso — prioridad alta
    if (_hasEnergia && _selectedEnergias.length > 2 && !_hasVegetal) {
      return 'Demasiada energía sin fibra — pico de glucosa';
    }
    if (_hasEnergia &&
        _selectedEnergias.length > _selectedVegetales.length + 1) {
      return 'Exceso de carbos — agrega más vegetales';
    }
    if (_totalCarbs > 0 &&
        _totalProtein > 0 &&
        _totalCarbs / _totalProtein > 4) {
      return 'Ratio carbos/proteína muy alto — agrega proteína';
    }

    // Equilibrio logrado
    if (_proportionsMet) return 'Tu plato está equilibrado';

    // Sectores faltantes
    if (_hasEnergia && !_hasVegetal) {
      return 'Falta fibra para amortiguar la glucosa';
    }
    if (_hasEnergia && !_hasProteina) {
      return 'Agrega proteína para mayor saciedad';
    }
    if (!_hasVegetal) return 'Agrega vegetales — son tu escudo metabólico';
    if (!_hasProteina) return 'Falta proteína — tu músculo la necesita';
    if (!_hasEnergia) return 'Puedes agregar energía o registrar así';
    return 'Completa tu plato';
  }

  int get _totalKcal =>
      _selectedVegetales.fold<int>(0, (s, i) => s + i.kcal) +
      _selectedProteinas.fold<int>(0, (s, i) => s + i.kcal) +
      _selectedEnergias.fold<int>(0, (s, i) => s + i.kcal);

  int get _totalProtein =>
      _selectedVegetales.fold<int>(0, (s, i) => s + i.protein) +
      _selectedProteinas.fold<int>(0, (s, i) => s + i.protein) +
      _selectedEnergias.fold<int>(0, (s, i) => s + i.protein);

  int get _totalCarbs =>
      _selectedVegetales.fold<int>(0, (s, i) => s + i.carbs) +
      _selectedProteinas.fold<int>(0, (s, i) => s + i.carbs) +
      _selectedEnergias.fold<int>(0, (s, i) => s + i.carbs);

  int get _totalFat =>
      _selectedVegetales.fold<int>(0, (s, i) => s + i.fat) +
      _selectedProteinas.fold<int>(0, (s, i) => s + i.fat) +
      _selectedEnergias.fold<int>(0, (s, i) => s + i.fat);

  /// Derivar MealType desde el índice del milestone seleccionado
  MealType get _selectedMealType {
    final milestones = ref.read(metabolicHubProvider).mealMilestones;
    if (milestones.isEmpty) return MealType.lunch;
    // Primer milestone = desayuno/ruptura, último = cena, medio = almuerzo
    if (_selectedMealIndex == 0) return MealType.breakfast;
    if (_selectedMealIndex >= milestones.length - 1) return MealType.dinner;
    return MealType.lunch;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final hub = ref.watch(metabolicHubProvider);
    final log =
        user != null ? ref.watch(todayLogProvider(user.uid)).valueOrNull : null;
    final fastingState = ref.watch(fastingControllerProvider).valueOrNull;
    final isFasting = fastingState?.isFasting ?? true;

    return Scaffold(
      backgroundColor: _bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── HEADER ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: user != null
                  ? ElenaHeader(title: 'NUTRICIÓN METABÓLICA', user: user)
                  : const SizedBox.shrink(),
            ),
          ),

          // ─── FEEDING WINDOW TIMELINE ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _FeedingWindowTimeline(
                milestones: hub.mealMilestones,
                actualMeals: hub.actualMeals,
                selectedIndex: _selectedMealIndex,
                onSelect: (index) => setState(() => _selectedMealIndex = index),
              ),
            ),
          ),

          // ─── PLATE VERDICT (Advisory Message) ───────────────────
          if (_showAdviceCard && !isFasting)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _PlateVerdict(
                  message: _plateVerdict,
                  impact: _filledSectors > 0 ? _glycemicImpact : null,
                  onDismiss: () => setState(() => _showAdviceCard = false),
                ),
              ),
            ),

          // ─── METABOLIC PLATE ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: isFasting
                  ? _buildLockedPlate()
                  : _MetabolicPlateCard(
                      selectedVegetales: _selectedVegetales,
                      selectedProteinas: _selectedProteinas,
                      selectedEnergias: _selectedEnergias,
                      activeSection: _activeSection,
                      proportionsMet: _proportionsMet,
                      onSectionTap: (section) {
                        setState(() {
                          _activeSection =
                              _activeSection == section ? null : section;
                        });
                      },
                    ),
            ),
          ),

          // ─── QUICK FOOD SELECTOR (expanded sector) ───────────────
          if (_activeSection != null && !isFasting)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _QuickFoodGrid(
                  section: _activeSection!,
                  selectedItems: switch (_activeSection!) {
                    _PlateSection.vegetales => _selectedVegetales,
                    _PlateSection.proteina => _selectedProteinas,
                    _PlateSection.energia => _selectedEnergias,
                  },
                  onToggle: (item) {
                    setState(() {
                      switch (item.section) {
                        case _PlateSection.vegetales:
                          _toggleItem(_selectedVegetales, item);
                        case _PlateSection.proteina:
                          _toggleItem(_selectedProteinas, item);
                        case _PlateSection.energia:
                          _toggleItem(_selectedEnergias, item);
                      }
                    });
                  },
                ),
              ),
            ),

          // ─── MACRO SUMMARY ───────────────────────────────────────
          if (_filledSectors > 0 && !isFasting)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _MacroSummaryBar(
                  kcal: _totalKcal,
                  protein: _totalProtein,
                  carbs: _totalCarbs,
                  fat: _totalFat,
                ),
              ),
            ),

          // ─── REGISTER BUTTON ─────────────────────────────────────
          if (_filledSectors > 0 && !isFasting)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _RegisterButton(
                  isReady: _filledSectors >= 2,
                  isLoading: _isRegistering,
                  mealType: _selectedMealType,
                  onTap: _filledSectors >= 2 ? _handleRegister : null,
                ),
              ),
            ),

          // ─── COMPOSICIÓN METABÓLICA (daily totals / fasting guide) ────
          if (user != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _MetabolicMacrosCard(user: user, log: log),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  // ─── LOCKED PLATE (during fasting) ─────────────────────────────────
  Widget _buildLockedPlate() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Título
          Row(
            children: [
              Container(width: 3, height: 14, color: Colors.white24),
              const SizedBox(width: 8),
              Text(
                'PLATO METABÓLICO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.25),
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '🔒 EN AYUNO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Plato bloqueado — desaturado con candado
          Opacity(
            opacity: 0.25,
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _PlatePainter(
                  hasVegetal: false,
                  hasProteina: false,
                  hasEnergia: false,
                  activeSection: null,
                  proportionsMet: false,
                ),
                child: const Center(
                  child: Text('🔒', style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Ventana de ayuno activa',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'El plato se activa al iniciar tu ventana\n'
            'de alimentación. Mientras tanto, tu cuerpo\n'
            'está optimizando la quema de grasa.',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.3),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Toggle un alimento en la lista (agregar o quitar)
  void _toggleItem(List<_PlateItem> list, _PlateItem item) {
    final index = list.indexWhere((e) => e.name == item.name);
    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.add(item);
    }
  }

  Future<void> _handleRegister() async {
    if (_isRegistering || _filledSectors < 2) return;
    setState(() => _isRegistering = true);

    final parts = <String>[];
    for (final p in _selectedProteinas) {
      parts.add(p.name);
    }
    for (final v in _selectedVegetales) {
      parts.add(v.name);
    }
    for (final e in _selectedEnergias) {
      parts.add(e.name);
    }
    final mealName = parts.join(' + ');

    final impactLabel = _glycemicImpact.label;

    final success =
        await ref.read(mealControllerProvider.notifier).registerMeal(
              name: mealName,
              type: _selectedMealType,
              calories: _totalKcal,
              protein: _totalProtein,
              carbs: _totalCarbs,
              fat: _totalFat,
            );

    if (mounted) {
      setState(() => _isRegistering = false);

      if (success) {
        setState(() {
          _selectedVegetales.clear();
          _selectedProteinas.clear();
          _selectedEnergias.clear();
          _activeSection = null;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ $mealName registrado — Impacto $impactLabel'
                : '❌ El protocolo no permite más comidas ahora',
          ),
          backgroundColor: success ? AppTheme.primary : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🕐 FEEDING WINDOW TIMELINE — Ventana de Alimentación con milestones
// ═══════════════════════════════════════════════════════════════════════════════

class _FeedingWindowTimeline extends StatelessWidget {
  final List<MetabolicMilestone> milestones;
  final int actualMeals;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _FeedingWindowTimeline({
    required this.milestones,
    required this.actualMeals,
    required this.selectedIndex,
    required this.onSelect,
  });

  String _formatHour(double absoluteHour) {
    final h = absoluteHour.floor() % 12 == 0 ? 12 : absoluteHour.floor() % 12;
    final m = ((absoluteHour % 1) * 60).round();
    final ampm = absoluteHour >= 12 && absoluteHour < 24 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';
  }

  String _mealLabel(int index, int total) {
    if (index == 0) return 'Romper Ayuno';
    if (total <= 2) return 'Comida Principal';
    if (index == 1) return 'Comida Principal';
    return 'Comida ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Ventana de Alimentación',
            style: GoogleFonts.publicSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${milestones.length} comidas en tu protocolo',
            style: GoogleFonts.publicSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 24),

          // Timeline bar + dots
          SizedBox(
            height: 80,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final count = milestones.length;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background track
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 10,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Progress track (filled up to actualMeals)
                    if (actualMeals > 0)
                      Positioned(
                        left: 0,
                        top: 10,
                        child: Container(
                          height: 4,
                          width: count > 1
                              ? ((actualMeals - 1) / (count - 1)).clamp(
                                    0.0,
                                    1.0,
                                  ) *
                                  totalWidth
                              : totalWidth,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Milestone dots + labels
                    for (int i = 0; i < count; i++)
                      Positioned(
                        left: count > 1
                            ? (i / (count - 1)) * (totalWidth - 24)
                            : (totalWidth - 24) / 2,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => onSelect(i),
                          child: SizedBox(
                            width: 24,
                            child: Column(
                              children: [
                                // Dot
                                _TimelineDot(
                                  isReached: milestones[i].isReached,
                                  isSelected: i == selectedIndex,
                                  isNext: i == actualMeals,
                                ),
                                const SizedBox(height: 8),
                                // Hour
                                Text(
                                  _formatHour(milestones[i].absoluteHour),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: milestones[i].isReached
                                        ? AppTheme.primary
                                        : Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Label
                                Text(
                                  _mealLabel(i, count),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.publicSans(
                                    fontSize: 8,
                                    color: milestones[i].isReached
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: 0.25),
                                    fontWeight: i == selectedIndex
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final bool isReached;
  final bool isSelected;
  final bool isNext;

  const _TimelineDot({
    required this.isReached,
    required this.isSelected,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 18.0 : 14.0;

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isReached
              ? AppTheme.primary
              : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : isReached
                    ? AppTheme.primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isReached
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🥗 METABOLIC PLATE CARD — Plato circular 3 sectores interactivo
// ═══════════════════════════════════════════════════════════════════════════════

class _MetabolicPlateCard extends StatelessWidget {
  final List<_PlateItem> selectedVegetales;
  final List<_PlateItem> selectedProteinas;
  final List<_PlateItem> selectedEnergias;
  final _PlateSection? activeSection;
  final bool proportionsMet;
  final ValueChanged<_PlateSection> onSectionTap;

  const _MetabolicPlateCard({
    required this.selectedVegetales,
    required this.selectedProteinas,
    required this.selectedEnergias,
    required this.activeSection,
    required this.proportionsMet,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasVeg = selectedVegetales.isNotEmpty;
    final hasProt = selectedProteinas.isNotEmpty;
    final hasEne = selectedEnergias.isNotEmpty;

    final borderColor = proportionsMet
        ? _colorVegetales.withValues(alpha: 0.5)
        : _colorEnergia.withValues(alpha: 0.3);

    final int filled = (hasVeg ? 1 : 0) + (hasProt ? 1 : 0) + (hasEne ? 1 : 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              filled == 0 ? Colors.white.withValues(alpha: 0.05) : borderColor,
          width: filled > 0 && proportionsMet ? 1.5 : 1,
        ),
        boxShadow: proportionsMet
            ? [
                BoxShadow(
                  color: _colorVegetales.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Título
          Row(
            children: [
              Container(width: 3, height: 14, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'PLATO METABÓLICO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (proportionsMet)
                Row(
                  children: [
                    Icon(Icons.check_circle, color: _colorVegetales, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'EQUILIBRADO',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        color: _colorVegetales,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Plato circular
          SizedBox(
            width: 220,
            height: 220,
            child: GestureDetector(
              onTapUp: (details) {
                final center = const Offset(110, 110);
                final dx = details.localPosition.dx - center.dx;
                final dy = details.localPosition.dy - center.dy;
                // atan2 devuelve [-π, +π]. Comparar directo con rangos del painter:
                // Vegetales: startAngle -π/2, sweep π → rango [-π/2, +π/2)
                // Proteína:  startAngle +π/2, sweep π/2 → rango [+π/2, +π)
                // Energía:   startAngle +π,   sweep π/2 → rango [+π, +3π/2) ≡ [-π, -π/2)
                final angle = math.atan2(dy, dx);

                if (angle >= -math.pi / 2 && angle < math.pi / 2) {
                  onSectionTap(_PlateSection.vegetales);
                } else if (angle >= math.pi / 2 && angle < math.pi) {
                  onSectionTap(_PlateSection.proteina);
                } else {
                  // angle >= π || angle < -π/2 → cuadrante superior-izquierdo
                  onSectionTap(_PlateSection.energia);
                }
              },
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _PlatePainter(
                  hasVegetal: hasVeg,
                  hasProteina: hasProt,
                  hasEnergia: hasEne,
                  activeSection: activeSection,
                  proportionsMet: proportionsMet,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Labels dentro del plato — centrados en cada sector
                    // Vegetales: sector [-π/2, +π/2] → centro = 0 (derecha)
                    // Pero 0 queda en el borde, usamos un ángulo ligeramente
                    // hacia abajo para mejor lectura visual
                    _PlateLabel(
                      angle: math.pi * 0.25,
                      radius: 55,
                      center: const Offset(110, 110),
                      emoji: hasVeg ? selectedVegetales.first.emoji : '🥗',
                      label: hasVeg
                          ? selectedVegetales.map((e) => e.name).join(', ')
                          : 'Vegetales',
                      sublabel: '50%',
                      filled: hasVeg,
                    ),
                    // Proteína: sector [+π/2, +π] → centro = +3π/4 (abajo-izquierda)
                    _PlateLabel(
                      angle: math.pi * 0.75,
                      radius: 55,
                      center: const Offset(110, 110),
                      emoji: hasProt ? selectedProteinas.first.emoji : '🥩',
                      label: hasProt
                          ? selectedProteinas.map((e) => e.name).join(', ')
                          : 'Proteína',
                      sublabel: '25%',
                      filled: hasProt,
                    ),
                    // Energía: sector [+π, +3π/2] → centro = -3π/4 (arriba-izquierda)
                    _PlateLabel(
                      angle: -math.pi * 0.75,
                      radius: 55,
                      center: const Offset(110, 110),
                      emoji: hasEne ? selectedEnergias.first.emoji : '⚡',
                      label: hasEne
                          ? selectedEnergias.map((e) => e.name).join(', ')
                          : 'Energía',
                      sublabel: '25%',
                      filled: hasEne,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLATE PAINTER — CustomPainter para el plato circular
// ═══════════════════════════════════════════════════════════════════════════════

class _PlatePainter extends CustomPainter {
  final bool hasVegetal;
  final bool hasProteina;
  final bool hasEnergia;
  final _PlateSection? activeSection;
  final bool proportionsMet;

  _PlatePainter({
    required this.hasVegetal,
    required this.hasProteina,
    required this.hasEnergia,
    required this.activeSection,
    required this.proportionsMet,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const gap = 0.03;

    // Borde exterior del plato
    final borderPaint = Paint()
      ..color = proportionsMet
          ? _colorVegetales.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius + 4, borderPaint);

    // Sectores
    final rect = Rect.fromCircle(center: center, radius: radius);

    _drawSector(
      canvas,
      rect,
      center,
      radius,
      startAngle: -math.pi / 2,
      sweepAngle: math.pi - gap,
      color: _colorVegetales,
      filled: hasVegetal,
      isActive: activeSection == _PlateSection.vegetales,
    );

    _drawSector(
      canvas,
      rect,
      center,
      radius,
      startAngle: math.pi / 2 + gap / 2,
      sweepAngle: math.pi / 2 - gap,
      color: _colorProteina,
      filled: hasProteina,
      isActive: activeSection == _PlateSection.proteina,
    );

    _drawSector(
      canvas,
      rect,
      center,
      radius,
      startAngle: math.pi + gap / 2,
      sweepAngle: math.pi / 2 - gap,
      color: _colorEnergia,
      filled: hasEnergia,
      isActive: activeSection == _PlateSection.energia,
    );
  }

  void _drawSector(
    Canvas canvas,
    Rect rect,
    Offset center,
    double radius, {
    required double startAngle,
    required double sweepAngle,
    required Color color,
    required bool filled,
    required bool isActive,
  }) {
    // Fondo del sector
    final bgPaint = Paint()
      ..color =
          filled ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, startAngle, sweepAngle, true, bgPaint);

    // Borde del sector
    final strokePaint = Paint()
      ..color = isActive
          ? color.withValues(alpha: 0.8)
          : filled
              ? color.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 2.5 : 1.5;
    canvas.drawArc(rect, startAngle, sweepAngle, true, strokePaint);

    // Glow si está activo
    if (isActive) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawArc(rect, startAngle, sweepAngle, true, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlatePainter old) =>
      old.hasVegetal != hasVegetal ||
      old.hasProteina != hasProteina ||
      old.hasEnergia != hasEnergia ||
      old.activeSection != activeSection ||
      old.proportionsMet != proportionsMet;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLATE LABEL — Emoji + nombre posicionado dentro de un sector
// ═══════════════════════════════════════════════════════════════════════════════

class _PlateLabel extends StatelessWidget {
  final double angle;
  final double radius;
  final Offset center;
  final String emoji;
  final String label;
  final String sublabel;
  final bool filled;

  const _PlateLabel({
    required this.angle,
    required this.radius,
    required this.center,
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final dx = center.dx + radius * math.cos(angle) - 28;
    final dy = center.dy + radius * math.sin(angle) - 20;

    return Positioned(
      left: dx,
      top: dy,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 7,
                fontWeight: filled ? FontWeight.bold : FontWeight.normal,
                color: filled
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.3),
                letterSpacing: 0.5,
              ),
            ),
            if (!filled)
              Text(
                sublabel,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 7,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 💬 PLATE VERDICT — Feedback directo estilo ingeniero
// ═══════════════════════════════════════════════════════════════════════════════

class _PlateVerdict extends StatelessWidget {
  final String message;
  final _GlycemicImpact? impact;
  final VoidCallback? onDismiss;

  const _PlateVerdict({required this.message, this.impact, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: impact?.color.withValues(alpha: 0.2) ??
              Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono Dinámico (Lightbulb para neutral, Impact icon para datos)
          Icon(
            impact != null ? impact!.icon : Icons.lightbulb_outline_rounded,
            color: impact?.color ?? AppTheme.primary.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 14),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                if (impact != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'IMPACTO GLUCÉMICO: ',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.3),
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: impact!.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          impact!.label,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            color: impact!.color,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Botón de Cerrar (HUD Style)
          if (onDismiss != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🔘 QUICK FOOD GRID — Chips por sector
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickFoodGrid extends StatelessWidget {
  final _PlateSection section;
  final List<_PlateItem> selectedItems;
  final ValueChanged<_PlateItem> onToggle;

  const _QuickFoodGrid({
    required this.section,
    required this.selectedItems,
    required this.onToggle,
  });

  List<_PlateItem> get _items => switch (section) {
        _PlateSection.vegetales => _defaultVegetales,
        _PlateSection.proteina => _defaultProteina,
        _PlateSection.energia => _defaultEnergia,
      };

  Color get _sectionColor => switch (section) {
        _PlateSection.vegetales => _colorVegetales,
        _PlateSection.proteina => _colorProteina,
        _PlateSection.energia => _colorEnergia,
      };

  String get _sectionTitle => switch (section) {
        _PlateSection.vegetales => 'VEGETALES / FIBRA',
        _PlateSection.proteina => 'PROTEÍNA',
        _PlateSection.energia => 'ENERGÍA / CARBOS / GRASAS',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _sectionColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _sectionColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _sectionColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _sectionTitle,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _sectionColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _items.map((item) {
              final isSelected = selectedItems.any((e) => e.name == item.name);
              return GestureDetector(
                onTap: () => onToggle(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _sectionColor.withValues(alpha: 0.2)
                        : _cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? _sectionColor.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.publicSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            '${item.kcal} kcal',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 📊 MACRO SUMMARY BAR — Resumen compacto P/C/G
// ═══════════════════════════════════════════════════════════════════════════════

class _MacroSummaryBar extends StatelessWidget {
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  const _MacroSummaryBar({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MacroChip(label: 'KCAL', value: '$kcal', color: Colors.white54),
          _MacroChip(
            label: 'PROT',
            value: '${protein}g',
            color: _colorProteina,
          ),
          _MacroChip(label: 'CARBS', value: '${carbs}g', color: _colorEnergia),
          _MacroChip(
            label: 'GRASA',
            value: '${fat}g',
            color: const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 7,
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ✅ REGISTER BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _RegisterButton extends StatelessWidget {
  final bool isReady;
  final bool isLoading;
  final MealType mealType;
  final VoidCallback? onTap;

  const _RegisterButton({
    required this.isReady,
    required this.isLoading,
    required this.mealType,
    this.onTap,
  });

  String get _mealLabel => switch (mealType) {
        MealType.breakfast => 'DESAYUNO',
        MealType.lunch => 'ALMUERZO',
        MealType.dinner => 'CENA',
        _ => 'COMIDA',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isReady
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isReady
                ? AppTheme.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: isReady ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                Icons.check_circle_outline,
                color: isReady ? AppTheme.primary : Colors.white24,
                size: 18,
              ),
            const SizedBox(width: 10),
            Text(
              'REGISTRAR $_mealLabel',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isReady ? AppTheme.primary : Colors.white24,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🍩 COMPOSICIÓN METABÓLICA — Donut + Macro Progress Bars / Fasting Guide
// ═══════════════════════════════════════════════════════════════════════════════

class _MetabolicMacrosCard extends ConsumerWidget {
  final UserModel user;
  final DailyLog? log;

  const _MetabolicMacrosCard({required this.user, this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastingState = ref.watch(fastingControllerProvider).valueOrNull;
    final isFasting = fastingState?.isFasting ?? true;
    final hasMeals = log?.mealEntries.isNotEmpty ?? false;

    // During fasting window (and no meals yet): show plate composition guide
    if (isFasting && !hasMeals) {
      return _buildFastingGuide();
    }

    // During feeding window (or has meals): show real metabolic data
    return _buildFeedingData(ref);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FASTING MODE — Plate composition educational guide
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildFastingGuide() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(width: 3, height: 16, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'TU PRÓXIMO PLATO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'EN AYUNO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Al romper el ayuno, arma tu plato así:',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.45),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // ── Plate composition visual ──
          Row(
            children: [
              // Mini plate diagram
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(painter: _PlateGuidePainter()),
              ),
              const SizedBox(width: 20),
              // Proportions list
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlatePortion(
                      '🥬',
                      'VEGETALES',
                      '50% del plato',
                      'Fibra y micronutrientes',
                      _colorVegetales,
                    ),
                    const SizedBox(height: 12),
                    _buildPlatePortion(
                      '🥩',
                      'PROTEÍNA',
                      '25% del plato',
                      'Saciedad y músculo',
                      _colorProteina,
                    ),
                    const SizedBox(height: 12),
                    _buildPlatePortion(
                      '🍠',
                      'ENERGÍA',
                      '25% del plato',
                      'Carbos complejos + grasas',
                      _colorEnergia,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Tip ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Empieza por la proteína y los vegetales. '
                    'Los carbohidratos al final minimizan el pico de glucosa.',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppTheme.primary.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatePortion(
    String emoji,
    String label,
    String proportion,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    proportion,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FEEDING MODE — Real metabolic composition (donut + macros)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildFeedingData(WidgetRef ref) {
    final targets = ElenaBrain.calculateMacros(user);
    final fastingState = ref.watch(fastingControllerProvider).valueOrNull;
    final startTime = fastingState?.startTime;
    final elapsed = startTime != null
        ? DateTime.now().difference(startTime)
        : Duration.zero;

    // Type-safe aggregation
    int currentCals = 0;
    int currentProtein = 0;
    int currentCarbs = 0;
    int currentFats = 0;

    if (log != null) {
      for (final meal in log!.mealEntries) {
        currentCals += (meal['calories'] as num? ?? 0).toInt();
        currentProtein += (meal['protein'] as num? ?? 0).toInt();
        currentCarbs += (meal['carbs'] as num? ?? 0).toInt();
        currentFats +=
            (meal['fats'] as num? ?? meal['fat'] as num? ?? 0).toInt();
      }
    }

    final totals = _MacroTotals(
      calories: currentCals,
      proteinG: currentProtein,
      carbsG: currentCarbs,
      fatG: currentFats,
    );

    final phase = ElenaBrain.getMetabolicPhase(
      currentProtein,
      currentCarbs,
      currentFats,
      elapsed,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 16, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                'COMPOSICIÓN METABÓLICA',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  phase,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Donut Chart
              Expanded(
                flex: 4,
                child: Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(140, 140),
                          painter: _MetabolicDonutPainter(
                            proteinPct: totals.proteinContribution,
                            carbsPct: totals.carbsContribution,
                            fatPct: totals.fatContribution,
                            hasData: totals.calories > 0,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${totals.calories}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'KCAL',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TOTAL HOY',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8,
                                color: AppTheme.primary.withValues(alpha: 0.5),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Progress indicators (Neon Dots)
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _MacroProgressItem(
                      label: 'PROTEÍNA',
                      current: totals.proteinG,
                      target: targets['protein']!.toInt(),
                      color: Colors.orangeAccent,
                      icon: '🥩',
                    ),
                    const SizedBox(height: 16),
                    _MacroProgressItem(
                      label: 'CARBOS',
                      current: totals.carbsG,
                      target: targets['carbs']!.toInt(),
                      color: Colors.greenAccent,
                      icon: '🍚',
                    ),
                    const SizedBox(height: 16),
                    _MacroProgressItem(
                      label: 'GRASAS',
                      current: totals.fatG,
                      target: targets['fats']!.toInt(),
                      color: Colors.yellowAccent,
                      icon: '🥑',
                    ),
                  ],
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
// 🍽 PLATE GUIDE PAINTER — Visual plate composition (50/25/25)
// ═══════════════════════════════════════════════════════════════════════════════

class _PlateGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Plate background
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A1E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Plate border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    const startAngle = -math.pi / 2;

    // Vegetables: 50% (180°)
    final vegPaint = Paint()
      ..color = _colorVegetales.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi, // 180°
      true,
      vegPaint,
    );

    // Protein: 25% (90°)
    final proteinPaint = Paint()
      ..color = _colorProteina.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + math.pi,
      math.pi / 2, // 90°
      true,
      proteinPaint,
    );

    // Energy: 25% (90°)
    final energyPaint = Paint()
      ..color = _colorEnergia.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + math.pi * 1.5,
      math.pi / 2, // 90°
      true,
      energyPaint,
    );

    // Separator lines
    final linePaint = Paint()
      ..color = const Color(0xFF0D0D10)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Vertical line (top to bottom) — separates vegs from protein/energy
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      linePaint,
    );

    // Horizontal line (right half only) — separates protein from energy
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius, center.dy),
      linePaint,
    );

    // Percentage labels
    final textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      color: Colors.white.withValues(alpha: 0.7),
    );
    _drawCenteredText(
      canvas,
      '50%',
      Offset(center.dx - radius * 0.35, center.dy),
      textStyle,
    );
    _drawCenteredText(
      canvas,
      '25%',
      Offset(center.dx + radius * 0.45, center.dy - radius * 0.4),
      textStyle,
    );
    _drawCenteredText(
      canvas,
      '25%',
      Offset(center.dx + radius * 0.45, center.dy + radius * 0.4),
      textStyle,
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(position.dx - tp.width / 2, position.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MacroTotals {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  _MacroTotals({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  double get proteinContribution {
    if (calories <= 0) return 0.33;
    return (proteinG * 4) / calories;
  }

  double get carbsContribution {
    if (calories <= 0) return 0.33;
    return (carbsG * 4) / calories;
  }

  double get fatContribution {
    if (calories <= 0) return 0.34;
    return (fatG * 9) / calories;
  }
}

class _MacroProgressItem extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;
  final String icon;

  const _MacroProgressItem({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double percent =
        target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            Text(
              '${current}g / ${target}g',
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            if (percent > 0)
              Positioned(
                left: 0,
                right: 0,
                top: -12,
                child: FractionallySizedBox(
                  widthFactor: percent,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CustomPaint(
                        painter: _MacroGlowPainter(color: color),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Glow painter for the macro progress indicator dot
class _MacroGlowPainter extends CustomPainter {
  final Color color;
  _MacroGlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 10, haloPaint);

    final midPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(center, 5, midPaint);

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, 3, corePaint);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _MacroGlowPainter old) => old.color != color;
}

class _MetabolicDonutPainter extends CustomPainter {
  final double proteinPct;
  final double carbsPct;
  final double fatPct;
  final bool hasData;

  _MetabolicDonutPainter({
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
    required this.hasData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeW = 12.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    if (!hasData) return;

    final segments = [
      (proteinPct, Colors.orangeAccent),
      (carbsPct, Colors.greenAccent),
      (fatPct, Colors.yellowAccent),
    ];

    double startAngle = -math.pi / 2;
    for (final (pct, color) in segments) {
      if (pct <= 0) continue;
      final sweep = 2 * math.pi * pct;
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Glow layer
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Data arc
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
