import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:elena_app/src/router/app_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/providers/notification_provider.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/core/services/daily_reset_service.dart';
import 'package:elena_app/src/features/analysis/application/daily_summary_persistence_service.dart';
import 'package:elena_app/src/features/health_sync/application/health_auto_sync_controller.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_evaluator_provider.dart';
import 'package:elena_app/src/core/engine/weekly_imr_staleness_trigger.dart';
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
      final user = ref.read(currentUserStreamProvider).valueOrNull;
      if (user == null || user.id.isEmpty) return;
      // `print` directo (no AppLogger) para que aparezca en Console.app
      // del iPhone en release. AppLogger del paquete `logger` puede
      // estar siendo strippeado en release builds optimizados.
      // ignore: avoid_print
      print('[ElenaApp] resume — forzando HealthAutoSync.runNow');
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

    // SPEC-141 §RF-141-12.C (2026-06-05): gatillo de staleness para
    // re-snapshot del IMR longitudinal. Al primer login (o cambio de
    // usuario), si pasaron >7 días desde el último snapshot, recalcula
    // y persiste. One-shot por sesión por usuario.
    ref.watch(weeklyImrStalenessTriggerProvider);

    // SPEC-132 Bloque C: bootstrap del auto-sync con HealthKit /
    // Health Connect. Escucha el stream del usuario y dispara
    // `runIfDue()` cuando hay un usuario completo. El controller
    // tiene debouncing interno (15 min) — el listener puede
    // dispararse N veces sin generar N syncs.
    ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider,
        (prev, next) {
      final user = next.value;
      if (user == null || user.id.isEmpty) return;
      ref
          .read(healthAutoSyncControllerProvider.notifier)
          .runIfDue(userId: user.id);
    });

    // SPEC-193: asociar el uid pseudónimo a Analytics (null en logout).
    // Sin PII — solo el identificador de Firebase.
    ref.listen<AsyncValue<AppAccount?>>(authStateProvider, (prev, next) {
      AnalyticsService.setUserId(next.value?.uid);
    });

    return ScreenUtilInit(
      designSize: const Size(390, 844), // Medida base de iPhone
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // SPEC-89: forzamos dark theme en ambos slots + themeMode.dark
        // para evitar flash de light durante transiciones del sistema.
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'ElenaApp',
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          routerConfig: router,
        );
      },
    );
  }
}
