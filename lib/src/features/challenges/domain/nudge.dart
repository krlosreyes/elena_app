// SPEC-264: interacciones sociales dentro de un reto ("zumbidos" estilo MSN).
//
// GUARDARRAÍL DE BIENESTAR (no negociable): catálogo CERRADO y SOLO POSITIVO,
// sin texto libre. Nada de burla ni presión sobre peso/cuerpo. El mensaje llega
// "de {nombre}" (modelo Duolingo), que es más efectivo y humano. Cuestan perlas.

/// Tipos de interacción disponibles.
enum NudgeType { porra, zumbido, fuego }

/// Definición de una interacción: costo en perlas, ícono y copy de recepción.
class NudgeKind {
  final NudgeType type;

  /// Id estable para Firestore (no depende del orden del enum).
  final String id;
  final String label;
  final String emoji;

  /// Costo en perlas al enviarla.
  final int cost;

  const NudgeKind({
    required this.type,
    required this.id,
    required this.label,
    required this.emoji,
    required this.cost,
  });

  /// Copy que ve quien la recibe, con el nombre de quien la envía.
  String messageFrom(String fromName) => switch (type) {
        NudgeType.porra => '¡$fromName te está echando porras! 👏',
        NudgeType.zumbido =>
          '¡$fromName te dio un zumbido! No pierdas el ritmo hoy 💪',
        NudgeType.fuego => '¡$fromName reconoce tu constancia! 🔥',
      };
}

abstract final class NudgeCatalog {
  static const NudgeKind porra = NudgeKind(
    type: NudgeType.porra,
    id: 'porra',
    label: 'Porra',
    emoji: '👏',
    cost: 2,
  );

  static const NudgeKind zumbido = NudgeKind(
    type: NudgeType.zumbido,
    id: 'zumbido',
    label: 'Zumbido',
    emoji: '⚡',
    cost: 5,
  );

  static const NudgeKind fuego = NudgeKind(
    type: NudgeType.fuego,
    id: 'fuego',
    label: 'Fuego',
    emoji: '🔥',
    cost: 3,
  );

  static const List<NudgeKind> all = [porra, zumbido, fuego];

  static NudgeKind? byId(String id) {
    for (final k in all) {
      if (k.id == id) return k;
    }
    return null;
  }
}

/// Una interacción enviada (persistida en challenges/{code}/nudges/{id}).
class Nudge {
  final String id;
  final String fromUid;
  final String fromName;
  final String toUid;

  /// Id del [NudgeKind] (ver [NudgeCatalog]).
  final String typeId;
  final DateTime createdAt;

  const Nudge({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.typeId,
    required this.createdAt,
  });

  NudgeKind? get kind => NudgeCatalog.byId(typeId);
}
