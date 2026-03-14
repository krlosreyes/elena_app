import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FastingStage {
  final int hour;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const FastingStage({
    required this.hour,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class FastingTimeline extends StatelessWidget {
  final double progress;
  final Duration elapsed;
  final int plannedHours;

  const FastingTimeline({
    super.key,
    required this.progress,
    required this.elapsed,
    required this.plannedHours,
  });

  static const List<FastingStage> stages = [
    FastingStage(
      hour: 0,
      title: 'Digestión',
      description: 'Tu cuerpo absorbe nutrientes. La insulina está alta, el proceso metabólico acaba de comenzar.',
      icon: Icons.lunch_dining,
      color: Color(0xFF78909C),
    ),
    FastingStage(
      hour: 4,
      title: 'Equilibrio',
      description: 'La glucosa se normaliza y la insulina empieza a bajar. Tu metabolismo entra en reposo activo.',
      icon: Icons.balance,
      color: Color(0xFF26C6DA),
    ),
    FastingStage(
      hour: 12,
      title: 'Quema de Grasa',
      description: '🔥 La lipólisis se activa. Tu cuerpo empieza a usar las reservas de grasa como combustible.',
      icon: Icons.local_fire_department,
      color: Color(0xFFFF7043),
    ),
    FastingStage(
      hour: 14,
      title: 'Cetosis',
      description: '⚡ Se producen cuerpos cetónicos. Tu cerebro opera con energía limpia y hay mayor claridad mental.',
      icon: Icons.psychology,
      color: Color(0xFFAB47BC),
    ),
    FastingStage(
      hour: 16,
      title: 'Autofagia',
      description: '✨ El reciclaje celular está en marcha. Tu cuerpo limpia células dañadas y se regenera a nivel profundo.',
      icon: Icons.auto_awesome,
      color: Color(0xFF00E5FF),
    ),
    FastingStage(
      hour: 20,
      title: 'Renovación Profunda',
      description: '🚀 Pico máximo de hormona de crecimiento. Regeneración de tejidos, sistema inmune fortalecido.',
      icon: Icons.rocket_launch,
      color: Color(0xFF69F0AE),
    ),
  ];

  Color get _progressColor {
    final h = elapsed.inHours;
    if (h >= 16) return const Color(0xFF69F0AE);
    if (h >= 12) return const Color(0xFF00FFB2);
    return const Color(0xFF00BFA5);
  }

  @override
  Widget build(BuildContext context) {
    final List<FastingStage> displayStages =
        stages.where((s) => s.hour <= plannedHours).toList();

    if (!displayStages.any((s) => s.hour == plannedHours)) {
      displayStages.add(FastingStage(
        hour: plannedHours,
        title: '¡Meta! (${plannedHours}h)',
        description: '¡Increíble! Has completado tu ayuno de ${plannedHours}h. Tu cuerpo agradece este logro.',
        icon: Icons.flag,
        color: const Color(0xFF69F0AE),
      ));
    }

    final elapsedH = elapsed.inHours + (elapsed.inMinutes.remainder(60) / 60.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: _progressColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'VIAJE METABÓLICO',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60).toString().padLeft(2, '0')}m',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _progressColor,
                ),
              ),
            ],
          ),
        ),

        // The timeline itself
        SizedBox(
          height: 86,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              const double dotRadius = 14.0;
              const double sideMargin = dotRadius;
              final double availableWidth = maxWidth - (sideMargin * 2);
              final double pxPerHour = availableWidth / plannedHours;

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // 1. Track background — with subtle glow
                  Positioned(
                    left: sideMargin,
                    right: sideMargin,
                    top: 20,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // 2. Progress fill — gradient glow bar
                  Positioned(
                    left: sideMargin,
                    top: 20,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      width: (elapsedH * pxPerHour).clamp(0.0, availableWidth),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF004D40),
                            _progressColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _progressColor.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Stage nodes
                  ...displayStages.map((stage) {
                    final double relativePos = stage.hour * pxPerHour;
                    final double left = relativePos + sideMargin;
                    if (relativePos > availableWidth + 1) return const SizedBox.shrink();

                    final bool isReached = elapsedH >= stage.hour;
                    final bool isCurrent = isReached &&
                        displayStages.indexOf(stage) < displayStages.length - 1 &&
                        elapsedH < displayStages[displayStages.indexOf(stage) + 1].hour;

                    return Positioned(
                      left: left - dotRadius,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => _showStageInfo(context, stage, isReached),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Node circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: isCurrent ? dotRadius * 2.4 : dotRadius * 2,
                              height: isCurrent ? dotRadius * 2.4 : dotRadius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isReached
                                    ? stage.color.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                border: Border.all(
                                  color: isReached ? stage.color : Colors.white24,
                                  width: isCurrent ? 2.5 : 1.5,
                                ),
                                boxShadow: isReached
                                    ? [
                                        BoxShadow(
                                          color: stage.color.withOpacity(isCurrent ? 0.5 : 0.25),
                                          blurRadius: isCurrent ? 12 : 6,
                                          spreadRadius: isCurrent ? 2 : 0,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                stage.icon,
                                size: isCurrent ? 13 : 11,
                                color: isReached ? stage.color : Colors.white30,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Label
                            Text(
                              '${stage.hour}h',
                              style: GoogleFonts.robotoMono(
                                fontSize: 9,
                                fontWeight: isReached ? FontWeight.bold : FontWeight.w400,
                                color: isReached ? stage.color : Colors.white30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),

        // Stage name label strip below
        const SizedBox(height: 8),
        _buildCurrentStageBadge(elapsedH),
      ],
    );
  }

  Widget _buildCurrentStageBadge(double elapsedH) {
    FastingStage? current;
    for (final s in stages.reversed) {
      if (elapsedH >= s.hour) {
        current = s;
        break;
      }
    }
    if (current == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: current.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: current.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(current.icon, color: current.color, size: 13),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Etapa actual: ${current.title}',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: current.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStageInfo(BuildContext context, FastingStage stage, bool isReached) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: stage.color.withOpacity(0.4)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: stage.color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: stage.color.withOpacity(0.4)),
              ),
              child: Icon(stage.icon, color: stage.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Hora ${stage.hour}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      color: stage.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReached)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: stage.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: stage.color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '¡Etapa alcanzada!',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: stage.color,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              stage.description,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: stage.color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              'Entendido',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
