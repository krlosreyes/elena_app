import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart'; // Importante
import 'firebase_options.dart'; // Importa tus opciones generadas
import 'src/features/onboarding/presentation/onboarding_screen.dart';
import 'src/features/dashboard/presentation/dashboard_screen.dart';
import 'src/core/theme/app_theme.dart'; // Asegúrate de importar tu tema

void main() async {
  // 1. Asegura que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase con tus opciones de elena-app-2026-v1
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Arranca la app con el ProviderScope de Riverpod
  runApp(
    const ProviderScope(
      child: ElenaApp(),
    ),
  );
}

class ElenaApp extends StatelessWidget {
  const ElenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ElenaApp - Metamorfosis Real',
      // Usamos el tema premium que definimos
      theme: AppTheme.lightTheme, 
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}