import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class DynamicHeaderWidget extends ConsumerWidget {
  final UserModel user;

  const DynamicHeaderWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado'
    ];
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];

    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];
    final firstName = user.name.split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Hola, $firstName.",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Hoy es ${dayName.toLowerCase()}, ${now.day} de ${monthName.toLowerCase()}",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => NotificationService.showTestNotification(),
            icon: Icon(Icons.notification_add,
                color: Colors.white38, size: getAdaptiveSize(context, 20)),
            tooltip: "Test Protocolo Android",
          ),
        ],
      ),
    );
  }
}
