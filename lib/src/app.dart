import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:elena_app/src/router/app_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/providers/notification_provider.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/notification_router.dart';
import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/application/feature_gate.dart';
import 'package:elena_app/src/features/onboarding/presentation/app_tour_overlay.dart';
import 'package:elena_app/src/features/coaching/application/coaching_action_router.dart';
import 'package:elena_app/src/core/services/daily_reset_service.dart';
import 'package:elena_app/src/features/analysis/application/daily_summary_persistence_service.dart';
import 'package:elena_app/src/features/health_sync/application/health_auto_sync_controller.dart';
import 'package:elena_app/src/features/health_sync/application/health_observer_provider.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_evaluator_provider.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart'
    show cycleScoreMigrationProvider;
import 'package:elena_app/src/core/engine/weekly_imr_staleness_trigger.dart';
import 'package:elena_app/src/core/services/watch_connectivity_service.dart';
import 'package:elena_app/src/core/services/watch_state_sync.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// SPEC-173 (2026-06-04): ElenaApp pasa de ConsumerWidget a
// ConsumerStatefulWidget para poder enganchar `WidgetsBindingObserver`
// y disparar `runIfDue` del Health auto-sync cuando la app vuelve de
// background (`AppLifecycleState.resumed`). Antes, abrir HealthKit y
// volver a la app no re-sincronizaba hasta cumplir el debounce + nuevo
// evento del stream de usuario.
class ElenaApp extends ConsumerStatefulWidget {
  const ElenaApp({super.key});

  @override
  ConsumerState<ElenaApp> createState() => _ElenaAppState();
}

class _ElenaAppState extends ConsumerState<ElenaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // SPEC-222: cold start — chequear si la app se abrió al tocar una
    // notificación. Si hay payload, guardarlo para flush cuando el
    // widget tree tenga BuildContext + GoRouter montado.
    _checkColdStartNotification();
    // SPEC-236 (SPEC-237 fix): inicializar el bridge Watch una sola vez
    // en startup. Si no hay Watch pareado o el canal no está registrado,
    // la llamada es no-op (MissingPluginException / PlatformException).
    WatchConnectivityService.initialize();
  }

  /// SPEC-222: consulta `getNotificationAppLaunchDetails` para detectar
  /// si la app se lanzó desde una notificación. En ese caso, guarda el
  /// payload para que `flushPending` lo navegue tras el primer frame.
  Future<void> _checkColdStartNotification() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      final details = await plugin.getNotificationAppLaunchDetails();
      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse?.payload != null &&
          details.notificationResponse!.payload!.isNotEmpty) {
        NotificationRouter.handlePayload(
          details.notificationResponse!.payload!,
        );
        AppLogger.debug(
          '[ElenaApp] Cold start con payload: '
          '${details.notificationResponse!.payload}',
        );
      }
    } catch (e) {
      AppLogger.debug('[ElenaApp] Error cold start notification check: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // SPEC-173: cuando el usuario trae la app de background (típico al
    // volver de Apple Health/HealthKit), re-disparar el auto-sync.
    // SPEC-173.bugfix2 (2026-06-04): pasamos de `runIfDue` (debounce 15m)
    // a `runNow` para garantizar que cada resume traiga datos frescos.
    // Carlos reportó ejercicio en 0 — probable que el debounce evitara
    // el sync. `runNow` ignora el debounce; el flag `state.isRunning`
    // sigue previniendo runs concurrentes.
    if (state == AppLifecycleState.resumed) {
      // SPEC-222: flush pending notification deeplink al volver a foreground.
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null && NotificationRouter.hasPending) {
        NotificationRouter.flushPending(navContext);
      }

      // SPEC-199 Fase A: aplicar acciones pendientes encoladas desde prompts
      // accionables (p. ej. "Sí, lo registro" del agua). Idempotente; las
      // acciones que requieren usuario se conservan si aún no hay sesión.
      CoachingActionRouter.flush(ref);

      final user = ref.read(currentUserStreamProvider).valueOrNull;
      if (user == null || user.id.isEmpty) return;
      // SPEC-197: el auto-sync de wearables es Premium. Free registra manual.
      if (!ref.read(featureGateProvider).autoSyncAllowed) return;
      AppLogger.debug('App: resume — forzando HealthAutoSync.runNow');
      ref
          .read(healthAutoSyncControllerProvider.notifier)
          .runNow(userId: user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    // SPEC-05: Mantener vivo el scheduler. Al leer el provider aquí,
    // Riverpod garantiza que vive durante toda la sesión de la app.
    ref.watch(notificationSchedulerProvider);

    // SPEC-58: Mantener vivo el DailyResetNotifier. Su constructor hace el
    // bootstrap (chequea SharedPreferences por reset pendiente desde la
    // última sesión) y arma un Timer hasta la próxima medianoche.
    ref.watch(dailyResetProvider);

    // SPEC-111: mantener vivo el servicio de persistencia diaria. Su
    // listener interno escucha `dailySummaryProvider` y persiste con
    // debounce + detección de cambio de día.
    ref.watch(dailySummaryPersistenceServiceProvider);

    // SPEC-174 (2026-06-04): evaluador del ciclo metabólico a nivel
    // root. Antes vivía en `dashboard_screen.dart` — si el usuario
    // salía a Análisis/Perfil, el provider se desmontaba y el ciclo
    // dejaba de evaluarse. Acá vive durante toda la sesión.
    ref.watch(metabolicCycleEvaluatorProvider);

    // SPEC-226: migración one-shot de dailyScores históricos afectados
    // por el bug de SPEC-225 (fastingMagnitude=0 al cerrar por nuevo
    // ayuno). Guard SharedPrefs garantiza que solo corre una vez por device.
    ref.watch(cycleScoreMigrationProvider);

    // SPEC-141 §RF-141-12.C (2026-06-05): gatillo de staleness para
    // re-snapshot del IMR longitudinal. Al primer login (o cambio de
    // usuario), si pasaron >7 días desde el último snapshot, recalcula
    // y persiste. One-shot por sesión por usuario.
    ref.watch(weeklyImrStalenessTriggerProvider);

    // SPEC-236 (SPEC-237 fix): registrar listeners de sincronización Watch.
    // ref.listen en build() es el patrón correcto de Riverpod para side-effects
    // — Riverpod deduplica automáticamente entre rebuilds.
    WatchStateSync.registerListeners(ref);

    // SPEC-132.next (2026-06-10): observers de HealthKit con background
    // delivery. Arranca el side-effect que escucha los eventos nativos de
    // Apple Health y dispara el sync cuando hay data fresca (peso, pasos,
    // sueño) — sin esperar a que el usuario reabra la app.
    ref.watch(healthObserverSideEffectProvider);

    // SPEC-132 Bloque C: bootstrap del auto-sync con HealthKit /
    // Health Connect. Escucha el stream del usuario y dispara
    // `runIfDue()` cuando hay un usuario completo. El controller
    // tiene debouncing interno (15 min) — el listener puede
    // dispararse N veces sin generar N syncs.
    ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider,
        (prev, next) {
      final user = next.value;
      if (user == null || user.id.isEmpty) return;
      // SPEC-199 Fase A: en cold start, las acciones encoladas (agua) se
      // aplican apenas hay usuario disponible.
      CoachingActionRouter.flush(ref);
      // SPEC-197: el auto-sync de wearables es Premium. Free registra manual.
      if (!ref.read(featureGateProvider).autoSyncAllowed) return;
      ref
          .read(healthAutoSyncControllerProvider.notifier)
          .runIfDue(userId: user.id);
    });

    // FIX race condition RC entitlement (2026-07-02):
    // `currentUserStreamProvider` puede dispararse ANTES de que RevenueCat
    // cargue el entitlement (isPremiumProvider arranca en false mientras
    // el StreamProvider resuelve). Si eso ocurre, el runIfDue de arriba se
    // aborta (`autoSyncAllowed = false`) y el sync nunca corre esa sesión
    // porque `currentUserStreamProvider` no vuelve a emitir.
    //
    // Este listener reactiva el sync en cuanto el gate pasa a true (RC cargó
    // + usuario Premium o en Trial). Cubre también el caso de upgrade en vivo
    // (Free → Premium mientras la app está abierta).
    ref.listen<FeatureGate>(featureGateProvider, (previous, next) {
      final wasAllowed = previous?.autoSyncAllowed ?? false;
      final isNowAllowed = next.autoSyncAllowed;
      if (wasAllowed || !isNowAllowed) return; // sin transición false→true
      final user = ref.read(currentUserStreamProvider).valueOrNull;
      if (user == null || user.id.isEmpty) return;
      AppLogger.debug(
        'App: featureGate autoSync unlocked — forzando HealthAutoSync.runNow',
      );
      // runNow (no runIfDue): el entitlement acaba de cargar, el debounce de
      // 15 min no aplica — necesitamos datos frescos ahora.
      ref
          .read(healthAutoSyncControllerProvider.notifier)
          .runNow(userId: user.id);
    });

    // SPEC-193: asociar el uid pseudónimo a Analytics (null en logout).
    // Sin PII — solo el identificador de Firebase.
    // SPEC-196: además, ligar las compras al usuario (App User ID = Firebase
    // UID) para que el entitlement siga al usuario entre devices; logout lo
    // desasocia (vuelve a Free).
    ref.listen<AsyncValue<AppAccount?>>(authStateProvider, (prev, next) {
      final uid = next.value?.uid;
      AnalyticsService.setUserId(uid);
      final billing = ref.read(billingServiceProvider);
      if (uid != null && uid.isNotEmpty) {
        billing.login(uid);
      } else {
        billing.logout();
      }

      // SPEC-222 fix cold-start timing: el addPostFrameCallback de build()
      // se ejecuta antes de que authState resuelva, por lo que el router
      // intercepta la navegación y redirige a /splash. En cuanto el usuario
      // está autenticado y el perfil está completo (isComplete), ejecutamos
      // el flush aquí — el router ya dejará pasar la navegación al destino real.
      final account = next.value;
      if (account != null && account.isComplete && NotificationRouter.hasPending) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navContext = rootNavigatorKey.currentContext;
          if (navContext != null) {
            NotificationRouter.flushPending(navContext);
          }
        });
      }
    });

    return ScreenUtilInit(
      designSize: const Size(390, 844), // Medida base de iPhone
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // SPEC-222: flush pending notification payload tras el primer frame.
        // Usamos addPostFrameCallback para que GoRouter ya esté montado.
        if (NotificationRouter.hasPending) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final navContext = rootNavigatorKey.currentContext;
            if (navContext != null) {
              NotificationRouter.flushPending(navContext);
            }
          });
        }

        // SPEC-89: forzamos dark theme en ambos slots + themeMode.dark
        // para evitar flash de light durante transiciones del sistema.
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'ElenaApp',
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          routerConfig: router,
          // SPEC-243: el tour interactivo post-onboarding se monta sobre
          // todo el árbol. AppTourOverlay retorna SizedBox.shrink() cuando
          // appTourProvider.isActive es false → costo cero en operación normal.
          builder: (ctx, child) => Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const AppTourOverlay(),
            ],
          ),
        );
      },
    );
  }
}
