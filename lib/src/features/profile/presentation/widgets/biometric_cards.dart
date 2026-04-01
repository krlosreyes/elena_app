import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/biometric_calculator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BIOMETRIC CARDS CONSOLIDATED — All measurement cards in one file
// ─────────────────────────────────────────────────────────────────────────────

const Color _riskRed = Color(0xFFFF4444);
const Color _riskYellow = Color(0xFFFFD700);

// ─────────────────────────────────────────────────────────────────────────────
// BODY COMPOSITION CARD
// ─────────────────────────────────────────────────────────────────────────────

class BodyCompositionCard extends StatelessWidget {
  final UserModel user;
  final BiometricResult biometricResult;

  const BodyCompositionCard({
    super.key,
    required this.user,
    required this.biometricResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Composición Corporal',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricColumn(
                label: 'Peso',
                value: '${user.currentWeightKg.toStringAsFixed(1)} kg',
              ),
              _MetricColumn(
                label: 'Masa Magra',
                value:
                    '${biometricResult.leanBodyMassKg.toStringAsFixed(1)} kg',
              ),
              _MetricColumn(
                label: 'Grasa Corporal',
                value:
                    '${biometricResult.bodyFatPercentage.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // BMI Classification
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'IMC: ${biometricResult.bmi.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  BiometricCalculator.getBMIClassification(biometricResult.bmi),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BIOMETRIC METRICS CARD (Perímetros)
// ─────────────────────────────────────────────────────────────────────────────

class BiometricMetricsCard extends StatelessWidget {
  final UserModel user;
  final BiometricResult biometricResult;

  const BiometricMetricsCard({
    super.key,
    required this.user,
    required this.biometricResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perímetros Corporales',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _TableHeader('Cuello'),
                  _TableHeader('Cintura'),
                  _TableHeader('Cadera'),
                ],
              ),
              TableRow(
                children: [
                  _TableCell(
                    '${user.neckCircumferenceCm?.toStringAsFixed(1) ?? "N/A"} cm',
                  ),
                  _TableCell(
                    '${user.waistCircumferenceCm?.toStringAsFixed(1) ?? "N/A"} cm',
                  ),
                  _TableCell(
                    '${user.hipCircumferenceCm?.toStringAsFixed(1) ?? "N/A"} cm',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Ratio Cintura/Altura: ${biometricResult.waistToHeightRatio.toStringAsFixed(3)}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RISK ASSESSMENT CARD
// ─────────────────────────────────────────────────────────────────────────────

class RiskAssessmentCard extends StatelessWidget {
  final BiometricResult biometricResult;

  const RiskAssessmentCard({
    super.key,
    required this.biometricResult,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = biometricResult.imrRiskLevel == IMRRiskLevel.red
        ? _riskRed
        : biometricResult.imrRiskLevel == IMRRiskLevel.yellow
            ? _riskYellow
            : AppTheme.primary;

    final riskTitle = biometricResult.imrRiskLevel == IMRRiskLevel.red
        ? 'Alto Riesgo'
        : biometricResult.imrRiskLevel == IMRRiskLevel.yellow
            ? 'Riesgo Moderado'
            : 'Riesgo Bajo';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: riskColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                riskTitle,
                style: TextStyle(
                  color: riskColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Evaluación de Riesgo Metabólico',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            biometricResult.riskDescription,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ratio Cintura/Altura',
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  biometricResult.waistToHeightRatio.toStringAsFixed(3),
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;

  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
