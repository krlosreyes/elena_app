// Sistema de insignias (2026-07-15) — implementa la propuesta entregada en
// "Propuesta - Sistema de Insignias.docx".
//
// Una `EarnedBadge` es un HECHO PERMANENTE: el usuario la ganó, con fecha
// y contexto, y eso no se recalcula ni se revierte después — a diferencia
// de la racha (`StreakEntry`/`StreakEngine`), que SÍ se recalcula en vivo
// cada vez a partir del historial diario. Si algún día cambia la regla de
// qué cuenta para un nivel (como ya pasó una vez con la racha, ver
// SPEC-245), eso no debe quitarle retroactivamente un logro ya ganado a
// nadie — por eso este modelo se escribe UNA vez, al momento de
// desbloquearse, y las reglas de Firestore (ver firestore.rules,
// `users/{uid}/badges/{badgeId}`) no permiten `update` ni `delete` desde
// el cliente.
//
// Nombrada `EarnedBadge` y no `Badge` a propósito: `package:flutter/
// material.dart` ya exporta una clase `Badge` (el widget de "punto rojo
// de notificación") — un nombre distinto evita colisión de imports en
// cualquier archivo de presentación que necesite ambas cosas.
//
// No usa Freezed (evita build_runner) — mismo criterio que StreakEntry
// y BiometricCheckIn.

class EarnedBadge {
  /// ID determinístico (ej. 'racha_30', 'ayuno_75') — NUNCA autogenerado.
  /// Es también el ID del documento en Firestore. Esto es lo que hace
  /// que otorgar la misma insignia dos veces (por una carrera entre dos
  /// evaluaciones, o un reintento offline) sea inofensivo: la segunda
  /// escritura sobreescribe el mismo documento con los mismos datos, en
  /// vez de crear un duplicado.
  final String badgeId;

  /// Una de las categorías en [BadgeCategory.all] (ver badge_definition.dart).
  final String category;

  /// Nivel dentro de la categoría (1 = el primero/más fácil).
  final int level;

  /// Momento en que se desbloqueó.
  final DateTime unlockedAt;

  /// Dato que disparó el desbloqueo, guardado tal cual — no se vuelve a
  /// calcular después. Ej. `{'streakLength': 30}` o `{'daysCompleted': 75}`.
  /// Opcional y de forma libre porque cada categoría guarda un dato distinto.
  final Map<String, dynamic>? contextSnapshot;

  const EarnedBadge({
    required this.badgeId,
    required this.category,
    required this.level,
    required this.unlockedAt,
    this.contextSnapshot,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'badgeId': badgeId,
      'category': category,
      'level': level,
      'unlockedAt': unlockedAt.toIso8601String(),
    };
    if (contextSnapshot != null) m['contextSnapshot'] = contextSnapshot;
    return m;
  }

  factory EarnedBadge.fromJson(Map<String, dynamic> json) => EarnedBadge(
        badgeId: json['badgeId'] as String? ?? '',
        category: json['category'] as String? ?? '',
        level: (json['level'] as num?)?.toInt() ?? 0,
        unlockedAt: DateTime.tryParse(json['unlockedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        contextSnapshot: (json['contextSnapshot'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v)),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EarnedBadge && badgeId == other.badgeId);

  @override
  int get hashCode => badgeId.hashCode;
}
