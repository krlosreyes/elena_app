// SPEC-262: estado persistido de la economía de gamificación.
//
// Value object INMUTABLE con transiciones PURAS (sin I/O, sin reloj). El
// notifier lo hace evolucionar y lo persiste; la UI solo lo dibuja. Toda la
// aritmética de la economía vive acá para poder testearla al 100%.

import 'package:elena_app/src/features/gamification/domain/level_system.dart';
import 'package:elena_app/src/features/gamification/domain/shop_item.dart';
import 'package:elena_app/src/features/gamification/domain/star_action.dart';

class GamificationState {
  /// Saldo actual de estrellas (moneda gastable).
  final int stars;

  /// Estrellas ganadas de por vida (nunca baja; para récords).
  final int totalStarsEarned;

  /// XP total acumulado (define el nivel).
  final int xp;

  /// Congeladores en inventario (protegen la racha).
  final int frosties;

  /// Progreso hacia el próximo congelador por constancia: 0..(daysPerFrosty-1).
  final int daysTowardFrosty;

  /// Horas de ayuno acumuladas de por vida.
  final double lifetimeFastingHours;

  const GamificationState({
    this.stars = 0,
    this.totalStarsEarned = 0,
    this.xp = 0,
    this.frosties = 0,
    this.daysTowardFrosty = 0,
    this.lifetimeFastingHours = 0,
  });

  /// Cada cuántos días que califican se gana un congelador.
  static const int daysPerFrosty = 6;

  LevelInfo get levelInfo => LevelSystem.infoForXp(xp);
  int get level => levelInfo.level;

  GamificationState copyWith({
    int? stars,
    int? totalStarsEarned,
    int? xp,
    int? frosties,
    int? daysTowardFrosty,
    double? lifetimeFastingHours,
  }) =>
      GamificationState(
        stars: stars ?? this.stars,
        totalStarsEarned: totalStarsEarned ?? this.totalStarsEarned,
        xp: xp ?? this.xp,
        frosties: frosties ?? this.frosties,
        daysTowardFrosty: daysTowardFrosty ?? this.daysTowardFrosty,
        lifetimeFastingHours: lifetimeFastingHours ?? this.lifetimeFastingHours,
      );

  // ── Transiciones puras ────────────────────────────────────────────────

  /// Suma la recompensa de una acción (estrellas + XP).
  GamificationState earn(StarAction action) {
    final r = action.reward;
    return copyWith(
      stars: stars + r.stars,
      totalStarsEarned: totalStarsEarned + r.stars,
      xp: xp + r.xp,
    );
  }

  /// Un día que calificó para la racha: paga el bonus y avanza el contador de
  /// constancia; cada [daysPerFrosty] días que califican regala 1 congelador.
  GamificationState onDayQualified() {
    final r = StarAction.dayQualified.reward;
    var days = daysTowardFrosty + 1;
    var earnedFrosties = frosties;
    if (days >= daysPerFrosty) {
      days = 0;
      earnedFrosties += 1;
    }
    return copyWith(
      stars: stars + r.stars,
      totalStarsEarned: totalStarsEarned + r.stars,
      xp: xp + r.xp,
      daysTowardFrosty: days,
      frosties: earnedFrosties,
    );
  }

  /// Acumula horas de ayuno de por vida (ignora valores no positivos).
  GamificationState addFastingHours(double hours) {
    if (hours <= 0) return this;
    return copyWith(lifetimeFastingHours: lifetimeFastingHours + hours);
  }

  bool canAfford(ShopItem item) => stars >= item.starCost;

  /// Compra un paquete de la tienda. Devuelve `null` si no alcanza (no muta).
  GamificationState? purchase(ShopItem item) {
    if (!canAfford(item)) return null;
    return copyWith(
      stars: stars - item.starCost,
      frosties: frosties + item.frostyQty,
    );
  }

  /// Usa un congelador. Devuelve `null` si no hay ninguno.
  GamificationState? useFrosty() {
    if (frosties <= 0) return null;
    return copyWith(frosties: frosties - 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamificationState &&
          stars == other.stars &&
          totalStarsEarned == other.totalStarsEarned &&
          xp == other.xp &&
          frosties == other.frosties &&
          daysTowardFrosty == other.daysTowardFrosty &&
          lifetimeFastingHours == other.lifetimeFastingHours;

  @override
  int get hashCode => Object.hash(
        stars,
        totalStarsEarned,
        xp,
        frosties,
        daysTowardFrosty,
        lifetimeFastingHours,
      );
}
