import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/application/user_controller.dart';
import 'package:intl/intl.dart';

final currentTimeProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

final circadianStatusProvider =
    Provider<({bool isPrepPhase, int minutesToBed, bool isCriticalWindow})>(
        (ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  final now = ref.watch(currentTimeProvider).value ?? DateTime.now();

  if (user == null || user.bedTime == null) {
    return (isPrepPhase: false, minutesToBed: 999, isCriticalWindow: false);
  }

  final bedTimeToday = _parseTimeToToday(user.bedTime!, now);
  final diff = bedTimeToday.difference(now).inMinutes;

  // Protocolo T-20: La preparación empieza 20 minutos antes
  final bool isPrep = diff > 0 && diff <= 20;
  // Ventana Crítica: Menos de 5 minutos para el apagado
  final bool isCritical = diff > 0 && diff <= 5;

  return (
    isPrepPhase: isPrep,
    minutesToBed: diff,
    isCriticalWindow: isCritical,
  );
});

DateTime _parseTimeToToday(String time, DateTime now) {
  try {
    String normalized = time.toUpperCase().trim();
    if (!normalized.contains(' ')) {
      if (normalized.endsWith('AM')) {
        normalized = normalized.replaceAll('AM', ' AM');
      }
      if (normalized.endsWith('PM')) {
        normalized = normalized.replaceAll('PM', ' PM');
      }
    }
    final parsed = DateFormat("h:mm a").parse(normalized);
    var dt = DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);

    // Si la hora de dormir parseada ya pasó hace mucho (ej: 1 AM vs 11 PM ahora),
    // asumimos que es para mañana, pero para la lógica de "preparación" nos interesa el mismo ciclo.
    if (dt.isBefore(now.subtract(const Duration(hours: 12)))) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  } catch (e) {
    return now.add(const Duration(hours: 24)); // Fallback seguro
  }
}
