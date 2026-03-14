import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../authentication/application/auth_controller.dart';
import '../../profile/application/user_controller.dart';
import '../../profile/data/user_repository.dart';
import '../../imx/application/imx_provider.dart';
import '../../imx/domain/imx_engine.dart';
import '../../progress/application/progress_controller.dart';
import '../../progress/domain/measurement_log.dart';
import '../../profile/domain/user_model.dart';
import '../../../shared/presentation/widgets/responsive_centered_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.notifier).currentUser;
    final userModelAsync = user != null
        ? ref.watch(userStreamProvider(user.uid))
        : const AsyncValue<UserModel?>.loading();
    final imxResultAsync = ref.watch(currentImxResultProvider);
    final historyAsync = ref.watch(userMeasurementsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: userModelAsync.when(
        data: (userModel) {
          if (userModel == null) {
            return const Center(child: Text('Perfil no encontrado', style: TextStyle(color: Colors.white)));
          }

          final imxResult = imxResultAsync.value;
          final history = historyAsync.value ?? [];
          final latestLog = history.isNotEmpty ? history.last : null;
          final firstLog = history.isNotEmpty ? history.first : null;

          return ResponsiveCenteredView(
            maxWidth: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── HERO SECTION ─────────────────────────────────────────
                  _HeroSection(
                    userModel: userModel,
                    imxResult: imxResult ?? ImxResult.empty,
                    authUser: user,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (imxResult != null) ...[
                          const SizedBox(height: 12),
                          _ImxPillarBreakdown(result: imxResult),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // ── COMPOSITION GOAL / PATH ───────────────────────
                        _CompositionPathCard(
                          userModel: userModel, 
                          log: latestLog,
                          baseline: firstLog,
                        ),
                        
                        const SizedBox(height: 16),

                        // ── BIOMETRIC STATS ROW ──────────────────────────
                        if (latestLog != null)
                          _BiometricStatsRow(userModel: userModel, log: latestLog),

                        const SizedBox(height: 24),

                        // ── ACTIVE PLAN ──────────────────────────────────
                        _ActivePlanBadge(uid: user?.uid),
                        const SizedBox(height: 32),

                        // ── LOGOUT ────────────────────────────────────────
                        TextButton(
                          onPressed: () async =>
                              await ref.read(authControllerProvider.notifier).signOut(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.07),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Cerrar sesión',
                              style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent)),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text('Elena App · Metamorfosis Real',
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white24)),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO: Big IMX score + avatar + name
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final UserModel userModel;
  final ImxResult imxResult;
  final dynamic authUser;

  const _HeroSection({required this.userModel, required this.imxResult, required this.authUser});

  // No longer needed: categories are calculated in the Cloud Function
  /*
  String get _imxLabel { ... }
  Color get _imxColor { ... }
  */

  Color _getColor(String categoryType) {
    return switch (categoryType) {
      'deteriorated' => Colors.redAccent,
      'unstable' => Colors.orange,
      'functional' => Colors.cyanAccent,
      'efficient' => const Color(0xFF00FFB2),
      'optimized' => const Color(0xFF00FFB2),
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(imxResult.categoryType);
    final totalScore = imxResult.total;
    
    final effectiveName = userModel.name.isNotEmpty 
        ? userModel.name 
        : (authUser?.displayName ?? userModel.displayName ?? 'Usuario');
    final firstName = effectiveName.trim().split(' ').first;

    return Stack(
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.15),
                const Color(0xFF0A0A0A).withOpacity(0),
              ],
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _ImxArcPainter(progress: totalScore / 100, color: color),
                  ),
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: color.withOpacity(0.1),
                  child: Text(
                    firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : 'U',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              firstName,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalScore.toStringAsFixed(1),
                  style: GoogleFonts.robotoMono(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5, left: 4),
                  child: Text(
                    '/ 100',
                    style: GoogleFonts.robotoMono(
                        fontSize: 12, color: Colors.white38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              imxResult.category.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImxArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ImxArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 2);
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(_ImxArcPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// PILLAR BREAKDOWN CHIPS
// ─────────────────────────────────────────────────────────────────────────────
class _ImxPillarBreakdown extends StatelessWidget {
  final ImxResult result;
  const _ImxPillarBreakdown({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PillarIcon(label: 'ESTRUCTURA', score: result.scoreStructure, icon: Icons.straighten, color: Colors.cyanAccent),
        const SizedBox(width: 6),
        _PillarIcon(label: 'METABÓLICA', score: result.scoreMetabolic, icon: Icons.bolt, color: Colors.orangeAccent),
        const SizedBox(width: 6),
        _PillarIcon(label: 'CONDUCTA', score: result.scoreBehavior, icon: Icons.spa_outlined, color: Colors.purpleAccent),
      ],
    );
  }
}

class _PillarIcon extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;
  final Color color;

  const _PillarIcon({required this.label, required this.score, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 10),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$label: ${score.toStringAsFixed(0)}',
                  style: GoogleFonts.robotoMono(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSITION PATH CARD: Where you are vs Where you're going
// ─────────────────────────────────────────────────────────────────────────────
class _CompositionPathCard extends StatelessWidget {
  final UserModel userModel;
  final MeasurementLog? log;
  final MeasurementLog? baseline;

  const _CompositionPathCard({required this.userModel, this.log, this.baseline});

  @override
  Widget build(BuildContext context) {
    final currentWeight = log?.weight ?? userModel.currentWeightKg;
    final isMale = userModel.gender == Gender.male;

    // ── Fat targets ────────────────────────────────────────────────────────
    final targetFatPct = isMale ? 15.0 : 22.0;
    final currentFat = log?.bodyFatPercentage ?? 0.0;

    // ── LBM-Preserving Target Weight ───────────────────────────────────────
    // Step A: Lean Body Mass = weight × (1 - fat%)
    // Step B: TargetWeight   = LBM  / (1 - targetFat%)
    // Fallback: if no body fat data, use healthy BMI midpoint (22.5 ♂ / 21.0 ♀)
    late final double targetWeight;
    late final String weightSubLabel;
    if (userModel.targetWeightKg != null) {
      targetWeight = userModel.targetWeightKg!;
      weightSubLabel = 'Meta personal';
    } else if (currentFat > 0) {
      final lbm = currentWeight * (1.0 - currentFat / 100.0);
      targetWeight = lbm / (1.0 - targetFatPct / 100.0);
      final fatToLose = currentWeight - targetWeight;
      weightSubLabel = '−${fatToLose.toStringAsFixed(1)} kg grasa pura';
    } else {
      final hM = userModel.heightCm / 100;
      targetWeight = isMale ? (hM * hM * 22.5) : (hM * hM * 21.0);
      weightSubLabel = 'Estimado por IMC (sin datos de grasa)';
    }

    // ── Waist target: WHtR = 0.48 (más realista para preservar músculo) ────
    final targetWaist = userModel.heightCm * 0.48;
    final currentWaist = log?.waistCircumference ?? userModel.waistCircumferenceCm;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Tu Meta de Composición',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 14, // Reducido un poco para mayor margen
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(width: 8),
              _DestinyBadge(),
            ],
          ),
          const SizedBox(height: 20),
          
          _MetricCompareRow(
            label: 'Peso Corporal',
            current: '${currentWeight.toStringAsFixed(1)} kg',
            target: '${targetWeight.toStringAsFixed(1)} kg',
            subLabel: weightSubLabel,
            percent: (currentWeight > 0 && targetWeight > 0) 
                ? (math.min<num>(currentWeight, targetWeight) / math.max<num>(currentWeight, targetWeight)).toDouble()
                : 0.0,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          _MetricCompareRow(
            label: 'Circunstancia Cintura',
            current: currentWaist > 0 ? '${currentWaist.toStringAsFixed(1)} cm' : 'Pendiente',
            target: '${targetWaist.toStringAsFixed(1)} cm',
            percent: (currentWaist > 0) ? (targetWaist / currentWaist).clamp(0, 1) : 0,
            color: const Color(0xFF00FFB2),
          ),
          if (currentFat > 0) ...[
            const SizedBox(height: 16),
            _MetricCompareRow(
              label: 'Grasa Corporal',
              current: '${currentFat.toStringAsFixed(1)}%',
              target: '${targetFatPct.toStringAsFixed(0)}%',
              percent: (targetFatPct / currentFat).clamp(0, 1),
              color: Colors.orangeAccent,
            ),
          ],
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white38, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentWaist > targetWaist + 5 
                      ? 'Faltan ${(currentWaist - targetWaist).toStringAsFixed(0)}cm de cintura para tu zona de salud óptima.'
                      : '¡Estás en una zona de composición saludable!',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
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

class _MetricCompareRow extends StatelessWidget {
  final String label;
  final String current;
  final String target;
  final double percent;
  final Color color;
  final String? subLabel;

  const _MetricCompareRow({
    required this.label,
    required this.current,
    required this.target,
    required this.percent,
    required this.color,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label, 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
            ),
            const SizedBox(width: 8),
            Text(target, style: GoogleFonts.robotoMono(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent.clamp(0, 1),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Expanded(
               child: Text('Actual: $current', 
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                 style: GoogleFonts.outfit(fontSize: 10, color: Colors.white24)),
             ),
             const SizedBox(width: 8),
             Flexible(
               child: Text(
                 subLabel ?? 'Meta Saludable',
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                 style: GoogleFonts.outfit(fontSize: 10, color: color.withOpacity(0.5)),
               ),
             ),
          ],
        ),
      ],
    );
  }
}

class _DestinyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 10),
            const SizedBox(width: 6),
            Text(
              'TU DESTINO',
              style: GoogleFonts.robotoMono(
                fontSize: 9,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3 KEY BIOMETRIC STATS
// ─────────────────────────────────────────────────────────────────────────────
class _BiometricStatsRow extends StatelessWidget {
  final UserModel userModel;
  final MeasurementLog log;

  const _BiometricStatsRow({required this.userModel, required this.log});

  @override
  Widget build(BuildContext context) {
    final bodyFat = log.bodyFatPercentage ?? 0;
    final weight = log.weight;

    // Fat mass in kg
    final fatKg   = bodyFat > 0 ? weight * bodyFat / 100 : 0.0;
    // Lean body mass
    final lbmKg   = bodyFat > 0
        ? weight * (100 - bodyFat) / 100
        : (weight * (log.muscleMassPercentage ?? 0) / 100);
    final lbmPct  = bodyFat > 0 ? (100 - bodyFat) : (log.muscleMassPercentage ?? 0);

    final visceral = log.visceralFat ??
        MeasurementLog.estimateVisceralFat(
          waistCm: log.waistCircumference ?? 0,
          isMale: userModel.gender == Gender.male,
        ) ?? 0.0;

    Color visceralColor = const Color(0xFF00FFB2);
    String visceralRisk = 'Normal';
    if (visceral >= 10) { visceralColor = Colors.orange; visceralRisk = 'Elevada'; }
    if (visceral >= 15) { visceralColor = Colors.redAccent; visceralRisk = 'Alta'; }

    Color fatColor = const Color(0xFF00FFB2);
    if (bodyFat > 0) {
      final limit = userModel.gender == Gender.male ? 20.0 : 28.0;
      if (bodyFat > limit + 5) fatColor = Colors.redAccent;
      else if (bodyFat > limit) fatColor = Colors.orange;
    }

    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Grasa\nCorporal',
          value: bodyFat > 0 ? '${bodyFat.toStringAsFixed(1)}%' : '--',
          subValue: fatKg > 0 ? '${fatKg.toStringAsFixed(1)} kg grasa' : null,
          color: fatColor,
          icon: Icons.water_drop_outlined,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          label: 'Masa\nMagra',
          value: lbmKg > 0 ? '${lbmKg.toStringAsFixed(1)} kg' : '--',
          subValue: lbmPct > 0 ? '${lbmPct.toStringAsFixed(1)}% del peso' : null,
          color: Colors.blueAccent,
          icon: Icons.fitness_center,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          label: 'Grasa\nVisceral',
          value: visceral > 0 ? visceral.toStringAsFixed(1) : '--',
          subValue: visceral > 0 ? visceralRisk : null,
          color: visceralColor,
          icon: Icons.monitor_heart_outlined,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          if (subValue != null) ...
            [
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  subValue!,
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: color.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          const SizedBox(height: 4),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontSize: 10, color: Colors.white38, height: 1.1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE PLAN BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _ActivePlanBadge extends ConsumerWidget {
  final String? uid;
  const _ActivePlanBadge({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<Map<String, dynamic>?>(
      stream: ref.watch(userRepositoryProvider).userActivePlanStream(uid!),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        final protocol = data['protocol'] as String? ?? '16/8';
        final message = data['coachMessage'] as String? ?? '';
        final statusStr = data['status'] as String? ?? '';

        Color accent = const Color(0xFF00FFB2);
        if (statusStr == 'regression') accent = Colors.orange;
        if (statusStr == 'stagnation') accent = Colors.blueAccent;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.auto_graph_outlined, color: accent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'PLAN DE TRANSFORMACIÓN',
                      style: GoogleFonts.robotoMono(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Protocolo de Ayuno: $protocol',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16)),
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
