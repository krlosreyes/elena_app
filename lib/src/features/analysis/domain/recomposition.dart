// Progreso v4 (2026-11-05): recomposición corporal.
//
// El objetivo de Elena es la salud metabólica, que va de la mano con la
// recomposición corporal: perder grasa —sobre todo abdominal— conservando
// el músculo. El peso solo engaña (perder grasa y ganar músculo pueden
// dejarlo igual), así que Progreso comunica:
//
//   1. Tu cuerpo está cambiando: grasa vs. masa magra entre dos mediciones.
//   2. Qué significa para tu salud: un beneficio por indicador que mejoró.
//   3. Cómo lo lograste: hábitos (y una acción para el más débil).
//
// Masa magra = peso × (1 − %grasa). El %grasa sale de cintura + cuello
// (US Navy): un error de 1 cm al medirse lo mueve, así que los cambios se
// redondean a 0,5 kg y "conservaste" tolera −0,5 kg de ruido.
//
// ⚠ Los textos de beneficios son asociaciones, no promesas. Revisarlos con
// los médicos del piloto antes de la App Store.
//
// Dart puro: sin Flutter ni Riverpod.

import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';

/// Una medición usable para comparar.
class BodyPoint {
  const BodyPoint({
    required this.at,
    required this.weightKg,
    this.bodyFatPct,
    this.waistCm,
  });

  final DateTime at;
  final double weightKg;
  final double? bodyFatPct;
  final double? waistCm;

  double? get fatKg => bodyFatPct == null ? null : weightKg * bodyFatPct! / 100;
  double? get leanKg => fatKg == null ? null : weightKg - fatKg!;

  factory BodyPoint.fromCheckIn(BiometricCheckIn c) => BodyPoint(
        at: c.recordedAt ?? c.createdAt,
        weightKg: c.weight,
        bodyFatPct: c.bodyFatPercentage,
        waistCm: c.waistCircumference,
      );
}

enum RecompositionVerdict {
  /// Bajó la grasa y la masa magra se mantuvo (o subió).
  fatLostMuscleKept,

  /// Bajó la grasa pero también la masa magra.
  fatLostMuscleLost,

  /// Sin %grasa comparable, pero la cintura bajó.
  waistDown,

  /// Nada mejoró de forma medible.
  noImprovement,
}

enum HealthBenefit { lessAbdominalFat, muscleKept }

class Recomposition {
  const Recomposition({
    required this.before,
    required this.after,
    required this.verdict,
    this.fatDeltaKg,
    this.leanDeltaKg,
    this.waistDeltaCm,
    required this.weightDeltaKg,
  });

  final BodyPoint before;
  final BodyPoint after;
  final RecompositionVerdict verdict;
  final double? fatDeltaKg;
  final double? leanDeltaKg;
  final double? waistDeltaCm;
  final double weightDeltaKg;

  int get days => after.at.difference(before.at).inDays;

  bool get hasComposition => fatDeltaKg != null && leanDeltaKg != null;

  /// Fuentes que NO son una medición del usuario.
  static const _excludedSources = {'healthkit_sync', 'bodyfat_recompute'};

  /// Mínimo de días entre mediciones para comparar.
  static const int minDays = 6;

  /// Ventana objetivo: la medición "antes" más cercana a 30 días atrás.
  static const int targetDays = 30;

  /// Ruido tolerado (kg) en grasa y masa magra.
  static const double noiseKg = 0.5;

  /// Compara la medición más reciente con la más cercana a 30 días antes.
  /// Null si no hay dos mediciones separadas por al menos [minDays].
  static Recomposition? compute(List<BiometricCheckIn> history) {
    final points = <BodyPoint>[
      for (final c in history)
        if (c.weight > 0 &&
            !_excludedSources.contains(c.source) &&
            !(c.source == null &&
                (c.notes?.startsWith('Importado de') ?? false)))
          BodyPoint.fromCheckIn(c),
    ]..sort((a, b) => a.at.compareTo(b.at));
    if (points.length < 2) return null;

    final after = points.last;
    BodyPoint? before;
    int? bestGap;
    for (final p in points) {
      final days = after.at.difference(p.at).inDays;
      if (days < minDays) continue;
      final gap = (days - targetDays).abs();
      if (bestGap == null || gap < bestGap) {
        bestGap = gap;
        before = p;
      }
    }
    if (before == null) return null;

    final fatD = (after.fatKg != null && before.fatKg != null)
        ? after.fatKg! - before.fatKg!
        : null;
    final leanD = (after.leanKg != null && before.leanKg != null)
        ? after.leanKg! - before.leanKg!
        : null;
    final waistD = (after.waistCm != null && before.waistCm != null)
        ? after.waistCm! - before.waistCm!
        : null;

    final RecompositionVerdict verdict;
    if (fatD != null && leanD != null && fatD <= -noiseKg) {
      verdict = leanD >= -noiseKg
          ? RecompositionVerdict.fatLostMuscleKept
          : RecompositionVerdict.fatLostMuscleLost;
    } else if (waistD != null && waistD <= -1) {
      verdict = RecompositionVerdict.waistDown;
    } else {
      verdict = RecompositionVerdict.noImprovement;
    }

    return Recomposition(
      before: before,
      after: after,
      verdict: verdict,
      fatDeltaKg: fatD,
      leanDeltaKg: leanD,
      waistDeltaCm: waistD,
      weightDeltaKg: after.weightKg - before.weightKg,
    );
  }

  // ─── Textos ──────────────────────────────────────────────────────

  /// Redondea a 0,5 y formatea en español ("2", "1,5").
  static String half(double v) {
    final r = (v.abs() * 2).round() / 2;
    final s =
        r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
    return s.replaceAll('.', ',');
  }

  /// "−1,5 kg" / "+0,5 kg" / "sin cambio".
  static String signedKg(double v) {
    final r = (v.abs() * 2).round() / 2;
    if (r == 0) return 'sin cambio';
    return '${v < 0 ? '−' : '+'}${half(v)} kg';
  }

  static String signedCm(double v) {
    final r = v.abs().round();
    if (r == 0) return 'sin cambio';
    return '${v < 0 ? '−' : '+'}$r cm';
  }

  String get headline {
    switch (verdict) {
      case RecompositionVerdict.fatLostMuscleKept:
        return 'Perdiste ${half(fatDeltaKg!)} kg de grasa y conservaste tu músculo.';
      case RecompositionVerdict.fatLostMuscleLost:
        return 'Perdiste ${half(fatDeltaKg!)} kg de grasa, pero también algo de músculo.';
      case RecompositionVerdict.waistDown:
        return 'Tu cintura bajó ${waistDeltaCm!.abs().round()} cm.';
      case RecompositionVerdict.noImprovement:
        return 'Tu composición no mejoró en este periodo.';
    }
  }

  /// Línea de contexto bajo el detalle.
  String get weightNote {
    final w = signedKg(weightDeltaKg);
    if (verdict == RecompositionVerdict.fatLostMuscleKept &&
        weightDeltaKg < 0 &&
        fatDeltaKg != null &&
        fatDeltaKg!.abs() >= weightDeltaKg.abs() * 0.8) {
      return 'Tu peso: $w. Casi todo fue grasa.';
    }
    if (verdict == RecompositionVerdict.noImprovement) {
      return 'Tu peso: $w. Los cambios toman semanas; enfócate en el '
          'hábito de abajo.';
    }
    return 'Tu peso: $w.';
  }

  List<HealthBenefit> get benefits => [
        if (waistDeltaCm != null && waistDeltaCm! <= -1)
          HealthBenefit.lessAbdominalFat,
        if (verdict == RecompositionVerdict.fatLostMuscleKept)
          HealthBenefit.muscleKept,
      ];
}

/// Título y texto de cada beneficio. Redactados como asociaciones.
(String, String) benefitCopy(HealthBenefit b) => switch (b) {
      HealthBenefit.lessAbdominalFat => (
          'Menos grasa abdominal',
          'Es la grasa que más se asocia con resistencia a la insulina y '
              'riesgo de diabetes tipo 2.',
        ),
      HealthBenefit.muscleKept => (
          'Músculo conservado',
          'El músculo ayuda a tu cuerpo a usar mejor la glucosa. Bajar de '
              'peso perdiéndolo haría lo contrario.',
        ),
    };

/// Pilares que se muestran en "Cómo lo lograste".
enum ProgressPillar { ayuno, sueno, agua, movimiento, comida }

/// Acción concreta para el pilar más débil, orientada a la recomposición.
String pillarTip(ProgressPillar p, {required bool muscleAtRisk}) => switch (p) {
      ProgressPillar.movimiento => muscleAtRisk
          ? 'Para conservar tu músculo: haz 2 sesiones de fuerza esta semana.'
          : 'Muévete 20 minutos después de comer, 3 días esta semana.',
      ProgressPillar.ayuno => 'Completa tu ayuno al menos 5 días esta semana.',
      ProgressPillar.sueno =>
        'Duerme cerca de 7 horas: dormir poco empeora cómo usas la insulina.',
      ProgressPillar.agua =>
        'Llega a tu meta de agua: te ayuda a sostener el ayuno.',
      ProgressPillar.comida => muscleAtRisk
          ? 'Prioriza proteína en cada comida: protege tu músculo mientras '
              'pierdes grasa.'
          : 'Empieza cada comida por proteína y verduras.',
    };

/// El pilar con menos días cumplidos (empates: el primero en el orden).
ProgressPillar weakestPillar(Map<ProgressPillar, int> days) {
  var best = ProgressPillar.values.first;
  var min = days[best] ?? 0;
  for (final p in ProgressPillar.values) {
    final d = days[p] ?? 0;
    if (d < min) {
      min = d;
      best = p;
    }
  }
  return best;
}
