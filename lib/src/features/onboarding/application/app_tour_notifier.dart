// SPEC-243 — Tour interactivo post-onboarding.
//
// Un overlay de coach marks que guía al usuario por los elementos clave de
// la app antes de registrar el primer dato. Se activa una sola vez al
// completar el onboarding y se persiste como flag para no repetirse.
//
// Arquitectura:
//   - AppTourNotifier: StateNotifier que gestiona el paso actual.
//   - appTourProvider: expuesto en app.dart y en el overlay.
//   - La marca "ya visto" vive en SharedPreferences ('appTourDone').
//
// 11 pasos organizados en 3 pantallas:
//   Pasos 0-7  → Dashboard (reloj + 5 pilares + score)
//   Paso  8    → Análisis (pantalla de Progreso)
//   Paso  9    → Perfil
//   Paso  10   → Dashboard (bienvenida final)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

// ── Descripción de un paso del tour ──────────────────────────────────────────

/// Posición del spotlight (hueco en el overlay oscuro).
enum TourSpotlightArea {
  /// Sin hueco — overlay 100% oscuro (bienvenida, cierre).
  none,

  /// Hueco en la zona del reloj circadiano (centro-alto de pantalla).
  clock,

  /// Hueco estrecho sobre la fila de los 5 anillos de pilar.
  pillarRow,

  /// Hueco que destaca el primer anillo (Ayuno) de la fila.
  fastingRing,

  /// Hueco que destaca el segundo anillo (Sueño).
  sleepRing,

  /// Hueco que destaca el tercer anillo (Hidratación).
  hydrationRing,

  /// Hueco que destaca el cuarto anillo (Ejercicio).
  exerciseRing,

  /// Hueco que destaca el quinto anillo (Comidas).
  comidasRing,

  /// Hueco en la zona inferior — card PROGRESO HOY.
  scoreCard,

  /// Pantalla completa iluminada (Análisis / Perfil mostrados sin oscurecer).
  fullScreen,
}

class TourStep {
  final String emoji;
  final String title;
  final String body;
  final TourSpotlightArea spotlight;

  /// Si no es nulo, el tour navega a esta ruta antes de mostrar el paso.
  final String? navigateTo;

  const TourStep({
    required this.emoji,
    required this.title,
    required this.body,
    required this.spotlight,
    this.navigateTo,
  });
}

// ── Datos del tour ────────────────────────────────────────────────────────────

const List<TourStep> kTourSteps = [
  // 0 — Bienvenida
  TourStep(
    emoji: '👋',
    title: '¡Tu guía de ElenaApp!',
    body:
        'En los próximos 2 minutos te mostramos cómo funciona cada elemento de la app antes de que empieces a registrar.',
    spotlight: TourSpotlightArea.none,
  ),

  // 1 — Reloj Circadiano
  TourStep(
    emoji: '🕐',
    title: 'El Reloj Circadiano',
    body:
        'Muestra tu ventana de alimentación, las fases metabólicas del día (cognitiva, física, digestiva) y el punto donde estás ahora. Tócalo para ver la leyenda completa.',
    spotlight: TourSpotlightArea.clock,
  ),

  // 2 — Pilar Ayuno
  //
  // 27-jul-2026, dos correcciones en la misma frase:
  //   * "activa la quema de grasa y la autofagia" — sin decir cuándo,
  //     junto a "tu ayuno del día", daba a entender que un 16:8 llega a
  //     la autofagia. Empieza a las 24 h (`FastingPhase.startsAt`).
  //   * "Toca el anillo para iniciar" — el anillo no inicia nada: abre
  //     la leyenda del reloj. Ver la nota en `fasting_hero_display.dart`.
  TourStep(
    emoji: '⏱️',
    title: 'Pilar 1 · Ayuno',
    body: 'Cada hora de ayuno mueve a tu cuerpo por fases: baja la insulina, '
        'empieza la cetosis y aumenta el uso de grasa. Inicia tu ayuno con '
        'el botón verde de la tarjeta de abajo.',
    spotlight: TourSpotlightArea.fastingRing,
  ),

  // 3 — Pilar Sueño
  TourStep(
    emoji: '🌙',
    title: 'Pilar 2 · Sueño',
    body:
        'La base de la recuperación hormonal y metabólica. Elena detecta cuando despiertas y registra tus horas de descanso.',
    spotlight: TourSpotlightArea.sleepRing,
  ),

  // 4 — Pilar Hidratación
  TourStep(
    emoji: '💧',
    title: 'Pilar 3 · Hidratación',
    body:
        'El agua activa el transporte de nutrientes y la función celular. Un toque = registrar un vaso. Elena te recuerda cada 45 minutos.',
    spotlight: TourSpotlightArea.hydrationRing,
  ),

  // 5 — Pilar Ejercicio
  TourStep(
    emoji: '💪',
    title: 'Pilar 4 · Ejercicio',
    body:
        'El movimiento acelera el metabolismo y mejora la sensibilidad a la insulina. Se sincroniza con HealthKit o puedes registrar manualmente.',
    spotlight: TourSpotlightArea.exerciseRing,
  ),

  // 6 — Pilar Comidas
  TourStep(
    emoji: '🥗',
    title: 'Pilar 5 · Comidas',
    body:
        'Tus horarios de alimentación deben respetarse dentro de tu ventana nutricional. Elena te sugiere el número de comidas según tu protocolo.',
    spotlight: TourSpotlightArea.comidasRing,
  ),

  // 7 — Score del Día
  TourStep(
    emoji: '📊',
    title: 'Progreso Hoy (HOY)',
    body:
        'Es el agregado de los 5 pilares en tiempo real (0-100). Sube cada vez que registras una acción. El IMR longitudinal refleja tu metabolismo semana a semana.',
    spotlight: TourSpotlightArea.scoreCard,
  ),

  // 8 — Pantalla Análisis
  TourStep(
    emoji: '📈',
    title: 'Tu Progreso',
    body:
        'Aquí ves la evolución de tu IMR, las tendencias de cada pilar y el histórico de ciclos metabólicos. Disponible en detalle con Premium.',
    spotlight: TourSpotlightArea.fullScreen,
    navigateTo: '/analysis',
  ),

  // 9 — Pantalla Perfil
  TourStep(
    emoji: '⚙️',
    title: 'Tu Perfil',
    body:
        'Medidas biométricas, objetivos por pilar, protocolo de ayuno y configuración del plan. Mantenlo actualizado para que el IMR sea preciso.',
    spotlight: TourSpotlightArea.fullScreen,
    navigateTo: '/profile',
  ),

  // 10 — Cierre
  TourStep(
    emoji: '🎯',
    title: '¡Todo listo!',
    body: 'Ya conoces tu app. Comienza registrando tu primer ayuno con el '
        'botón "Iniciar Ayuno" ⏱️ del Dashboard. '
        '¡Tu metabolismo te lo va a agradecer!',
    spotlight: TourSpotlightArea.none,
    navigateTo: '/dashboard',
  ),
];

// ── Estado del tour ───────────────────────────────────────────────────────────

class AppTourState {
  final bool isActive;
  final int stepIndex;

  const AppTourState({required this.isActive, required this.stepIndex});

  TourStep get currentStep => kTourSteps[stepIndex];
  bool get isFirstStep => stepIndex == 0;
  bool get isLastStep => stepIndex == kTourSteps.length - 1;
  int get totalSteps => kTourSteps.length;

  AppTourState copyWith({bool? isActive, int? stepIndex}) => AppTourState(
        isActive: isActive ?? this.isActive,
        stepIndex: stepIndex ?? this.stepIndex,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AppTourNotifier extends StateNotifier<AppTourState> {
  final Ref _ref;

  AppTourNotifier(this._ref)
      : super(const AppTourState(isActive: false, stepIndex: 0));

  /// PROD-05 (21-jul, auditoría técnica): clave de SharedPreferences
  /// namespaceada por uid. Antes 'appTourDone' era una clave GLOBAL del
  /// dispositivo (SharedPreferences no distingue cuentas). En la práctica
  /// esto significa que si dos cuentas distintas se usan en el mismo
  /// simulador/dispositivo (como ocurrió durante esta auditoría: cuenta
  /// vieja → cerrar sesión → cuenta nueva), la cuenta NUEVA heredaba
  /// `done=true` de la cuenta anterior y el tour jamás se activaba —
  /// aunque para esa cuenta específica nunca se había mostrado. Esta es
  /// la explicación más probable, más simple y más directamente respaldada
  /// por el código, de por qué el tour "no se activó" al terminar el
  /// onboarding de la cuenta nueva.
  ///
  /// Devuelve null si todavía no hay sesión (no hay uid para namespacing).
  String? get _prefsKey {
    final uid = _ref.read(authStateProvider).value?.uid;
    if (uid == null) return null;
    return 'appTourDone_$uid';
  }

  /// Verifica si el tour ya se completó (para ESTA cuenta) y lo activa si no.
  Future<bool> tryActivate() async {
    if (state.isActive)
      return false; // tour ya corriendo — no resetear al navegar
    final key = _prefsKey;
    if (key == null)
      return false; // sin sesión aún — no hay uid para namespacing
    final prefs = _ref.read(sharedPreferencesProvider);

    // REGRESIÓN DE P0-2 encontrada y corregida en la auditoría en vivo del
    // 22-jul: el shim de "compat hacia atrás" que vivía acá asumía que si
    // la clave global legacy ('appTourDone', sin namespacing por uid) era
    // `true`, entonces ESTA cuenta ya había visto el tour, y migraba sin
    // activarlo. Ese supuesto es falso en cualquier dispositivo/simulador
    // que haya corrido una cuenta ANTERIOR (la que puso el flag legacy en
    // `true`) — exactamente el escenario multi-cuenta que P0-2 vino a
    // arreglar. Resultado en producción: toda cuenta NUEVA creada en un
    // dispositivo con historial heredaba `done=true` sin haber visto nunca
    // el tour, silenciosamente. Confirmado en vivo: cuenta de prueba fresca
    // ("Claude", 22-jul) nunca vio el tour pese a que P0-2 estaba
    // implementado y el trigger en DashboardScreen.initState corría bien.
    //
    // Se elimina la migración. El costo de sacarla es bajo (un usuario que
    // de verdad completó el tour bajo el esquema global viejo podría verlo
    // una vez más); el costo de mantenerla era alto (ninguna cuenta nueva
    // en un dispositivo compartido lo ve jamás). La clave global legacy ya
    // no se lee en ningún lado de este archivo.
    final done = prefs.getBool(key) ?? false;
    if (done) return false;
    state = const AppTourState(isActive: true, stepIndex: 0);
    return true;
  }

  /// Avanza al siguiente paso. Si era el último, cierra el tour.
  Future<void> nextStep() async {
    if (state.isLastStep) {
      await _finish();
      return;
    }
    state = state.copyWith(stepIndex: state.stepIndex + 1);
  }

  /// Salta directamente a un paso (usado internamente para navegar screens).
  void jumpTo(int index) {
    state = state.copyWith(stepIndex: index);
  }

  /// Cierra el tour sin completarlo (botón "Saltar").
  Future<void> skip() async => _finish();

  /// Borra el flag de "tour visto" (de ESTA cuenta) para volver a
  /// mostrarlo. Útil en QA / testing y en el replay desde Perfil
  /// ("Guía de la app").
  Future<void> forceReset() async {
    final key = _prefsKey;
    if (key != null) {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.remove(key);
    }
    state = const AppTourState(isActive: false, stepIndex: 0);
  }

  Future<void> _finish() async {
    final key = _prefsKey;
    if (key != null) {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setBool(key, true);
    }
    state = const AppTourState(isActive: false, stepIndex: 0);
  }
}

final appTourProvider =
    StateNotifierProvider<AppTourNotifier, AppTourState>((ref) {
  return AppTourNotifier(ref);
});
