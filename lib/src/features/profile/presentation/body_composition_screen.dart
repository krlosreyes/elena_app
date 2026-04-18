// SPEC-12: Composición Corporal Visible — Pantalla de detalle completo
// Muestra el desglose científico de la composición corporal del usuario
// con explicaciones en lenguaje accesible. Nunca muestra fórmulas matemáticas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/profile/presentation/widgets/body_composition_card.dart';

class BodyCompositionScreen extends ConsumerWidget {
  const BodyCompositionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'COMPOSICIÓN CORPORAL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Sin datos', style: TextStyle(color: Colors.white54)),
            );
          }
          return _BodyCompositionContent(user: user);
        },
      ),
    );
  }
}

// ─── Contenido principal ──────────────────────────────────────────────────────

class _BodyCompositionContent extends StatelessWidget {
  const _BodyCompositionContent({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final bool isMale  = user.gender.toUpperCase() == 'M';
    final double fat   = user.bodyFatPercentage.clamp(1.0, 60.0);
    final double lean  = BodyCompositionCalc.leanMass(user.weight, fat);
    final double wCm   = user.waistCircumference ?? (user.weight * 0.48);
    final double w     = BodyCompositionCalc.whtr(wCm, user.height);
    final double f     = BodyCompositionCalc.ffmi(lean, user.height);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner de datos estimados ─────────────────────────────────────
          if (user.isMeasurementEstimated)
            _EstimatedBanner(),

          const SizedBox(height: 20),

          // ── Score de grasa corporal — número grande ────────────────────────
          _FatScoreHero(fat: fat, isMale: isMale),

          const SizedBox(height: 24),

          // ── Masa magra ────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.fitness_center_rounded,
            iconColor: Colors.cyanAccent,
            title: 'Masa Magra',
            titleSub: 'Tu músculo + hueso + órganos',
            child: _LeanMassContent(
              lean: lean,
              weight: user.weight,
              fat: fat,
              isMale: isMale,
              ffmi: f,
            ),
          ),

          const SizedBox(height: 16),

          // ── WHTR ──────────────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.straighten_rounded,
            iconColor: BodyCompositionCalc.whtrColor(w),
            title: 'Índice Cintura-Estatura',
            titleSub: 'El indicador de riesgo metabólico más preciso',
            child: _WhtrContent(
              whtr: w,
              waistCm: wCm,
              heightCm: user.height,
              isEstimated: user.waistCircumference == null,
            ),
          ),

          const SizedBox(height: 16),

          // ── Impacto en el IMR ─────────────────────────────────────────────
          _ImrImpactCard(
            structurePct: _calcStructurePct(w, f, isMale),
          ),

          const SizedBox(height: 16),

          // ── Nota científica ───────────────────────────────────────────────
          _ScientificNote(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Estima el structureScore como aparece en el ScoreEngine para dar contexto.
  double _calcStructurePct(double w, double f, bool isMale) {
    final double s1 = ((0.60 - w) / 0.15).clamp(0.0, 1.0);
    final double baseFFMI = isMale ? 16.0 : 14.0;
    final double rangeFFMI = isMale ? 6.0 : 5.0;
    final double s2 = ((f - baseFFMI) / rangeFFMI).clamp(0.0, 1.0);
    return ((0.65 * s1) + (0.35 * s2)) * 100;
  }
}

// ─── Hero de % grasa ──────────────────────────────────────────────────────────

class _FatScoreHero extends StatelessWidget {
  const _FatScoreHero({required this.fat, required this.isMale});
  final double fat;
  final bool isMale;

  @override
  Widget build(BuildContext context) {
    final Color c = BodyCompositionCalc.fatZoneColor(fat, isMale);
    final String zone = BodyCompositionCalc.fatZoneLabel(fat, isMale);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: c.withOpacity(0.08), blurRadius: 24, spreadRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${fat.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: c,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'GRASA CORPORAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.withOpacity(0.4)),
            ),
            child: Text(
              'Zona $zone',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: c,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FatZoneBar(fat: fat, isMale: isMale),
        ],
      ),
    );
  }
}

// ─── Barra de zonas de grasa ──────────────────────────────────────────────────

class _FatZoneBar extends StatelessWidget {
  const _FatZoneBar({required this.fat, required this.isMale});
  final double fat;
  final bool isMale;

  @override
  Widget build(BuildContext context) {
    // Rango visual: 5%–40% para hombres, 12%–45% para mujeres
    final double minFat = isMale ? 5.0 : 12.0;
    final double maxFat = isMale ? 40.0 : 45.0;
    final double pos = ((fat - minFat) / (maxFat - minFat)).clamp(0.0, 1.0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent,
                    const Color(0xFF2D9B60),
                    Colors.tealAccent,
                    Colors.orangeAccent,
                    Colors.redAccent,
                  ],
                  stops: isMale
                      ? const [0.0, 0.2, 0.35, 0.55, 1.0]
                      : const [0.0, 0.15, 0.30, 0.55, 1.0],
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pos,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: BodyCompositionCalc.fatZoneColor(fat, isMale),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: BodyCompositionCalc.fatZoneColor(fat, isMale)
                            .withOpacity(0.7),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _barLabel('Esencial'),
            _barLabel('Atlético'),
            _barLabel('Fitness'),
            _barLabel('Promedio'),
            _barLabel('Alto'),
          ],
        ),
      ],
    );
  }

  Widget _barLabel(String t) => Text(
    t,
    style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.3)),
  );
}

// ─── Contenido: Masa Magra ────────────────────────────────────────────────────

class _LeanMassContent extends StatelessWidget {
  const _LeanMassContent({
    required this.lean,
    required this.weight,
    required this.fat,
    required this.isMale,
    required this.ffmi,
  });

  final double lean;
  final double weight;
  final double fat;
  final bool isMale;
  final double ffmi;

  @override
  Widget build(BuildContext context) {
    final Color ffmiColor = BodyCompositionCalc.ffmiColor(ffmi, isMale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                value: '${lean.toStringAsFixed(1)} kg',
                label: 'Masa magra total',
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                value: '${(weight - lean).toStringAsFixed(1)} kg',
                label: 'Masa grasa',
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // FFMI
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ÍNDICE DE MASA LIBRE DE GRASA (FFMI)',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            Text(
              ffmi.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ffmiColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          BodyCompositionCalc.ffmiLabel(ffmi, isMale),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ffmiColor,
          ),
        ),
        const SizedBox(height: 8),
        _ExplanationText(
          'El FFMI mide cuánta masa muscular tienes en relación a tu estatura. '
          'Es el indicador más objetivo de desarrollo muscular, independiente '
          'de cuánto peses. Un FFMI mayor protege contra la sarcopenia.',
        ),
      ],
    );
  }
}

// ─── Contenido: WHTR ──────────────────────────────────────────────────────────

class _WhtrContent extends StatelessWidget {
  const _WhtrContent({
    required this.whtr,
    required this.waistCm,
    required this.heightCm,
    required this.isEstimated,
  });

  final double whtr;
  final double waistCm;
  final double heightCm;
  final bool isEstimated;

  @override
  Widget build(BuildContext context) {
    final Color c = BodyCompositionCalc.whtrColor(whtr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                value: whtr.toStringAsFixed(3),
                label: 'Índice WHTR',
                color: c,
                highlight: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                value: '${waistCm.toStringAsFixed(0)} cm',
                label: isEstimated ? 'Cintura (estimada)' : 'Cintura',
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, color: c, size: 8),
              const SizedBox(width: 8),
              Text(
                BodyCompositionCalc.whtrLabel(whtr),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: c,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExplanationText(
          'El WHTR compara tu cintura con tu estatura. Una proporción menor '
          'a 0.50 indica bajo riesgo cardiovascular y metabólico, '
          'independientemente de tu peso total. Es más preciso que el IMC '
          'porque detecta grasa visceral, la más peligrosa metabólicamente.',
        ),
        if (isEstimated) ...[
          const SizedBox(height: 10),
          _EstimatedNote(),
        ],
      ],
    );
  }
}

// ─── Impacto en el IMR ────────────────────────────────────────────────────────

class _ImrImpactCard extends StatelessWidget {
  const _ImrImpactCard({required this.structurePct});
  final double structurePct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.metabolicGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.metabolicGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF2D9B60),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IMPACTO EN TU IMR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'El Bloque Estructura representa el 50% de tu IMR. '
                  'Tu puntuación actual en este bloque es '
                  '${structurePct.toStringAsFixed(0)}/100.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
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

// ─── Nota científica ──────────────────────────────────────────────────────────

class _ScientificNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined,
                  size: 14, color: Colors.white.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text(
                'BASE CIENTÍFICA',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Los cálculos de composición corporal usan la Fórmula Naval del US Navy '
            '(Hodgdon & Beckett, 1984), validada en estudios de salud metabólica. '
            'El WHTR está respaldado por Ashwell et al. (2012) como predictor '
            'independiente de riesgo cardiovascular. El FFMI fue establecido por '
            'Kouri et al. (1995) como referencia de masa muscular natural.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.35),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Componentes genéricos ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleSub,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String titleSub;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: iconColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      titleSub,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.07),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    this.highlight = false,
  });

  final String value;
  final String label;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? color.withOpacity(0.1)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? color.withOpacity(0.3) : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationText extends StatelessWidget {
  const _ExplanationText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        color: Colors.white.withOpacity(0.5),
        height: 1.6,
      ),
    );
  }
}

class _EstimatedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Colors.amber, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Algunos datos fueron estimados a partir de tu talla de ropa. '
              'Para mayor precisión, actualiza tus medidas en Progreso.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.withOpacity(0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimatedNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: Colors.amber, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Cintura estimada desde tu talla de pantalón. '
            'Actualiza tus medidas para un WHTR preciso.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.amber.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
