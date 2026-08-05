// SPEC-262: round-trip del mapper del wallet.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/gamification/data/mappers/gamification_mapper.dart';
import 'package:elena_app/src/features/gamification/domain/gamification_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = GamificationMapper();

  test('toMap → fromMap preserva todos los campos', () {
    const s = GamificationState(
      stars: 120,
      totalStarsEarned: 500,
      xp: 5039,
      frosties: 6,
      daysTowardFrosty: 4,
      lifetimeFastingHours: 9361,
    );
    final back = mapper.fromMap(mapper.toMap(s));
    expect(back, s);
  });

  test('serializa con updatedAt de servidor', () {
    final map = mapper.toMap(const GamificationState());
    expect(map['updatedAt'], isA<FieldValue>());
    expect(map['stars'], 0);
  });

  test('fromMap tolera mapa vacío (wallet nuevo)', () {
    final back = mapper.fromMap(<String, dynamic>{});
    expect(back, const GamificationState());
  });

  test('fromMap tolera enteros venidos como num/double', () {
    final back = mapper.fromMap(<String, dynamic>{
      'stars': 10.0,
      'xp': 200,
      'lifetimeFastingHours': 12,
    });
    expect(back.stars, 10);
    expect(back.xp, 200);
    expect(back.lifetimeFastingHours, 12.0);
  });
}
