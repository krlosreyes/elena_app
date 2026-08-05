// SPEC-262: (de)serialización del wallet ↔ Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/gamification/domain/gamification_state.dart';

class GamificationMapper {
  const GamificationMapper();

  Map<String, dynamic> toMap(GamificationState s) => {
        'stars': s.stars,
        'totalStarsEarned': s.totalStarsEarned,
        'xp': s.xp,
        'frosties': s.frosties,
        'daysTowardFrosty': s.daysTowardFrosty,
        'lifetimeFastingHours': s.lifetimeFastingHours,
        'retosJoined': s.retosJoined,
        'retosFinished': s.retosFinished,
        'retosWon': s.retosWon,
        'retosRematches': s.retosRematches,
        'retosCountedCodes': s.retosCountedCodes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  GamificationState fromMap(Map<String, dynamic> m) => GamificationState(
        stars: _int(m['stars']),
        totalStarsEarned: _int(m['totalStarsEarned']),
        xp: _int(m['xp']),
        frosties: _int(m['frosties']),
        daysTowardFrosty: _int(m['daysTowardFrosty']),
        lifetimeFastingHours: _double(m['lifetimeFastingHours']),
        retosJoined: _int(m['retosJoined']),
        retosFinished: _int(m['retosFinished']),
        retosWon: _int(m['retosWon']),
        retosRematches: _int(m['retosRematches']),
        retosCountedCodes:
            (m['retosCountedCodes'] as List?)?.whereType<String>().toList() ??
                const [],
      );

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _double(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
