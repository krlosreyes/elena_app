// Widget compartido: resumen compacto del ritmo circadiano.
// Usado en Dashboard (entre el reloj y los pilares) y en Analysis (tab Hoy).

import 'package:flutter/material.dart';

class CircadianMiniCard extends StatelessWidget {
  const CircadianMiniCard({
    super.key,
    required this.circadianPhase,
    required this.lockLabel,
    required this.lockActive,
    required this.circadianAlignment,
  });

  final String circadianPhase;
  final String lockLabel;
  final bool   lockActive;
  final double circadianAlignment;

  @override
  Widget build(BuildContext context) {
    final alignPct  = (circadianAlignment * 100).toStringAsFixed(0);
    final lockColor = lockActive ? Colors.redAccent : const Color(0xFF10B981);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _stat(
              icon: Icons.wb_twilight_rounded,
              label: 'FASE ACTUAL',
              value: circadianPhase,
              color: const Color(0xFFEAB308),
            ),
          ),
          Expanded(
            child: _stat(
              icon: Icons.lock_clock_rounded,
              label: 'BLOQUEO INTESTINAL',
              value: lockLabel,
              color: lockColor,
            ),
          ),
          Expanded(
            child: _stat(
              icon: Icons.align_vertical_center_rounded,
              label: 'ALINEACIÓN',
              value: '$alignPct%',
              color: const Color(0xFF818CF8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required String   label,
    required String   value,
    required Color    color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.35),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
