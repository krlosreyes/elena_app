// SPEC-12: Composición Corporal Visible
// Tarjeta compacta para el dashboard que expone los datos de composición
// corporal calculados durante el onboarding (fórmula Naval US Navy).
// Navega a BodyCompositionScreen para el desglose completo.

import 'dart:math' as math;

import 'package:elena_app/src/core/engine/metabolic_formulas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/science/presentation/widgets/sources_footer.dart';

// ─── Helpers de cálculo (reutilizados en BodyCompositionScreen) ──────────────

class BodyCompositionCalc {
  static double leanMass(double weight, double bodyFatPct) =>
      weight * (1 - bodyFatPct / 100);

  static double whtr(double waist, double height) =>
      height > 0 ? waist / height : 0.5;

  static double ffmi(double leanMassKg, double heightCm) {
    final hm = heightCm / 100;
    return hm > 0 ? leanMassKg / math.pow(hm, 2) : 0;
  }

  // ── WHTR ─────────────────────────────────────────────────────────────────
  // SPEC-306: cortes NICE NG246, los mismos de la calculadora del sitio.
  static Color whtrColor(double w) {
    switch (MetabolicFormulas.whtrCategory(w)) {
      case WhtrCategory.bajo:
        return Colors.blueAccent;
      case WhtrCategory.saludable:
        return const Color(0xFF2D9B60);
      case WhtrCategory.aumentado:
        return Colors.orangeAccent;
      case WhtrCategory.alto:
        return Colors.redAccent;
    }
  }

  static String whtrLabel(double w) => MetabolicFormulas.whtrCategory(w).label;

  // ── FFMI ─────────────────────────────────────────────────────────────────
  static String ffmiLabel(double f, bool isMale) {
    final thresholds =
        isMale ? [16.0, 18.0, 20.0, 22.0] : [14.0, 16.0, 18.0, 20.0];
    final labels = [
      'Por debajo del promedio',
      'Promedio',
      'Por encima del promedio',
      'Atlético',
      'Élite',
    ];
    for (int i = 0; i < thresholds.length; i++) {
      if (f < thresholds[i]) return labels[i];
    }
    return labels.last;
  }

  static Color ffmiColor(double f, bool isMale) {
    final base = isMale ? 18.0 : 16.0;
    if (f < base - 2) return Colors.redAccent;
    if (f < base) return Colors.orangeAccent;
    if (f < base + 4) return const Color(0xFF2D9B60);
    return Colors.cyanAccent;
  }

  // ── Grasa corporal ────────────────────────────────────────────────────────
  // SPEC-306: categorías del American Council on Exercise, iguales al sitio.
  static String fatZoneLabel(double pct, bool isMale) =>
      MetabolicFormulas.fatCategory(pct, isMale).label;

  static Color fatZoneColor(double pct, bool isMale) {
    final String zone = fatZoneLabel(pct, isMale);
    switch (zone) {
      case 'Esencial':
        return Colors.blueAccent;
      case 'Atletas':
        return const Color(0xFF2D9B60);
      case 'Fitness':
        return Colors.tealAccent;
      case 'Promedio':
        return Colors.orangeAccent;
      default:
        return Colors.redAccent;
    }
  }
}

/// Rediseño Perfil (2026-10-30): en la tarjeta del Perfil las zonas de
/// riesgo se muestran con una etiqueta neutra. El cálculo no cambia y la
/// pantalla de detalle conserva la clasificación completa.
String _neutralLabel(String label) {
  if (label == 'Obesidad' || label.startsWith('Riesgo')) return 'Por mejorar';
  return label;
}

// ─── Widget principal ─────────────────────────────────────────────────────────

class BodyCompositionCard extends ConsumerWidget {
  const BodyCompositionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return userAsync.when(
      loading: () => const _CardShell(
          child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child:
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white30),
        ),
      )),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return _CardContent(user: user);
      },
    );
  }
}

// ─── Contenido real de la tarjeta ─────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  const _CardContent({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final bool isMale = user.gender.toUpperCase() == 'M';
    // SPEC-92: bodyFat nullable → fallback poblacional para evitar
    // null crash en este widget de detalle. Si en el futuro queremos
    // mostrar un placeholder "Sin medir" en vez de pintar el cálculo
    // con fallback, hacerlo en SPEC separada.
    // SPEC-306: sin medida no se muestra un número inventado.
    final bool hasFat =
        user.bodyFatPercentage != null && user.bodyFatPercentage! > 0;
    final bool hasWaist =
        user.waistCircumference != null && user.waistCircumference! > 0;
    final double fat = hasFat ? user.bodyFatPercentage!.clamp(1.0, 60.0) : 0.0;
    final double lean = BodyCompositionCalc.leanMass(user.weight, fat);
    final double w = hasWaist
        ? BodyCompositionCalc.whtr(user.waistCircumference!, user.height)
        : 0.0;
    final double f = BodyCompositionCalc.ffmi(lean, user.height);

    final Color fatColor = BodyCompositionCalc.fatZoneColor(fat, isMale);
    final Color whtrColor = BodyCompositionCalc.whtrColor(w);

    return GestureDetector(
      onTap: () => context.push('/profile/body-composition'),
      child: _CardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monitor_weight_outlined,
                        color: Colors.tealAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'COMPOSICIÓN CORPORAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (user.isMeasurementEstimated) _EstimatedBadge(),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.3), size: 18),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Grid de 4 métricas ───────────────────────────────────────────
            Row(
              children: [
                // Grasa corporal
                Expanded(
                  child: _MetricTile(
                    label: '% GRASA',
                    value: hasFat ? '${fat.toStringAsFixed(1)}%' : '—',
                    sub: hasFat
                        ? _neutralLabel(
                            BodyCompositionCalc.fatZoneLabel(fat, isMale))
                        : (MetabolicFormulas.needsHip(
                                isMale: isMale, hipCm: user.hipCircumference)
                            ? 'Falta cadera'
                            : 'Sin medir'),
                    color: hasFat ? fatColor : Colors.white54,
                    icon: Icons.whatshot_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                // Masa magra
                Expanded(
                  child: _MetricTile(
                    label: 'MASA MAGRA',
                    value: hasFat ? '${lean.toStringAsFixed(1)} kg' : '—',
                    sub: hasFat
                        ? BodyCompositionCalc.ffmiLabel(f, isMale)
                        : 'Sin medir',
                    color: Colors.cyanAccent,
                    icon: Icons.fitness_center_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                // WHTR
                Expanded(
                  child: _MetricTile(
                    label: 'WHTR',
                    value: hasWaist ? w.toStringAsFixed(2) : '—',
                    sub: hasWaist
                        ? _neutralLabel(BodyCompositionCalc.whtrLabel(w))
                        : 'Sin medir',
                    color: hasWaist ? whtrColor : Colors.white54,
                    icon: Icons.straighten_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Barra de riesgo WHTR ─────────────────────────────────────────
            if (hasWaist) _WhtrBar(whtr: w),
            // SPEC-305 (guía 1.4.1): fuentes de los cuatro cálculos.
            const SizedBox(height: 10),
            const CitationLink(
              'Fuentes: US Navy (Hodgdon, 1992) · Ashwell 2012 · '
              'Kouri 1995',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barra visual WHTR ────────────────────────────────────────────────────────

class _WhtrBar extends StatelessWidget {
  const _WhtrBar({required this.whtr});
  final double whtr;

  @override
  Widget build(BuildContext context) {
    // Mapear WHTR 0.35–0.70 a posición 0.0–1.0
    final double pos = ((whtr - 0.35) / (0.70 - 0.35)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ÍNDICE CINTURA-ESTATURA',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Barra de gradiente
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Colors.blueAccent,
                    Color(0xFF2D9B60),
                    Colors.orangeAccent,
                    Colors.redAccent,
                  ],
                  // 0,40 / 0,50 / 0,60 sobre la escala 0,35–0,70.
                  stops: [0.14, 0.43, 0.71, 1.0],
                ),
              ),
            ),
            // Indicador de posición
            FractionallySizedBox(
              widthFactor: pos,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: BodyCompositionCalc.whtrColor(whtr),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: BodyCompositionCalc.whtrColor(whtr)
                            .withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Óptimo', style: _barLabel),
            Text('Por mejorar', style: _barLabel),
          ],
        ),
      ],
    );
  }

  TextStyle get _barLabel => TextStyle(
        fontSize: 7.5,
        color: Colors.white.withValues(alpha: 0.7),
        fontWeight: FontWeight.w600,
      );
}

// ─── Componentes auxiliares ───────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.tealAccent.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EstimatedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'ESTIMADO',
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          color: Colors.amber,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
