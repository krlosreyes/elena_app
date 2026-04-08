import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/logic/elena_brain.dart';
import '../engagement/data/engagement_repository.dart';
import '../theme/app_theme.dart';

class ElenaHeader extends ConsumerWidget {
  final String title;
  final UserModel user;
  final bool showDate;
  final VoidCallback? onBack;

  const ElenaHeader({
    super.key,
    required this.title,
    required this.user,
    this.showDate = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculamos el IMR para el círculo
    final imr = ElenaBrain.calculateIMRForUser(user);

    // Inicial del usuario
    final String initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : (user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U');

    // Título de la Página con Fecha opcional
    Widget titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.robotoMono(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (showDate) ...[const SizedBox(height: 2), _buildDateString()],
      ],
    );

    // Racha real desde Firestore
    final streak = ref.watch(streakStreamProvider).valueOrNull ?? 0;
    final streakText = streak.toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (onBack != null) ...[
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              _buildUserAvatar(initial, imr),
              const SizedBox(width: 12),
              Expanded(child: titleWidget),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Lado Derecho: Badge de Racha (Imagen 3 Style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppTheme.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                streakText, // Racha real del usuario
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(String initial, double imr) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.4),
          width: 1,
        ),
        color: const Color(0xFF0F1115),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Text(
            initial,
            style: GoogleFonts.publicSans(
              color: AppTheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Positioned(
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                imr.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateString() {
    final now = DateTime.now();
    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
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
      'diciembre',
    ];

    // weekday es 1-7 (Lunes-Domingo)
    final dayName = days[now.weekday == 7 ? 0 : now.weekday];
    final monthName = months[now.month - 1];

    return Text(
      'Hoy es $dayName ${now.day} de $monthName de ${now.year}',
      style: GoogleFonts.publicSans(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
