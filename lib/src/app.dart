import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routing/routing.dart';
import 'config/theme/app_theme.dart';
import 'features/authentication/data/auth_repository.dart';

class ElenaApp extends ConsumerWidget {
  const ElenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    final authState = ref.watch(authStateChangesProvider);
    final String appKey = authState.value?.uid ?? 'logged-out';

    return MaterialApp.router(
      key: ValueKey(appKey), // Force rebuild on user switch
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'elena_app',
      onGenerateTitle: (BuildContext context) => 'Elena App',
      theme: AppTheme.lightTheme,
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
