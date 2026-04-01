import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../training/application/movement_controller.dart';

class MovementRegistrationPanel extends ConsumerWidget {
  const MovementRegistrationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementState = ref.watch(exerciseProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MOVIMIENTO FUNCIONAL",
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "MINS EN ZONA (ÚLT. 24H): ${movementState.minutesCurrent}/${movementState.minutesGoal}",
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
      ),
      child:
          const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () => _showRegistrationModal(context, ref),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        "REGISTRAR SESIÓN",
        style: GoogleFonts.jetBrainsMono(
          color: AppTheme.primary,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRegistrationModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "REGISTRAR MOVIMIENTO",
                  style: GoogleFonts.publicSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Selecciona el tipo de actividad realizada hoy.",
                  style: GoogleFonts.publicSans(
                      color: AppTheme.textDim, fontSize: 13),
                ),
                const SizedBox(height: 24),
                _buildModalOption(
                  context,
                  ref,
                  "Cardio Zona 2",
                  "Mantenimiento mitocondrial (30 min)",
                  Icons.favorite,
                  30,
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  ref,
                  "Fuerza",
                  "Optimización metabólica muscular (45 min)",
                  Icons.fitness_center,
                  45,
                ),
                const SizedBox(height: 12),
                _buildModalOption(
                  context,
                  ref,
                  "Paseo Post-Prandial",
                  "Gestión de glucosa (15 min)",
                  Icons.directions_walk,
                  15,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption(BuildContext context, WidgetRef ref, String title,
      String subtitle, IconData icon, int minutes) {
    return ListTile(
      onTap: () {
        ref.read(exerciseProvider.notifier).addMinutes(minutes);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sesión de $title registrada (+ $minutes min)"),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(
        title,
        style: GoogleFonts.publicSans(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.publicSans(color: AppTheme.textDim, fontSize: 11),
      ),
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.outline.withValues(alpha: 0.2)),
      ),
    );
  }
}
