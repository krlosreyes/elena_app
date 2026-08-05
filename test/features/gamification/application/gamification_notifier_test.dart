// SPEC-262: tests del notifier (offline, sin usuario → sin Firestore).
//
// Overrideamos `currentUserStreamProvider` a null: el notifier NUNCA se
// suscribe a Firestore, así que probamos la lógica de estado sin Firebase.

import 'package:elena_app/src/features/gamification/application/gamification_notifier.dart';
import 'package:elena_app/src/features/gamification/domain/shop_item.dart';
import 'package:elena_app/src/features/gamification/domain/star_action.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container() => ProviderContainer(overrides: [
      currentUserStreamProvider
          .overrideWith((ref) => Stream<UserModel?>.value(null)),
    ]);

void main() {
  test('reward acumula estrellas y XP (offline)', () {
    final c = _container();
    addTearDown(c.dispose);
    final n = c.read(gamificationProvider.notifier);
    n.reward(StarAction.water);
    n.reward(StarAction.meal);
    final s = c.read(gamificationProvider);
    expect(s.stars, 5);
    expect(s.xp, 13);
  });

  test('comprar en la tienda solo cuando alcanza', () {
    final c = _container();
    addTearDown(c.dispose);
    final n = c.read(gamificationProvider.notifier);
    for (var i = 0; i < 25; i++) {
      n.reward(StarAction.water); // 25 × 2 = 50 estrellas
    }
    expect(c.read(gamificationProvider).stars, 50);

    expect(n.buyFrosty(Shop.byId('frosty-1')!), isTrue);
    expect(c.read(gamificationProvider).frosties, 1);
    expect(c.read(gamificationProvider).stars, 0);

    expect(n.buyFrosty(Shop.byId('frosty-1')!), isFalse); // ya no alcanza
  });

  test('onDayQualified regala un congelador cada 6 días', () {
    final c = _container();
    addTearDown(c.dispose);
    final n = c.read(gamificationProvider.notifier);
    for (var i = 0; i < 6; i++) {
      n.onDayQualified();
    }
    expect(c.read(gamificationProvider).frosties, 1);
    expect(c.read(gamificationProvider).daysTowardFrosty, 0);
  });

  test('recordFastingHours acumula horas de por vida', () {
    final c = _container();
    addTearDown(c.dispose);
    final n = c.read(gamificationProvider.notifier);
    n.recordFastingHours(16);
    n.recordFastingHours(18);
    expect(c.read(gamificationProvider).lifetimeFastingHours, 34);
  });
}
