import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:elena_app/src/router/app_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/providers/notification_provider.dart';
import 'package:elena_app/src/core/services/daily_reset_service.dart';
import 'package:elena_app/src/features/analysis/application/daily_summary_persistence_service.dart';
import 'package:elena_app/src/features/health_sync/application/health_auto_sync_controller.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class ElenaApp extends ConsumerWidget {
  const ElenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
