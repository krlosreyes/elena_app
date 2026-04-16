import 'package:flutter/material.dart';

/// PillarSummaryRow
/// Fila de resumen de un pilar individual dentro de la pantalla de Análisis.
/// Muestra: ícono, nombre, valor registrado del día, contribución al IMR y barra de progreso.
class PillarSummaryRow extends StatelessWidget {
  final IconData icon;
  final String pillarName;
  final String value;
  final String imrContribution;
  final double progress; // 0.0 – 1.0
  final Color color;
  final bool isHardcoded; // true = dato no real todavía (muestra badge)

  const PillarSummaryRow({
    super.key,
    required this.icon,
    required this.pillarName,
    required this.value,
    required this.imrContribution,
    required this.progress,
    required this.color,
    this.isHardcoded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: progress >= 0.8
              ? color.withOpacity(0.4)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícono con fondo coloreado
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),

          // Nombre + barra de progreso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pillarName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isHardcoded) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.3), width: 1),
                        ),
                        child: const Text(
                          'ESTIMADO',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Valor + contribución IMR
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: progress >= 0.8 ? color : Colors.white,
                ),
              ),
              Text(
                imrContribution,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
