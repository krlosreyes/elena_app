/// Modelo que representa un intervalo de ayuno o ventana de alimentación.
/// Almacenado en Firestore: users/{uid}/fasting_history/{id}
class FastingInterval {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isFasting;

  const FastingInterval({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.isFasting,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'isFasting': isFasting,
  };

  factory FastingInterval.fromJson(Map<String, dynamic> json) {
    return FastingInterval(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isFasting: json['isFasting'] as bool? ?? true,
    );
  }
}
