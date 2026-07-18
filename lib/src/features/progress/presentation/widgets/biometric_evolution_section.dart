import 'package:flutter/material.dart';
import 'package:elena_app/src/core/theme/app_icons.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/trend_chart.dart';

/// SPEC-15: sección "Composición corporal" del Road Map de Avance
/// Personal (Progreso). Muestra el último check-in, las gráficas de
/// peso/%grasa (cuando hay suficientes puntos) y el historial de los
/// últimos 5 check-ins. Si no hay historial, muestra el estado vacío
/// con CTA para registrar el primero.
///
/// SPEC-119: extraído de `progress_screen.dart` (ARCH-03). Estas
/// clases ya vivían como widgets `Stateless` independientes dentro del
/// mismo archivo — no dependían de un State compartido — así que la
/// extracción es una mudanza mecánica sin cambios de comportamiento.
class BiometricEvolutionSection extends StatelessWidget {
  const BiometricEvolutionSection({
    super.key,
    required this.history,
    required this.hasEnoughWeight,
    required this.hasEnoughBf,
    required this.weightPoints,
    required this.bfPoints,
    required this.latestWeight,
    required this.latestBf,
    required this.onCheckIn,
  });

  final List<BiometricCheckIn> history;
  final bool hasEnoughWeight;
  final bool hasEnoughBf;
  final List<double> weightPoints;
  final List<double> bfPoints;
  final double? latestWeight;
  final double? latestBf;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _EmptyBiometric(onTap: onCheckIn);
    }

    return Column(
      children: [
        // Stats del último check-in
        _LastCheckInCard(latest: history.last),
        const SizedBox(height: 12),

        // Gráfica de peso
        if (hasEnoughWeight) ...[
          TrendChart(
            data: weightPoints,
            label: 'Peso — ${history.length} mediciones',
            color: const Color(0xFF3498DB),
          ),
          const SizedBox(height: 12),
        ],

        // Gráfica de %grasa
        if (hasEnoughBf) ...[
          TrendChart(
            data: bfPoints,
            label: '% Grasa — ${bfPoints.length} mediciones',
            color: const Color(0xFFF39C12),
          ),
          const SizedBox(height: 12),
        ],

        // Historial de check-ins (últimos 5)
        if (history.length > 1)
          _CheckInHistory(history: history.reversed.take(5).toList()),
      ],
    );
  }
}

class _LastCheckInCard extends StatelessWidget {
  const _LastCheckInCard({required this.latest});
  final BiometricCheckIn latest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricChip(
            icon: AppIcons.peso,
            label: 'Peso',
            value: '${latest.weight.toStringAsFixed(1)} kg',
            color: const Color(0xFF3498DB),
          ),
          if (latest.bodyFatPercentage != null)
            _MetricChip(
              icon: AppIcons.grasa,
              label: '%Grasa',
              value: '${latest.bodyFatPercentage!.toStringAsFixed(0)}%',
              color: const Color(0xFFF39C12),
            ),
          if (latest.waistCircumference != null)
            _MetricChip(
              icon: AppIcons.cinturaEstatura,
              label: 'Cintura',
              value: '${latest.waistCircumference!.toStringAsFixed(0)} cm',
              color: const Color(0xFF9B59B6),
            ),
          if (latest.imrScore != null)
            _MetricChip(
              icon: AppIcons.imr,
              label: 'IMR',
              value: '${latest.imrScore}',
              color: const Color(0xFF1ABC9C),
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

class _CheckInHistory extends StatelessWidget {
  const _CheckInHistory({required this.history});
  final List<BiometricCheckIn> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: history.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      c.date,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${c.weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                    if (c.bodyFatPercentage != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${c.bodyFatPercentage!.toStringAsFixed(0)}% grasa',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    if (c.imrScore != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'IMR ${c.imrScore}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1ABC9C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (i < history.length - 1)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyBiometric extends StatelessWidget {
  const _EmptyBiometric({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF3498DB).withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(AppIcons.cinturaEstatura,
                size: 22, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sin medidas registradas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Registra tu primer check-in para ver tu evolución corporal.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline_rounded,
              color: const Color(0xFF3498DB).withValues(alpha: 0.7),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
