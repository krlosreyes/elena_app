// SPEC-73: tests del modelo AppAccount (getters y copyWith).

import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/auth/domain/app_account.dart';

void main() {
  group('AppAccount.isComplete / needsOnboarding', () {
    test('newProfile → needsOnboarding=true, isComplete=false', () {
      const account = AppAccount(
        uid: 'u1',
        email: 'a@b.com',
        profileStatus: AppProfileStatus.newProfile,
      );
      expect(account.needsOnboarding, isTrue);
      expect(account.isComplete, isFalse);
    });

    test('partialProfile → needsOnboarding=true, isComplete=false', () {
      const account = AppAccount(
        uid: 'u1',
        email: 'a@b.com',
        profileStatus: AppProfileStatus.partialProfile,
        rawProfile: {'name': 'X', 'subscription_active': true},
      );
      expect(account.needsOnboarding, isTrue);
      expect(account.isComplete, isFalse);
    });

    test('completeProfile → needsOnboarding=false, isComplete=true', () {
      const account = AppAccount(
        uid: 'u1',
        email: 'a@b.com',
        profileStatus: AppProfileStatus.completeProfile,
      );
      expect(account.needsOnboarding, isFalse);
      expect(account.isComplete, isTrue);
    });
  });

  group('AppAccount.copyWith', () {
    test('preserva campos no sobreescritos', () {
      const original = AppAccount(
        uid: 'u1',
        email: 'a@b.com',
        displayName: 'Carlos',
        profileStatus: AppProfileStatus.partialProfile,
        rawProfile: {'subscription_active': true},
      );
      final copy =
          original.copyWith(profileStatus: AppProfileStatus.completeProfile);

      expect(copy.uid, 'u1');
      expect(copy.email, 'a@b.com');
      expect(copy.displayName, 'Carlos');
      expect(copy.profileStatus, AppProfileStatus.completeProfile);
      expect(copy.rawProfile, {'subscription_active': true});
    });

    test('igualdad por valor (Equatable)', () {
      const a = AppAccount(
        uid: 'u1',
        email: 'a@b.com',
        profileStatus: AppProfileStatus.completeProfile,
      );
      const b = AppAccount(
        uid: 'u1',
        email: 'a@b.com',
        profileStatus: AppProfileStatus.completeProfile,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
