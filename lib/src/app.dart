import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:elena_app/src/router/app_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/providers/notification_provider.dart';

class ElenaApp extends ConsumerWidget {
  const ElenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    // SPEC-05: Mantener vivo el scheduler. Al leer el provider aquí,
    // Riverpod garantiza que vive durante toda la sesión de la app.
    ref.watch(notificationSchedulerProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844), // Medida base de iPhone
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'ElenaApp',
          theme: AppTheme.darkTheme, // Aplicamos tu tema profesional
          routerConfig: router,
        );
      },
    );
  }
}