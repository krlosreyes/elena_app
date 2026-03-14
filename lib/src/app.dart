import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routing/routing.dart';
import 'config/theme/app_theme.dart';
import 'features/authentication/application/auth_controller.dart';

class ElenaApp extends ConsumerWidget {
  const ElenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);
    final authState = ref.watch(authStateChangesProvider);
    
    // STRICT MODE: Use UID as Key to force complete rebuild on user switch.
    // This prevents "Zombie State" in providers and UI widgets.
    final String appKey = authState.value?.uid ?? 'guest_session';

    return MaterialApp.router(
      key: ValueKey(appKey), 
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'elena_app',
      onGenerateTitle: (BuildContext context) => 'Elena App',
      theme: AppTheme.darkTelemetryTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
    );
  }
}
