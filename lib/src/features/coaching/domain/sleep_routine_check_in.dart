// SPEC-234: modelo del check-in de rutina nocturna.
//
// Registra qué pasos de higiene de sueño completó el usuario antes de dormir.
// NO afecta el score — es una herramienta de acompañamiento, no una obligación.
// Alimenta al motor de coaching para personalizar tips futuros.

class SleepRoutineCheckIn {
  final String id; // 'routine_{yyyy-MM-dd}'
  final String userId;
  final DateTime date;
  final bool screensOff;
  final bool lastMealOk;
  final bool tempCool;
  final bool noCaffeine;
  final DateTime? completedAt;

  const SleepRoutineCheckIn({
    required this.id,
    required this.userId,
    required this.date,
    this.screensOff = false,
    this.lastMealOk = false,
    this.tempCool = false,
    this.noCaffeine = false,
    this.completedAt,
  });

  int get completedCount =>
      (screensOff ? 1 : 0) +
      (lastMealOk ? 1 : 0) +
      (tempCool ? 1 : 0) +
      (noCaffeine ? 1 : 0);

  bool get isWellPrepared => completedCount >= 3;

  /// ID determinista por fecha.
  static String buildId(String userId, DateTime date) =>
      'routine_${date.year}-${_two(date.month)}-${_two(date.day)}';

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'date': date.toIso8601String(),
        'screensOff': screensOff,
        'lastMealOk': lastMealOk,
        'tempCool': tempCool,
        'noCaffeine': noCaffeine,
        'completedAt': completedAt?.toIso8601String(),
        'completedCount': completedCount,
      };

  factory SleepRoutineCheckIn.fromMap(String id, Map<String, dynamic> m) =>
      SleepRoutineCheckIn(
        id: id,
        userId: m['userId'] as String? ?? '',
        date: DateTime.parse(m['date'] as String),
        screensOff: m['screensOff'] as bool? ?? false,
        lastMealOk: m['lastMealOk'] as bool? ?? false,
        tempCool: m['tempCool'] as bool? ?? false,
        noCaffeine: m['noCaffeine'] as bool? ?? false,
        completedAt: m['completedAt'] != null
            ? DateTime.parse(m['completedAt'] as String)
            : null,
      );

  SleepRoutineCheckIn copyWith({
    bool? screensOff,
    bool? lastMealOk,
    bool? tempCool,
    bool? noCaffeine,
    DateTime? completedAt,
  }) =>
      SleepRoutineCheckIn(
        id: id,
        userId: userId,
        date: date,
        screensOff: screensOff ?? this.screensOff,
        lastMealOk: lastMealOk ?? this.lastMealOk,
        tempCool: tempCool ?? this.tempCool,
        noCaffeine: noCaffeine ?? this.noCaffeine,
        completedAt: completedAt ?? this.completedAt,
      );

  static String _two(int n) => n.toString().padLeft(2, '0');
}
