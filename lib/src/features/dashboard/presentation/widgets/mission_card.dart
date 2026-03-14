import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum MissionState { pending, active, success }

class MissionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final MissionState state;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? score;
  final Widget? content;
  final Widget? bottomAction;

  const MissionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.score,
    this.content,
    this.state = MissionState.pending,
    this.onTap,
    this.trailing,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = state == MissionState.success;
    final isActive = state == MissionState.active;
    
    final backgroundColor = isSuccess 
        ? const Color(0xFF00FFB2).withOpacity(0.1) 
        : const Color(0xFF111111);
    
    final borderColor = isSuccess 
        ? const Color(0xFF00FFB2).withOpacity(0.5) 
        : accentColor.withOpacity(0.2);

    final glowColor = isSuccess 
        ? const Color(0xFF00FFB2).withOpacity(0.2) 
        : accentColor.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 15,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Stack(
              children: [
                if (score != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Text(
                      'Puntaje: $score/100',
                      style: GoogleFonts.firaCode(
                        color: accentColor.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Icon Container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            boxShadow: isActive ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ] : null,
                          ),
                          child: Icon(
                            isSuccess ? Icons.check_circle_outline : icon,
                            color: isSuccess ? const Color(0xFF00FFB2) : accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: GoogleFonts.outfit(
                                  color: isSuccess ? const Color(0xFF00FFB2).withOpacity(0.8) : Colors.grey.shade400,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    if (content != null) ...[
                      const SizedBox(height: 16),
                      content!,
                    ],
                    if (bottomAction != null) ...[
                      const SizedBox(height: 16),
                      bottomAction!,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
