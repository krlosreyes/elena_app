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

  // ── SPEC-264: marcador de retos (para insignias y récord) ───────────────
  /// Retos a los que se unió/creó (de por vida).
  final int retosJoined;

  /// Retos que terminó (llegaron a su fin estando el usuario dentro).
  final int retosFinished;

  /// Retos ganados (quedó 1º del tablero al cierre).
  final int retosWon;

  /// Revanchas iniciadas (encadenar retos — el motor del hábito).
  final int retosRematches;

  /// Códigos de retos cuyo resultado YA se contabilizó (idempotencia: reabrir
  /// un reto terminado no vuelve a sumar finished/won).
  final List<String> retosCountedCodes;

  const GamificationState({
    this.stars = 0,
    this.totalStarsEarned = 0,
    this.xp = 0,
    this.frosties = 0,
    this.daysTowardFrosty = 0,
    this.lifetimeFastingHours = 0,
    this.retosJoined = 0,
    this.retosFinished = 0,
    this.retosWon = 0,
    this.retosRematches = 0,
    this.retosCountedCodes = const [],
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
    int? retosJoined,
    int? retosFinished,
    int? retosWon,
    int? retosRematches,
    List<String>? retosCountedCodes,
  }) =>
      GamificationState(
        stars: stars ?? this.stars,
        totalStarsEarned: totalStarsEarned ?? this.totalStarsEarned,
        xp: xp ?? this.xp,
        frosties: frosties ?? this.frosties,
        daysTowardFrosty: daysTowardFrosty ?? this.daysTowardFrosty,
        lifetimeFastingHours: lifetimeFastingHours ?? this.lifetimeFastingHours,
        retosJoined: retosJoined ?? this.retosJoined,
        retosFinished: retosFinished ?? this.retosFinished,
        retosWon: retosWon ?? this.retosWon,
        retosRematches: retosRematches ?? this.retosRematches,
        retosCountedCodes: retosCountedCodes ?? this.retosCountedCodes,
      );

  /// SPEC-264: registra actividad de retos (unirse/revancha) para récord.
  GamificationState recordChallenge({
    int joined = 0,
    int rematches = 0,
  }) =>
      copyWith(
        retosJoined: retosJoined + joined,
        retosRematches: retosRematches + rematches,
      );

  /// SPEC-264: contabiliza el RESULTADO de un reto una sola vez (idempotente
  /// por [code]). No muta si ese reto ya se contó.
  GamificationState recordOutcome(String code, {required bool didWin}) {
    if (retosCountedCodes.contains(code)) return this;
    return copyWith(
      retosFinished: retosFinished + 1,
      retosWon: retosWon + (didWin ? 1 : 0),
      retosCountedCodes: [...retosCountedCodes, code],
    );
  }

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

  /// SPEC-264: gasta [perlas] en una interacción social (zumbido/porra).
  /// Devuelve `null` si no alcanza (no muta). `totalStarsEarned` no baja:
  /// es récord histórico, solo baja el saldo gastable.
  GamificationState? spend(int perlas) {
    if (perlas <= 0 || stars < perlas) return null;
    return copyWith(stars: stars - perlas);
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
          lifetimeFastingHours == other.lifetimeFastingHours &&
          retosJoined == other.retosJoined &&
          retosFinished == other.retosFinished &&
          retosWon == other.retosWon &&
          retosRematches == other.retosRematches &&
          retosCountedCodes.length == other.retosCountedCodes.length &&
          retosCountedCodes.join(',') == other.retosCountedCodes.join(',');

  @override
  int get hashCode => Object.hash(
        stars,
        totalStarsEarned,
        xp,
        frosties,
        daysTowardFrosty,
        lifetimeFastingHours,
        retosJoined,
        retosFinished,
        retosWon,
        retosRematches,
        Object.hashAll(retosCountedCodes),
      );
}
