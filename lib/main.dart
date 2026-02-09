import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await initializeDateFormatting('es');

  // Inicializar Notificaciones Locales
  try {
    await NotificationService.init();
    debugPrint('Notificaciones inicializadas correctamente');
  } catch (e) {
    debugPrint('Error inicializando notificaciones: $e');
  }

  runApp(
    const ProviderScope(
      child: ElenaApp(),
    ),
  );
}
