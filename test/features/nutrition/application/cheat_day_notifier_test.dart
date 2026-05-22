// Tests del CheatDayNotifier — SPEC-137 §RF-137-07.
//
// Cubre:
// - Activación exitosa cuando no hay lockout.
// - Bloqueo por lockout semanal ISO.
// - Idempotencia de doble activación en el mismo día.
// - Persistencia round-trip en SharedPreferences.
// - Cálculo de semana ISO 8601.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/features/nutrition/application/cheat_day_notifier.dart';

void main() {
  // Inicializar el binding para que SharedPreferences mock funcione.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('CheatDayNotifier — estado inicial sin data persistida', () {
    test('arranca sin cheat activo ni lockout', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = CheatDayNotifier(prefs);
      expect(notifier.state.isActiveToday, isFalse);
      expect(notifier.state.weeklyLockEnforced, isFalse);
      expect(notifier.state.lastCheatDate, isNull);
    });
  });

  group('CheatDayNotifier — activate', () {
    test('primer activate retorna activated y persiste', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = CheatDayNotifier(prefs);
      final result = await notifier.activate();

      expect(result, CheatDayActivationResult.activated);
      expect(notifier.state.isActiveToday, isTrue);
      expect(notifier.state.weeklyLockEnforced, isTrue);
      expect(notifier.state.lastCheatDate, isNotNull);

      // Persistencia verificable.
      expect(prefs.getString('cheat_day_active_date'), isNotNull);
      expect(prefs.getString('cheat_day_last_week_iso'), isNotNull);
    });

    test('segundo activate en el mismo día retorna alreadyActive', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = CheatDayNotifier(prefs);
      await notifier.activate();
      final result = await notifier.activate();
      expect(result, CheatDayActivationResult.alreadyActive);
    });
  });

  group('CheatDayNotifier — lockout semanal', () {
    test('activate en día distinto de la misma semana ISO bloquea', () async {
      // Lunes 2026-05-18 (semana 21).
      final monday = DateTime(2026, 5, 18, 10);
      // Miércoles 2026-05-20 (semana 21).
      final wednesday = DateTime(2026, 5, 20, 10);

      final prefs = await SharedPreferences.getInstance();
      final notifier = CheatDayNotifier.withClock(prefs, monday);

      final r1 = await notifier.activate(now: monday);
      expect(r1, CheatDayActivationResult.activated);

      // Hidratar de nuevo simulando el miércoles para que isActiveToday
      // pase a false y solo quede el lockout semanal.
      final fresh = CheatDayNotifier.withClock(prefs, wednesday);
      final r2 = await fresh.activate(now: wednesday);
      expect(
        r2,
        CheatDayActivationResult.blockedByWeeklyLock,
        reason: 'misma semana ISO no permite segundo cheat',
      );
    });

    test('activate en semana ISO distinta sí permite', () async {
      // Sábado 2026-05-23 (semana 21).
      final saturday = DateTime(2026, 5, 23, 10);
      // Lunes 2026-05-25 (semana 22).
      final nextMonday = DateTime(2026, 5, 25, 10);

      final prefs = await SharedPreferences.getInstance();
      final notifier = CheatDayNotifier.withClock(prefs, saturday);

      final r1 = await notifier.activate(now: saturday);
      expect(r1, CheatDayActivationResult.activated);

      // Simulamos el cambio de semana hidratando un notifier nuevo con
      // un reloj inyectado de la siguiente semana ISO.
      final fresh = CheatDayNotifier.withClock(prefs, nextMonday);
      expect(fresh.state.weeklyLockEnforced, isFalse,
          reason: 'la semana nueva no tiene cheat consumido aún');

      final r2 = await fresh.activate(now: nextMonday);
      expect(r2, CheatDayActivationResult.activated,
          reason: 'nueva semana ISO desbloquea cheat day');
    });
  });

  group('CheatDayNotifier — deactivateToday', () {
    test('libera el flag de hoy pero NO el lockout semanal', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = CheatDayNotifier(prefs);
      await notifier.activate();
      expect(notifier.state.isActiveToday, isTrue);

      await notifier.deactivateToday();
      expect(notifier.state.isActiveToday, isFalse,
          reason: 'el flag de hoy se libera');
      expect(notifier.state.weeklyLockEnforced, isTrue,
          reason: 'el lockout semanal permanece — una vez consumido el '
              'cheat, no se puede tener otro esa misma semana');
    });

    test('deactivate sin activar no hace nada', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = CheatDayNotifier(prefs);
      await notifier.deactivateToday();
      expect(notifier.state.isActiveToday, isFalse);
    });
  });

  group('CheatDayNotifier — rehidratación tras restart', () {
    test('un notifier nuevo lee el cheat activo del SP', () async {
      final prefs = await SharedPreferences.getInstance();

      final first = CheatDayNotifier(prefs);
      await first.activate();

      // Simular reapertura de la app: un notifier nuevo sobre el mismo SP.
      final second = CheatDayNotifier(prefs);
      expect(second.state.isActiveToday, isTrue);
      expect(second.state.weeklyLockEnforced, isTrue);
    });

    test('rehidratación en día distinto refleja "no activo hoy"', () async {
      // Pre-poblar SP con un activo de ayer.
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayIso =
          '${yesterday.year.toString().padLeft(4, '0')}-'
          '${yesterday.month.toString().padLeft(2, '0')}-'
          '${yesterday.day.toString().padLeft(2, '0')}';
      SharedPreferences.setMockInitialValues({
        'cheat_day_active_date': yesterdayIso,
        'cheat_day_last_week_iso': CheatDayNotifier.isoWeek(yesterday),
      });

      final prefs = await SharedPreferences.getInstance();
      final notifier = CheatDayNotifier(prefs);
      expect(notifier.state.isActiveToday, isFalse,
          reason: 'el cheat era de ayer, no se considera activo hoy');
    });
  });

  group('CheatDayNotifier.isoWeek — semana ISO 8601', () {
    test('semana ISO con formato YYYY-W##', () {
      final result = CheatDayNotifier.isoWeek(DateTime(2026, 5, 22));
      expect(result, matches(RegExp(r'^\d{4}-W\d{2}$')));
    });

    test('días de la misma semana ISO dan el mismo string', () {
      // Lunes-domingo 2026-05-18 a 2026-05-24 = semana 21 ISO.
      final monday = CheatDayNotifier.isoWeek(DateTime(2026, 5, 18));
      final wednesday = CheatDayNotifier.isoWeek(DateTime(2026, 5, 20));
      final sunday = CheatDayNotifier.isoWeek(DateTime(2026, 5, 24));
      expect(monday, wednesday);
      expect(wednesday, sunday);
    });

    test('lunes de semana distinta da string distinto', () {
      final w21 = CheatDayNotifier.isoWeek(DateTime(2026, 5, 18));
      final w22 = CheatDayNotifier.isoWeek(DateTime(2026, 5, 25));
      expect(w21, isNot(w22));
    });
  });
}
