import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FastingStage {
  final int hour;
  final String title;
  final String description;
  final IconData icon;

  const FastingStage({
    required this.hour,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class FastingTimeline extends StatelessWidget {
  final double progress; // 0.0 to 1.0 (relative to 16h for visualization or max stage)
  final Duration elapsed;
  final int plannedHours;

  const FastingTimeline({
    super.key,
    required this.progress,
    required this.elapsed,
    required this.plannedHours,
  });

  static const List<FastingStage> stages = [
    FastingStage(hour: 0, title: 'Digestión', description: 'Cuerpo absorbiendo nutrientes, insulina alta.', icon: Icons.lunch_dining),
    FastingStage(hour: 4, title: 'Equilibrio', description: 'Azúcar normalizada, insulina bajando.', icon: Icons.balance),
    FastingStage(hour: 12, title: 'Quema Grasa', description: 'Lipólisis activada, acceso a reservas.', icon: Icons.local_fire_department),
    FastingStage(hour: 14, title: 'Cetosis', description: 'Producción de cuerpos cetónicos, energía mental.', icon: Icons.psychology),
    FastingStage(hour: 16, title: 'Autofagia', description: 'Reciclaje y limpieza celular.', icon: Icons.cleaning_services),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              // Usamos 16h como base para la línea visual, o plannedHours si es mayor.
              final int visualMaxHours = plannedHours > 16 ? plannedHours : 16;
              final double pxPerHour = maxWidth / visualMaxHours;

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // 1. Línea Base
                  Container(
                    height: 4,
                    width: maxWidth,
                    color: Colors.grey[300],
                  ),

                  // 2. Línea de Progreso
                  Container(
                    height: 4,
                    width: (elapsed.inMinutes / 60) * pxPerHour,
                    color: Theme.of(context).primaryColor,
                  ),

                  // 3. Hitos (Stages)
                  ...stages.map((stage) {
                    final double left = stage.hour * pxPerHour;
                    // Evitar que se salga del borde derecho
                    if (left > maxWidth) return const SizedBox.shrink();

                    final bool isReached = elapsed.inHours >= stage.hour;
                    
                    return Positioned(
                      left: left - 12, // Centrar punto (24px width)
                      child: GestureDetector(
                        onTap: () => _showStageInfo(context, stage),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isReached ? Theme.of(context).primaryColor : Colors.grey[400],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  if (isReached)
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Icon(
                                stage.icon,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stage.hour}h',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
                                color: isReached ? Theme.of(context).primaryColor : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showStageInfo(BuildContext context, FastingStage stage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(stage.icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(stage.title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hito: Hora ${stage.hour}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(stage.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
