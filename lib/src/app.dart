import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routing/routing.dart';
import 'config/theme/app_theme.dart';

class ElenaApp extends ConsumerWidget {
  const ElenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'elena_app',
      onGenerateTitle: (BuildContext context) => 'Elena App',
      theme: AppTheme.lightTheme,
    );
  }
}
