// Sistema de insignias (2026-07-15) — contrato de persistencia.
// Mismo patrón que StreakRepository (SPEC-50.3).

import 'package:elena_app/src/features/badges/domain/earned_badge.dart';

abstract class BadgeRepository {
  /// Stream de TODAS las insignias ya ganadas por el usuario — sin
  /// recorte temporal (a diferencia de streak_history, acá no hay
  /// "últimos N días": una insignia ganada hace un año sigue siendo
  /// tan válida como una de ayer).
  Stream<List<EarnedBadge>> watchEarned(String userId);

  /// Crea el documento de una insignia recién desbloqueada. Usa
  /// `badge.badgeId` como clave del documento — llamar esto dos veces
  /// con el mismo badgeId es inofensivo (sobreescribe con los mismos
  /// datos, no duplica). Las reglas de Firestore no permiten update ni
  /// delete después de creada.
  Future<void> create(String userId, EarnedBadge badge);
}
