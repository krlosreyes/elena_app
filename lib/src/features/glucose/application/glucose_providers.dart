// Módulo "Tu Glucosa" — capa de aplicación (propuesta §8). Riverpod
// puro: cada provider expone SOLO lo que su consumidor pinta
// (`.select()` donde aplica), mismo criterio que STATE-01 ya dejó en
// `DashboardPillarsRow`.
//
// Clean Architecture: acá vive el CRUCE entre features (fasting, sleep,
// nutrition) — el dominio de glucosa (`glucose_insight.dart`) sigue
// siendo puro y no importa esos otros dominios directamente. En vez de
// reconstruir el historial de otras features para armar cada insight,
// cada `GlucoseReading` guarda un SNAPSHOT de fasting/sleep/comida en
// el momento exacto en que se registra (`buildGlucoseReadingSnapshot`
// más abajo) — más preciso que una reconstrucción posterior, y evita
// que este módulo necesite leer el historial completo de otras 3
// features cada vez que se abre "Tu Glucosa".

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/dashboard/application/ui_interaction_notifier.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/glucose/data/glucose_repository_impl.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_consent.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_insight.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_protocol_eligibility.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_protocol_state.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_variability.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_window_state.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_providers.dart'
    show effectiveSleepGoalProvider;
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart'
    show nutritionProvider;
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart'
    show currentCycleSleepProvider;
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// R1: elegibilidad automática por `pathologies` — recalcula cada vez
/// que cambia el UserModel (ya reactivo vía `currentUserStreamProvider`).
final glucoseProtocolEligibilityProvider =
    Provider<GlucoseProtocolEligibility>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) {
    return const GlucoseProtocolEligibility(eligible: false);
  }
  return GlucoseProtocolEligibility.assess(user);
});

/// true cuando corresponde mostrarle al usuario el sheet de
/// consentimiento AHORA (propuesta §7.1): es elegible automáticamente
/// Y todavía no aceptó el consentimiento vigente Y no lo descartó hoy
/// ("Ahora no" — `uiInteractionProvider.isGlucoseConsentDismissed`,
/// mismo patrón día-calendario que `isStreakAtRiskDismissed`).
/// `dashboard_screen.dart` hace `ref.listen` sobre este booleano para
/// disparar `showGlucoseConsentSheet` una sola vez por día.
final glucoseShouldPromptConsentProvider = Provider<bool>((ref) {
  final eligibility = ref.watch(glucoseProtocolEligibilityProvider);
  if (!eligibility.eligible) return false;

  final dismissedToday =
      ref.watch(uiInteractionProvider.select((s) => s.isGlucoseConsentDismissed));
  if (dismissedToday) return false;

  final protocolState = ref.watch(glucoseProtocolStateProvider).valueOrNull;
  if (protocolState == null) return false; // todavía cargando.
  if (protocolState.consentAccepted &&
      protocolState.consentVersion >= kGlucoseConsentVersion) {
    return false;
  }
  return true;
});

/// Estado persistido del protocolo — reactivo, mismo patrón que
/// `watchProtocolState`. `null` mientras carga o si nunca se creó el
/// doc (equivalente a `GlucoseProtocolState.initial()`).
final glucoseProtocolStateProvider =
    StreamProvider<GlucoseProtocolState>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(GlucoseProtocolState.initial());
  final repo = ref.watch(glucoseRepositoryProvider);
  return repo
      .watchProtocolState(uid)
      .map((s) => s ?? GlucoseProtocolState.initial());
});

/// Historial de lecturas (90 días por defecto — suficiente para
/// gráfico histórico + variabilidad + insights, propuesta §7.3/§9).
final glucoseReadingsProvider = StreamProvider<List<GlucoseReading>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  final repo = ref.watch(glucoseRepositoryProvider);
  return repo.watchReadings(uid, days: 90);
});

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// R3/R4: ventana de registro matutina, anclada al wakeUp REAL del
/// ciclo actual (`currentCycleSleepProvider` — mismo provider que ya
/// usa `DashboardPillarsRow` para el ring de Sueño). Devuelve
/// `GlucoseWindowState.notWokenYet` si el protocolo no está activo, sin
/// necesidad de un chequeo separado en cada consumidor.
final glucoseWindowStateProvider = Provider<GlucoseWindowState>((ref) {
  final protocolState = ref.watch(glucoseProtocolStateProvider).valueOrNull;
  if (protocolState == null || !protocolState.shouldPromptForReadings) {
    return GlucoseWindowState.notWokenYet;
  }

  final sleep = ref.watch(currentCycleSleepProvider);
  final now = DateTime.now();
  final wokeUpToday =
      (sleep != null && _isSameDay(sleep.wokeUp, now)) ? sleep.wokeUp : null;

  final todayLogs = ref.watch(nutritionProvider).todayLogs;
  final firstMealLoggedToday = MealIntervalRules.firstMealOf(todayLogs);

  final readings = ref.watch(glucoseReadingsProvider).valueOrNull ?? const [];
  final hasFastingReadingToday = readings.any((r) =>
      r.context == GlucoseReadingContext.ayunas && _isSameDay(r.measuredAt, now));

  return GlucoseWindowState.compute(
    wokeUpToday: wokeUpToday,
    firstMealLoggedToday: firstMealLoggedToday,
    hasFastingReadingToday: hasFastingReadingToday,
    now: now,
  );
});

/// Variabilidad glucémica (propuesta §12.2) sobre las lecturas en
/// ayunas de los últimos 14 días — mismo contexto para no mezclar
/// poblaciones de valores distintas (ayunas vs. postprandial).
final glucoseAyunasVariabilityProvider =
    Provider<GlucoseVariabilityResult>((ref) {
  final readings = ref.watch(glucoseReadingsProvider).valueOrNull ?? const [];
  final cutoff = DateTime.now().subtract(const Duration(days: 14));
  final values = readings
      .where((r) =>
          r.context == GlucoseReadingContext.ayunas &&
          r.measuredAt.isAfter(cutoff))
      .map((r) => r.valueMgDl)
      .toList();
  return GlucoseVariability.compute(values);
});

/// Motor de análisis (propuesta §10) — mapea `GlucoseReading` (con su
/// snapshot ya guardado) a `GlucoseReadingWithContext` sin necesidad de
/// re-consultar otras features, y delega el cálculo a
/// `GlucoseInsightEngine` (dominio puro).
final glucoseInsightsProvider = Provider<List<GlucoseInsight>>((ref) {
  final readings = ref.watch(glucoseReadingsProvider).valueOrNull ?? const [];

  final entries = readings.map((r) {
    return GlucoseReadingWithContext(
      valueMgDl: r.valueMgDl,
      isFastingContext: r.context == GlucoseReadingContext.ayunas,
      isPostprandialContext: r.context.isPostprandial,
      mealGlycemicIndex: r.mealGlycemicIndex,
      dayContext: GlucoseDailyContext(
        date: r.measuredAt,
        fastingHoursCompleted: r.relatedFastingHours,
        sleepHours: r.relatedSleepHours,
        sleepGoalHours: r.relatedSleepGoalHours,
      ),
    );
  }).toList();

  return GlucoseInsightEngine.analyze(entries);
});

/// Construye una `GlucoseReading` con el snapshot de fasting/sueño/
/// comida en el momento exacto de guardarla (ver doc de archivo). Se
/// llama desde el sheet de registro (`glucose_reading_sheet.dart`) —
/// vive acá para que ese widget no tenga lógica de negocio, solo UI.
GlucoseReading buildGlucoseReadingSnapshot(
  Ref ref, {
  required String userId,
  required int valueMgDl,
  required GlucoseReadingContext context,
  required List<GlucoseSymptom> symptoms,
  String note = '',
}) {
  final now = DateTime.now();

  final fastingState = ref.read(fastingProvider);
  double? relatedFastingHours;
  if (fastingState.isActive && fastingState.startTime != null) {
    relatedFastingHours =
        now.difference(fastingState.startTime!).inMinutes / 60.0;
  }

  final sleep = ref.read(currentCycleSleepProvider);
  final relatedSleepHours =
      sleep != null ? sleep.duration.inMinutes / 60.0 : null;
  final relatedSleepGoalHours = ref.read(effectiveSleepGoalProvider);

  int? minutesSinceWaking;
  if (context == GlucoseReadingContext.ayunas &&
      sleep != null &&
      _isSameDay(sleep.wokeUp, now)) {
    minutesSinceWaking = now.difference(sleep.wokeUp).inMinutes;
  }

  int? minutesSinceLastMeal;
  int? mealGlycemicIndex;
  if (context.isPostprandial) {
    final todayLogs = ref.read(nutritionProvider).todayLogs;
    if (todayLogs.isNotEmpty) {
      final lastMeal =
          todayLogs.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
      minutesSinceLastMeal = now.difference(lastMeal.timestamp).inMinutes;
      mealGlycemicIndex = lastMeal.glycemicIndex;
    }
  }

  return GlucoseReading(
    id: '',
    userId: userId,
    valueMgDl: valueMgDl,
    context: context,
    measuredAt: now,
    minutesSinceLastMeal: minutesSinceLastMeal,
    minutesSinceWaking: minutesSinceWaking,
    relatedFastingHours: relatedFastingHours,
    relatedSleepHours: relatedSleepHours,
    relatedSleepGoalHours: relatedSleepGoalHours,
    mealGlycemicIndex: mealGlycemicIndex,
    symptomsReported: symptoms,
    note: note,
    createdAt: now,
    updatedAt: now,
  );
}
